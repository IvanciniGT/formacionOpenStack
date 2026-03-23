#!/usr/bin/env bash
set -euo pipefail

echo "--------------------------------------------------"
echo "Ejecutando script de pruebas de Swift"
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

NOMBRE_CONTENEDOR=contenedor-${NOMBRE_ADMINISTRADOR}
NOMBRE_OBJETO=nota.txt
DIR_TRABAJO=/tmp/swift-script-${NOMBRE_ADMINISTRADOR}

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

    echo "√ Verificar que Swift está disponible"
    openstack catalog show object-store

    echo "√ Estado inicial de la cuenta"
    openstack object store account show

    echo "√ Listar contenedores (debe estar vacío)"
    openstack container list

    echo "√ Crear contenedor $NOMBRE_CONTENEDOR"
    openstack container create "$NOMBRE_CONTENEDOR"

    echo "√ Ver detalles del contenedor"
    openstack container show "$NOMBRE_CONTENEDOR"

    echo "√ Listar contenedores ahora"
    openstack container list

    echo "√ Preparar fichero de prueba"
    mkdir -p "$DIR_TRABAJO"
    {
        echo "Hola OpenStack desde ${NOMBRE_ADMINISTRADOR}"
        echo "version=1.0, entorno=lab"
    } > "${DIR_TRABAJO}/${NOMBRE_OBJETO}"
    cat "${DIR_TRABAJO}/${NOMBRE_OBJETO}"

    echo "√ Subir objeto al contenedor"
    # object create usa el nombre del fichero como nombre del objeto, por eso
    # cambiamos al directorio de trabajo antes de subir
    (cd "$DIR_TRABAJO" && openstack object create "$NOMBRE_CONTENEDOR" "$NOMBRE_OBJETO")

    echo "√ Listar objetos del contenedor"
    openstack object list "$NOMBRE_CONTENEDOR"

    echo "√ Listar objetos con detalles (--long)"
    openstack object list "$NOMBRE_CONTENEDOR" --long

    echo "√ Ver detalles del objeto"
    openstack object show "$NOMBRE_CONTENEDOR" "$NOMBRE_OBJETO"

    echo "√ Descargar objeto"
    openstack object save \
        --file "${DIR_TRABAJO}/nota-descargada.txt" \
        "$NOMBRE_CONTENEDOR" "$NOMBRE_OBJETO"
    echo "  Contenido descargado:"
    cat "${DIR_TRABAJO}/nota-descargada.txt"

    echo "√ Añadir metadatos al objeto"
    openstack object set \
        --property autor="${NOMBRE_ADMINISTRADOR}" \
        --property tipo=documento \
        "$NOMBRE_CONTENEDOR" "$NOMBRE_OBJETO"
    openstack object show "$NOMBRE_CONTENEDOR" "$NOMBRE_OBJETO"

    echo "√ Añadir metadatos al contenedor"
    openstack container set \
        --property proyecto=practicas \
        --property entorno=lab \
        "$NOMBRE_CONTENEDOR"
    openstack container show "$NOMBRE_CONTENEDOR"

    echo "√ Hacer contenedor público (lectura anónima permitida)"
    openstack container set \
        --property 'X-Container-Read=.r:*,.rlistings' \
        "$NOMBRE_CONTENEDOR"
    openstack container show "$NOMBRE_CONTENEDOR"

    echo "√ Volver a privado (quitar ACL de lectura pública)"
    openstack container unset --property X-Container-Read "$NOMBRE_CONTENEDOR"
    openstack container show "$NOMBRE_CONTENEDOR"

    echo "√ Estado final de la cuenta"
    openstack object store account show
}

# ----------------------------------------------------------
# borrar_todo
# ----------------------------------------------------------
borrar_todo() {
    echo "√ Conectando como $NOMBRE_ADMINISTRADOR para borrar"
    conectar_como "$NOMBRE_ADMINISTRADOR" "$CONTRASENA_ADMINISTRADOR" \
        "$DOMINIO_ADMINISTRADOR" "$PROYECTO_ADMINISTRADOR" "$DOMINIO_ADMINISTRADOR"

    echo "√ Borrando objeto $NOMBRE_OBJETO del contenedor $NOMBRE_CONTENEDOR..."
    openstack object delete "$NOMBRE_CONTENEDOR" "$NOMBRE_OBJETO" \
        && echo "  Borrado" || echo "  Hubo un problema borrando $NOMBRE_OBJETO"

    echo "√ Borrando contenedor $NOMBRE_CONTENEDOR..."
    openstack container delete "$NOMBRE_CONTENEDOR" \
        && echo "  Borrado" || echo "  Hubo un problema borrando $NOMBRE_CONTENEDOR"

    echo "√ Limpiando directorio de trabajo..."
    rm -rf "$DIR_TRABAJO"

    echo "√ Verificando — ya no debe aparecer $NOMBRE_CONTENEDOR:"
    openstack container list
    openstack object store account show
}

# ----------------------------------------------------------
# Main
# ----------------------------------------------------------
if [[ "$ACCION" == "borrar" ]]; then
    borrar_todo
else
    crear_recursos
fi
