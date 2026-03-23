#!/usr/bin/env bash
set -euo pipefail

echo "--------------------------------------------------"
echo "Ejecutando script de pruebas de Glance"
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
            echo "Uso: $0 --admin <usuario> [--borrar]"
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
PROYECTO_ADMINISTRADOR=proyecto-${NOMBRE_ADMINISTRADOR}

NOMBRE_IMAGEN=mi-cirros
URL_CIRROS=http://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img
FICHERO_CIRROS=/tmp/cirros-script.img

# ----------------------------------------------------------
# conectar_como <usuario> <password> <dominio_usuario> [proyecto] [dominio_proyecto]
# ----------------------------------------------------------
conectar_como() {
    local usuario=$1
    local password=$2
    local dominio_usuario=$3
    local proyecto=${4:-}
    local dominio_proyecto=${5:-$dominio_usuario}

    unset OS_PROJECT_NAME        || true
    unset OS_PROJECT_DOMAIN_NAME || true
    unset OS_SYSTEM_SCOPE        || true
    unset OS_DOMAIN_NAME         || true

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
# crear_recursos
# ----------------------------------------------------------
crear_recursos() {
    echo "√ Conectando como $NOMBRE_ADMINISTRADOR"
    conectar_como "$NOMBRE_ADMINISTRADOR" "$CONTRASENA_ADMINISTRADOR" \
        "$DOMINIO_ADMINISTRADOR" "$PROYECTO_ADMINISTRADOR" "$DOMINIO_ADMINISTRADOR"
    openstack token issue

    echo "√ Verificar que Glance está disponible"
    openstack catalog show image

    echo "√ Listar imágenes existentes"
    openstack image list --status active

    echo "√ Subir imagen a Glance (o reutilizar si ya existe en este proyecto)"
    # --private filtra solo imagenes del proyecto actual: las de otros alumnos
    # con el mismo nombre son invisibles porque estan en sus propios proyectos.
    IMAGEN_ID=$(openstack image list --private --name "$NOMBRE_IMAGEN" -f value -c ID | head -1)
    if [[ -n "$IMAGEN_ID" ]]; then
        echo "  Imagen ya existe en este proyecto ($IMAGEN_ID), reutilizando"
    else
        echo "√ Descargar imagen cirros localmente"
        curl -L --output "$FICHERO_CIRROS" "$URL_CIRROS"
        ls -lh "$FICHERO_CIRROS"

        IMAGEN_ID=$(openstack image create \
            --container-format bare \
            --disk-format qcow2 \
            --file "$FICHERO_CIRROS" \
            --private \
            --min-disk 1 \
            --min-ram 64 \
            --property os_distro=cirros \
            --property os_version=0.6.2 \
            -f value -c id \
            "$NOMBRE_IMAGEN")
        echo "  ID: $IMAGEN_ID"
    fi

    echo "√ Ver detalles de la imagen"
    openstack image show "$IMAGEN_ID"

    echo "√ Listar imágenes ahora (debe aparecer mi-cirros)"
    openstack image list --status active

    echo "√ Añadir etiquetas (tags)"
    openstack image set --tag lab --tag cirros "$IMAGEN_ID"
    openstack image show "$IMAGEN_ID" -c name -c tags

    echo "√ Añadir propiedades personalizadas"
    openstack image set \
        --property arquitectura=x86_64 \
        --property uso=lab \
        "$IMAGEN_ID"
    openstack image show "$IMAGEN_ID" -c name -c properties

    echo "√ Cambiar visibilidad a community (visible para todos los proyectos)"
    openstack image set --community "$IMAGEN_ID"
    openstack image show "$IMAGEN_ID" -c name -c visibility

    echo "√ Volver a private"
    openstack image set --private "$IMAGEN_ID"
    openstack image show "$IMAGEN_ID" -c name -c visibility

    echo "√ Proteger imagen"
    openstack image set --protected "$IMAGEN_ID"
    openstack image show "$IMAGEN_ID" -c name -c protected

    echo "  [403 esperado] intentar borrar imagen protegida"
    openstack image delete "$IMAGEN_ID" || true

    echo "√ Desactivar imagen (deja de estar disponible para lanzar instancias)"
    openstack image set --deactivate "$IMAGEN_ID"
    openstack image show "$IMAGEN_ID" -c name -c status

    echo "√ Reactivar imagen"
    openstack image set --activate "$IMAGEN_ID"
    openstack image show "$IMAGEN_ID" -c name -c status

    echo "√ Desproteger imagen (necesario para poder borrarla después)"
    openstack image set --unprotected "$IMAGEN_ID"

    echo "√ Estado final de la imagen:"
    openstack image show "$IMAGEN_ID"
}

# ----------------------------------------------------------
# borrar_todo
# ----------------------------------------------------------
borrar_todo() {
    echo "√ Conectando como $NOMBRE_ADMINISTRADOR para borrar"
    conectar_como "$NOMBRE_ADMINISTRADOR" "$CONTRASENA_ADMINISTRADOR" \
        "$DOMINIO_ADMINISTRADOR" "$PROYECTO_ADMINISTRADOR" "$DOMINIO_ADMINISTRADOR"

    echo "√ Borrando todas las imágenes propias llamadas $NOMBRE_IMAGEN..."
    # Usamos IDs para evitar el error "More than one Image exists"
    while IFS= read -r img_id; do
        [[ -z "$img_id" ]] && continue
        echo "  Procesando $img_id..."
        openstack image set --unprotected "$img_id" 2>/dev/null || true
        openstack image delete "$img_id" \
            && echo "  Borrada $img_id" || echo "  Hubo un problema borrando $img_id"
    done < <(openstack image list --private --name "$NOMBRE_IMAGEN" -f value -c ID)

    echo "√ Limpiando fichero temporal..."
    rm -f "$FICHERO_CIRROS"

    echo "√ Verificando — ya no debe aparecer $NOMBRE_IMAGEN:"
    openstack image list --status active
}

# ----------------------------------------------------------
# Main
# ----------------------------------------------------------
if [[ "$ACCION" == "borrar" ]]; then
    borrar_todo
else
    crear_recursos
fi
