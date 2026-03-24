#!/usr/bin/env bash
set -euo pipefail

echo "--------------------------------------------------"
echo "Ejecutando script de pruebas de Neutron"
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

# Usuarios del dominio cliente (creados en el lab de Keystone)
NOMBRE_OPERATOR=${NOMBRE_ADMINISTRADOR}-operador
DOMINIO_CLIENTE=dominio-${NOMBRE_ADMINISTRADOR}-cliente
PROYECTO_CLIENTE=proyecto-${NOMBRE_ADMINISTRADOR}-cliente

# Recursos de red
RED=red-${NOMBRE_ADMINISTRADOR}

SUBNET_1=${RED}-1
CIDR_1=10.1.0.0/24
GATEWAY_1=10.1.0.1

SUBNET_2=${RED}-2
CIDR_2=10.2.0.0/24
# Sin DHCP: IP fija para MariaDB
IP_MARIADB=10.2.0.10

ROUTER=router-${NOMBRE_ADMINISTRADOR}
RED_EXTERNA=external

SG_NGINX=sg-${NOMBRE_ADMINISTRADOR}-nginx
SG_MARIADB=sg-${NOMBRE_ADMINISTRADOR}-mariadb

PUERTO_MARIADB=puerto-${NOMBRE_ADMINISTRADOR}-mariadb

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
    # Las operaciones de red las hace el operator (rol member en proyecto-cliente)
    echo "√ Conectando como operator ($NOMBRE_OPERATOR) en $PROYECTO_CLIENTE"
    conectar_como "$NOMBRE_OPERATOR" "$CONTRASENA_ADMINISTRADOR" \
        "$DOMINIO_CLIENTE" "$PROYECTO_CLIENTE" "$DOMINIO_CLIENTE"
    openstack token issue

    echo "√ Verificar que Neutron está disponible"
    openstack catalog show network

    echo "√ Ver la red externa (provider) disponible"
    openstack network show "$RED_EXTERNA"
    openstack subnet list --network "$RED_EXTERNA"

    # ----------------------------------------------------------
    # RED
    # ----------------------------------------------------------
    echo "√ Crear red interna $RED"
    RED_ID=$(openstack network create "$RED" -f value -c id)
    openstack network show "$RED_ID"

    # ----------------------------------------------------------
    # SUBNET 1: para NGINX — con DHCP
    # ----------------------------------------------------------
    echo "√ Crear subnet $SUBNET_1 ($CIDR_1) con DHCP — para NGINX"
    SUBNET_1_ID=$(openstack subnet create "$SUBNET_1" \
        --network    "$RED_ID" \
        --subnet-range "$CIDR_1" \
        --gateway    "$GATEWAY_1" \
        --dns-nameserver 8.8.8.8 \
        -f value -c id)
    openstack subnet show "$SUBNET_1_ID"

    # ----------------------------------------------------------
    # SUBNET 2: para MariaDB — sin DHCP, IP fija
    # ----------------------------------------------------------
    echo "√ Crear subnet $SUBNET_2 ($CIDR_2) sin DHCP — para MariaDB"
    SUBNET_2_ID=$(openstack subnet create "$SUBNET_2" \
        --network    "$RED_ID" \
        --subnet-range "10.2.0.0/24" \
        --gateway    "10.2.0.1" \
        --no-dhcp \
        -f value -c id)
    openstack subnet show "$SUBNET_2_ID"

    # ----------------------------------------------------------
    # PUERTO con IP fija para MariaDB
    # Creamos el puerto antes de lanzar la VM; así podemos
    # asignar $IP_MARIADB de forma determinista.
    # ----------------------------------------------------------
    echo "√ Crear puerto $PUERTO_MARIADB con IP fija $IP_MARIADB"
    PUERTO_MARIADB_ID=$(openstack port create \
        --network "$RED_ID" \
        --fixed-ip "subnet=${SUBNET_2_ID},ip-address=${IP_MARIADB}" \
        "$PUERTO_MARIADB" \
        -f value -c id)
    openstack port show "$PUERTO_MARIADB_ID"

    # ----------------------------------------------------------
    # ROUTER
    # ----------------------------------------------------------
    echo "√ Crear router $ROUTER"
    ROUTER_ID=$(openstack router create "$ROUTER" -f value -c id)

    echo "√ Conectar router a la red externa (gateway)"
    openstack router set "$ROUTER_ID" --external-gateway "$RED_EXTERNA"

    echo "√ Añadir subnet-1 al router (NGINX tiene salida a internet)"
    openstack router add subnet "$ROUTER_ID" "$SUBNET_1_ID"

    echo "√ Añadir subnet-2 al router (MariaDB tiene salida a internet)"
    openstack router add subnet "$ROUTER_ID" "$SUBNET_2_ID"

    openstack router show "$ROUTER_ID"

    # ----------------------------------------------------------
    # SECURITY GROUP NGINX: 80, 443 + ICMP + SSH
    # ----------------------------------------------------------
    echo "√ Crear security group $SG_NGINX (NGINX: HTTP 80, HTTPS 443, ICMP, SSH)"
    SG_NGINX_ID=$(openstack security group create "$SG_NGINX" \
        --description "Reglas para la VM de NGINX: HTTP, HTTPS, ICMP, SSH" \
        -f value -c id)

    # HTTP
    openstack security group rule create "$SG_NGINX_ID" \
        --protocol tcp --dst-port 80 --ingress
    # HTTPS
    openstack security group rule create "$SG_NGINX_ID" \
        --protocol tcp --dst-port 443 --ingress
    # ICMP (ping desde cualquier origen)
    openstack security group rule create "$SG_NGINX_ID" \
        --protocol icmp --ingress
    # SSH (para administración)
    openstack security group rule create "$SG_NGINX_ID" \
        --protocol tcp --dst-port 22 --ingress

    openstack security group rule list "$SG_NGINX_ID" \
        --column Direction \
        --column "IP Protocol" \
        --column "Port Range" \
        --column "IP Range"

    # ----------------------------------------------------------
    # SECURITY GROUP MARIADB: 3306 desde la red interna
    # ----------------------------------------------------------
    echo "√ Crear security group $SG_MARIADB (MariaDB: puerto 3306 desde red interna)"
    SG_MARIADB_ID=$(openstack security group create "$SG_MARIADB" \
        --description "Reglas para la VM de MariaDB: MySQL 3306 solo desde red interna" \
        -f value -c id)

    # MySQL: solo desde la subnet de NGINX (no expuesto al exterior)
    openstack security group rule create "$SG_MARIADB_ID" \
        --protocol tcp --dst-port 3306 --ingress \
        --remote-ip "$CIDR_1"
    # ICMP desde la red interna (para debugging)
    openstack security group rule create "$SG_MARIADB_ID" \
        --protocol icmp --ingress \
        --remote-ip "$CIDR_1"
    # SSH desde la red interna (para administración vía jump host)
    openstack security group rule create "$SG_MARIADB_ID" \
        --protocol tcp --dst-port 22 --ingress \
        --remote-ip "$CIDR_1"

    openstack security group rule list "$SG_MARIADB_ID" \
        --column Direction \
        --column "IP Protocol" \
        --column "Port Range" \
        --column "IP Range"

    # ----------------------------------------------------------
    # FLOATING IP para NGINX
    # ----------------------------------------------------------
    echo "√ Reservar floating IP para NGINX"
    FIP_ID=$(openstack floating ip create "$RED_EXTERNA" -f value -c id)
    FIP_ADDR=$(openstack floating ip show "$FIP_ID" -f value -c floating_ip_address)
    echo "  Floating IP reservada: $FIP_ADDR (id: $FIP_ID)"

    # ----------------------------------------------------------
    # RESUMEN — lo ejecutamos con monitoring (rol reader) para
    # comprobar qué puede ver un usuario de solo lectura
    # ----------------------------------------------------------
    NOMBRE_MONITORING=${NOMBRE_ADMINISTRADOR}-monitoring
    conectar_como "$NOMBRE_MONITORING" "$CONTRASENA_ADMINISTRADOR" \
        "$DOMINIO_CLIENTE" "$PROYECTO_CLIENTE" "$DOMINIO_CLIENTE"

    echo ""
    echo "======================================================"
    echo "RESUMEN DE TOPOLOGÍA (visto como monitoring/reader)"
    echo "======================================================"
    openstack network list
    openstack subnet list
    openstack router list
    openstack security group list
    openstack floating ip list
    echo ""
    echo "  FIP NGINX:          $FIP_ADDR"
    echo "  Puerto MariaDB:     $PUERTO_MARIADB  IP=$IP_MARIADB"
    echo "  SG Nginx:           $SG_NGINX"
    echo "  SG MariaDB:         $SG_MARIADB"
    echo ""
    echo "  PRÓXIMO PASO: lanzar las VMs en Nova"
    echo "    VM nginx:    --nic net-id=<id-$RED>             --security-group $SG_NGINX"
    echo "    VM mariadb:  --nic port-id=<id-$PUERTO_MARIADB> --security-group $SG_MARIADB"
}

# ----------------------------------------------------------
# borrar_todo
# ----------------------------------------------------------
borrar_todo() {
    echo "√ Conectando como operator ($NOMBRE_OPERATOR) para borrar"
    conectar_como "$NOMBRE_OPERATOR" "$CONTRASENA_ADMINISTRADOR" \
        "$DOMINIO_CLIENTE" "$PROYECTO_CLIENTE" "$DOMINIO_CLIENTE"

    echo "√ Liberando floating IPs..."
    while IFS= read -r fip_id; do
        [[ -z "$fip_id" ]] && continue
        openstack floating ip delete "$fip_id" \
            && echo "  FIP $fip_id eliminada" || echo "  Problema eliminando FIP $fip_id"
    done < <(openstack floating ip list -f value -c ID)

    echo "√ Borrando puerto $PUERTO_MARIADB..."
    openstack port delete "$PUERTO_MARIADB" \
        && echo "  Borrado" || echo "  Hubo un problema borrando $PUERTO_MARIADB"

    echo "√ Quitando subnets del router..."
    openstack router remove subnet "$ROUTER" "$SUBNET_1" \
        && echo "  $SUBNET_1 desconectada" || echo "  Problema desconectando $SUBNET_1"
    openstack router remove subnet "$ROUTER" "$SUBNET_2" \
        && echo "  $SUBNET_2 desconectada" || echo "  Problema desconectando $SUBNET_2"

    echo "√ Quitando gateway del router..."
    openstack router unset "$ROUTER" --external-gateway \
        && echo "  Gateway eliminado" || echo "  Problema eliminando gateway"

    echo "√ Borrando router $ROUTER..."
    openstack router delete "$ROUTER" \
        && echo "  Borrado" || echo "  Hubo un problema borrando $ROUTER"

    echo "√ Borrando subnets..."
    openstack subnet delete "$SUBNET_1" \
        && echo "  $SUBNET_1 borrada" || echo "  Hubo un problema borrando $SUBNET_1"
    openstack subnet delete "$SUBNET_2" \
        && echo "  $SUBNET_2 borrada" || echo "  Hubo un problema borrando $SUBNET_2"

    echo "√ Borrando red $RED..."
    openstack network delete "$RED" \
        && echo "  Borrada" || echo "  Hubo un problema borrando $RED"

    echo "√ Borrando security group $SG_NGINX..."
    openstack security group delete "$SG_NGINX" \
        && echo "  Borrado" || echo "  Hubo un problema borrando $SG_NGINX"

    echo "√ Borrando security group $SG_MARIADB..."
    openstack security group delete "$SG_MARIADB" \
        && echo "  Borrado" || echo "  Hubo un problema borrando $SG_MARIADB"

    echo "√ Estado final:"
    openstack network list
    openstack security group list
    openstack floating ip list
}

# ----------------------------------------------------------
# Main
# ----------------------------------------------------------
if [[ "$ACCION" == "borrar" ]]; then
    borrar_todo
else
    crear_recursos
fi
