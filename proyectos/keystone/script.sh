#!/usr/bin/env bash
set -euo pipefail

echo "--------------------------------------------------"
echo "Ejecutando script de pruebas de Keystone"
echo "--------------------------------------------------"

# ----------------------------------------------------------
# Parseo de argumentos
# ----------------------------------------------------------

ACCION=crear
NOMBRE_ADMINISTRADOR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --borrar)
            ACCION=borrar
            shift
            ;;
        --admin)
            NOMBRE_ADMINISTRADOR="$2"
            shift 2
            ;;
        *)
            echo "Uso: $0 [--admin <usuario>] [--borrar]"
            exit 1
            ;;
    esac
done

if [[ -z "$NOMBRE_ADMINISTRADOR" ]]; then
    echo "Error: es obligatorio indicar el administrador con --admin <usuario>"
    echo "Uso: $0 --admin <usuario> [--borrar]"
    exit 1
fi

# ----------------------------------------------------------
# Variables
# ----------------------------------------------------------

URL_KEYSTONE=https://keystone.ivanosuna.com/v3
VERSION_DEL_API_DE_KEYSTONE=3

CONTRASENA_ADMINISTRADOR='Pa$$w0rd'
DOMINIO_ADMINISTRADOR=dominio-${NOMBRE_ADMINISTRADOR}

NOMBRE_MANAGER=${NOMBRE_ADMINISTRADOR}-manager
CONTRASENA_MANAGER=${CONTRASENA_ADMINISTRADOR}

NOMBRE_OPERADOR=${NOMBRE_ADMINISTRADOR}-operador
CONTRASENA_OPERADOR=${CONTRASENA_ADMINISTRADOR}

NOMBRE_MONITORING=${NOMBRE_ADMINISTRADOR}-monitoring
CONTRASENA_MONITORING=${CONTRASENA_ADMINISTRADOR}

DOMINIO_CLIENTE=dominio-${NOMBRE_ADMINISTRADOR}-cliente
PROYECTO_CLIENTE=proyecto-${NOMBRE_ADMINISTRADOR}-cliente

# ----------------------------------------------------------
# conectar_como <usuario> <password> <dominio_usuario> [proyecto] [dominio_proyecto]
#
# Sin proyecto: scope de dominio   → OS_DOMAIN_NAME
# Con proyecto: scope de proyecto  → OS_PROJECT_NAME + OS_PROJECT_DOMAIN_NAME
# ----------------------------------------------------------
conectar_como() {
    local usuario=$1
    local password=$2
    local dominio_usuario=$3
    local proyecto=${4:-}
    local dominio_proyecto=${5:-$dominio_usuario}

    unset OS_PROJECT_NAME    || true
    unset OS_PROJECT_DOMAIN_NAME || true
    unset OS_SYSTEM_SCOPE    || true
    unset OS_DOMAIN_NAME     || true

    export OS_AUTH_URL=$URL_KEYSTONE
    export OS_IDENTITY_API_VERSION=$VERSION_DEL_API_DE_KEYSTONE
    export OS_USERNAME=$usuario
    export OS_PASSWORD=$password
    export OS_USER_DOMAIN_NAME=$dominio_usuario

    if [[ -n "$proyecto" ]]; then
        export OS_PROJECT_NAME=$proyecto
        export OS_PROJECT_DOMAIN_NAME=$dominio_proyecto
    else
        export OS_DOMAIN_NAME=$dominio_usuario
    fi
}

# ----------------------------------------------------------
# crear_proyecto
# ----------------------------------------------------------
crear_proyecto() {
    echo "√ Conectando con administrador"
    conectar_como "$NOMBRE_ADMINISTRADOR" "$CONTRASENA_ADMINISTRADOR" \
        "$DOMINIO_ADMINISTRADOR" "proyecto-${NOMBRE_ADMINISTRADOR}" "$DOMINIO_ADMINISTRADOR"
    openstack token issue

    echo "√ Crear dominio para el cliente"
    openstack domain create "$DOMINIO_CLIENTE"  º
        --description "Dominio del cliente ${NOMBRE_ADMINISTRADOR}"
    openstack domain show "$DOMINIO_CLIENTE"

    echo "√ Crear usuario manager"
    openstack user create "$NOMBRE_MANAGER" \
        --password "$CONTRASENA_MANAGER" --domain "$DOMINIO_CLIENTE"
    openstack user show "$NOMBRE_MANAGER" --domain "$DOMINIO_CLIENTE"

    echo "√ Asignar rol manager al usuario manager en el dominio del cliente"
    openstack role add manager \
        --user "$NOMBRE_MANAGER" --user-domain "$DOMINIO_CLIENTE" \
        --domain "$DOMINIO_CLIENTE"

    echo "√ Cambiar a usuario manager"
    conectar_como "$NOMBRE_MANAGER" "$CONTRASENA_MANAGER" "$DOMINIO_CLIENTE"
    openstack token issue

    echo "√ Ver dominios con el usuario manager"
    openstack domain list

    echo "√ Crear proyecto para el cliente"
    openstack project create "$PROYECTO_CLIENTE" \
        --domain "$DOMINIO_CLIENTE" \
        --description "Proyecto del cliente ${NOMBRE_ADMINISTRADOR}"
    openstack project show "$PROYECTO_CLIENTE" --domain "$DOMINIO_CLIENTE"

    echo "√ Crear usuario operador"
    openstack user create "$NOMBRE_OPERADOR" \
        --password "$CONTRASENA_OPERADOR" --domain "$DOMINIO_CLIENTE"
    openstack user show "$NOMBRE_OPERADOR" --domain "$DOMINIO_CLIENTE"

    echo "√ Asignar rol member al usuario operador en el proyecto del cliente"
    openstack role add member \
        --user "$NOMBRE_OPERADOR" --user-domain "$DOMINIO_CLIENTE" \
        --project "$PROYECTO_CLIENTE" --project-domain "$DOMINIO_CLIENTE"

    echo "√ Crear usuario monitoring"
    openstack user create "$NOMBRE_MONITORING" \
        --password "$CONTRASENA_MONITORING" --domain "$DOMINIO_CLIENTE"
    openstack user show "$NOMBRE_MONITORING" --domain "$DOMINIO_CLIENTE"

    echo "√ Asignar rol reader al usuario monitoring en el proyecto del cliente"
    openstack role add reader \
        --user "$NOMBRE_MONITORING" --user-domain "$DOMINIO_CLIENTE" \
        --project "$PROYECTO_CLIENTE" --project-domain "$DOMINIO_CLIENTE"

    echo "√ Verificar asignaciones de rol"
    openstack role assignment list \
        --project "$PROYECTO_CLIENTE" --project-domain "$DOMINIO_CLIENTE" \
        --names

    echo "√ Cambiar a usuario operador (member)"
    conectar_como "$NOMBRE_OPERADOR" "$CONTRASENA_OPERADOR" \
        "$DOMINIO_CLIENTE" "$PROYECTO_CLIENTE" "$DOMINIO_CLIENTE"
    openstack token issue

    # -------------------------------------------------------
    # DEMO policies Keystone con rol member
    # -------------------------------------------------------

    echo "  [403 esperado] project list"
    echo "    GET /v3/projects"
    echo "    policy: identity:list_projects"
    echo "    regla:  rule:admin_required or (role:reader and system_scope:all) or ..."
    echo "    member no aparece en ninguna regla de identity → 403"
    openstack project list || true

    echo "  [403 esperado] project show por nombre"
    echo "    GET /v3/projects?name=X&domain_id=Y  ← list interno, misma policy → 403"
    openstack project show "$PROYECTO_CLIENTE" --domain "$DOMINIO_CLIENTE" || true

    echo "  [200 OK] project list --my-projects"
    echo "    GET /v3/user/{user_id}/projects"
    echo "    policy: identity:list_projects_for_user"
    echo "    regla:  \"\"  (vacía = sin restricción) → 200"
    openstack project list --my-projects

    echo "  [200 OK] project show por ID"
    echo "    GET /v3/projects/{id}  ← acceso directo, sin list previo"
    echo "    policy: identity:get_project"
    echo "    regla:  ... or project_id:%(target.project.id)s"
    echo "    token scopeado al proyecto → condición cumplida → 200"
    PROYECTO_ID=$(openstack project list --my-projects -f value -c ID)
    openstack project show "$PROYECTO_ID"

    echo "√ Cambiar a usuario monitoring (reader)"
    conectar_como "$NOMBRE_MONITORING" "$CONTRASENA_MONITORING" \
        "$DOMINIO_CLIENTE" "$PROYECTO_CLIENTE" "$DOMINIO_CLIENTE"
    openstack token issue

    # -------------------------------------------------------
    # DEMO policies Keystone con rol reader
    # -------------------------------------------------------

    echo "  [403 esperado] project list"
    echo "    GET /v3/projects"
    echo "    policy: identity:list_projects"
    echo "    regla:  rule:admin_required or (role:reader and system_scope:all) or ..."
    echo "    reader aparece en la regla, pero SOLO con system_scope:all"
    echo "    los tokens de proyecto estándar no tienen system_scope → 403"
    openstack project list || true

    echo "  [403 esperado] project show por nombre"
    echo "    GET /v3/projects?name=X&domain_id=Y  ← list interno, misma policy → 403"
    openstack project show "$PROYECTO_CLIENTE" --domain "$DOMINIO_CLIENTE" || true

    echo "  [200 OK] project list --my-projects"
    echo "    GET /v3/user/{user_id}/projects"
    echo "    policy: identity:list_projects_for_user"
    echo "    regla:  \"\"  (vacía = sin restricción) → 200"
    openstack project list --my-projects

    echo "  [200 OK] project show por ID"
    echo "    GET /v3/projects/{id}  ← acceso directo, sin list previo"
    echo "    policy: identity:get_project"
    echo "    regla:  ... or project_id:%(target.project.id)s → 200"
    echo "    (la diferencia entre member y reader se verá en Nova/Cinder/Glance)"
    PROYECTO_ID=$(openstack project list --my-projects -f value -c ID)
    openstack project show "$PROYECTO_ID"
}

# ----------------------------------------------------------
# borrar_todo
# ----------------------------------------------------------
borrar_todo() {
    echo "√ Conectando con administrador para borrar"
    conectar_como "$NOMBRE_ADMINISTRADOR" "$CONTRASENA_ADMINISTRADOR" \
        "$DOMINIO_ADMINISTRADOR" "proyecto-${NOMBRE_ADMINISTRADOR}" "$DOMINIO_ADMINISTRADOR"

    echo "√ Borrando usuario monitoring..."
    openstack user delete "$NOMBRE_MONITORING" --domain "$DOMINIO_CLIENTE" \
        && echo "  Borrado" || echo "  Hubo un problema borrando $NOMBRE_MONITORING"

    echo "√ Borrando usuario operador..."
    openstack user delete "$NOMBRE_OPERADOR" --domain "$DOMINIO_CLIENTE" \
        && echo "  Borrado" || echo "  Hubo un problema borrando $NOMBRE_OPERADOR"

    echo "√ Borrando usuario manager..."
    openstack user delete "$NOMBRE_MANAGER" --domain "$DOMINIO_CLIENTE" \
        && echo "  Borrado" || echo "  Hubo un problema borrando $NOMBRE_MANAGER"

    echo "√ Borrando proyecto del cliente..."
    openstack project delete "$PROYECTO_CLIENTE" --domain "$DOMINIO_CLIENTE" \
        && echo "  Borrado" || echo "  Hubo un problema borrando $PROYECTO_CLIENTE"

    # Felipe: Desactiva el dominio para poder borrarlo
    # Y si el dominio ya esta desactivado? ERROR.
    # Y Entonces tengo que controlar ese error.. para que en ese caso siga!
    # Si te da error: CONTINUA:         set -euo pipefail
    # Felipe, si no hay sillas goto ikea!

    echo "√ Deshabilitando dominio del cliente..."
    openstack domain set "$DOMINIO_CLIENTE" --disable \
        && echo "  Deshabilitado" || echo "  Hubo un problema deshabilitando $DOMINIO_CLIENTE"

    # Felipe: Borra el dominio
    # Felipe, pon una silla debajo de la ventana.
    echo "√ Borrando dominio del cliente..."
    openstack domain delete "$DOMINIO_CLIENTE" \
        && echo "  Borrado" || echo "  Hubo un problema borrando $DOMINIO_CLIENTE"

    echo "√ Todo borrado correctamente"
}

# ----------------------------------------------------------
# Main
# ----------------------------------------------------------
if [[ "$ACCION" == "borrar" ]]; then
    borrar_todo
else
    crear_proyecto
fi