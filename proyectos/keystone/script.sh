echo "--------------------------------------------------"
echo "Ejecutando script de pruebas de Keystone"
echo "--------------------------------------------------"

echo "√ Estableciendo variables de entorno"

# Variables del entorno para Keystone
export URL_KEYSTONE=https://keystone.ivanosuna.com/v3
export VERSION_DEL_API_DE_KEYSTONE=3

# Variables del usuario admin
export NOMBRE_ADMINISTRADOR=profesor
export CONTRASENA_ADMINISTRADOR='Pa$$w0rd'
export DOMINIO_ADMINISTRADOR=dominio-profesor

# Variables del usuario manager:
export NOMBRE_MANAGER=${NOMBRE_ADMINISTRADOR}-manager
export CONTRASENA_MANAGER=${CONTRASENA_ADMINISTRADOR}

# Variables del usuario operador:
export NOMBRE_OPERADOR=${NOMBRE_ADMINISTRADOR}-operador
export CONTRASENA_OPERADOR=${CONTRASENA_ADMINISTRADOR}

# Variables del dominio/proyecto a gestionar
export DOMINIO_CLIENTE=dominio-${NOMBRE_ADMINISTRADOR}-cliente
export PROYECTO_CLIENTE=proyecto-${NOMBRE_ADMINISTRADOR}-cliente

echo "√ Conectando con administrador"
# Conectarme con usuario admin
export OS_AUTH_URL=$URL_KEYSTONE # Exporto con el nombre que necesita el cli: openstack 
export OS_IDENTITY_API_VERSION=$VERSION_DEL_API_DE_KEYSTONE
export OS_USERNAME=$NOMBRE_ADMINISTRADOR
export OS_PASSWORD=$CONTRASENA_ADMINISTRADOR
export OS_USER_DOMAIN_NAME=$DOMINIO_ADMINISTRADOR
# En mi caso, me conecto con scope de dominio, porque el usuario admin solo existe en el dominio profesor.
#export OS_DOMAIN_NAME=$DOMINIO_ADMINISTRADOR
unset OS_PROJECT_NAME
unset OS_PROJECT_DOMAIN_NAME
unset OS_SYSTEM_SCOPE
unset OS_DOMAIN_NAME
export OS_PROJECT_NAME=proyecto-profesor
export OS_PROJECT_DOMAIN_NAME=$DOMINIO_ADMINISTRADOR


openstack token issue

echo "√ Crear dominio para el cliente"
# Creo un dominio para el cliente
openstack domain create $DOMINIO_CLIENTE --description "Dominio del cliente ${NOMBRE_ADMINISTRADOR}"
# Verifico que puedo verlo
openstack domain show $DOMINIO_CLIENTE

# Creo un usuario manager:
echo "√ Crear usuario manager"
openstack user create $NOMBRE_MANAGER --password $CONTRASENA_MANAGER --domain $DOMINIO_CLIENTE
openstack user show $NOMBRE_MANAGER --domain $DOMINIO_CLIENTE 

# Le asigno el role de manager en el dominio del cliente
echo "√ Asignar rol manager al usuario manager en el dominio del cliente"
openstack role add manager --user $NOMBRE_MANAGER --user-domain $DOMINIO_CLIENTE --domain $DOMINIO_CLIENTE

# Cambio de usuario a manager
echo "√ Cambiar a usuario manager"
unset OS_PROJECT_NAME
unset OS_PROJECT_DOMAIN_NAME
unset OS_SYSTEM_SCOPE
unset OS_DOMAIN_NAME
export OS_USERNAME=$NOMBRE_MANAGER
export OS_PASSWORD=$CONTRASENA_MANAGER
export OS_USER_DOMAIN_NAME=$DOMINIO_CLIENTE
export OS_DOMAIN_NAME=$DOMINIO_CLIENTE

openstack token issue

# Ver los dominisos que ve el manager
echo "√ Ver dominios con el usuario manager"
openstack domain list

# Creo un proyecto para el cliente
echo "√ Crear proyecto para el cliente"
openstack project create $PROYECTO_CLIENTE --domain $DOMINIO_CLIENTE --description "Proyecto del cliente ${NOMBRE_ADMINISTRADOR}"
openstack project show $PROYECTO_CLIENTE --domain $DOMINIO_CLIENTE

# Crear usuario operador
echo "√ Crear usuario operador"
openstack user create $NOMBRE_OPERADOR --password $CONTRASENA_OPERADOR --domain $DOMINIO_CLIENTE
openstack user show $NOMBRE_OPERADOR --domain $DOMINIO_CLIENTE

# Le pongo el rol de reader en el proyecto del cliente
echo "√ Asignar rol reader al usuario operador en el proyecto del cliente"
openstack role add reader --user $NOMBRE_OPERADOR --user-domain $DOMINIO_CLIENTE \
         --project $PROYECTO_CLIENTE --project-domain $DOMINIO_CLIENTE

echo "√ Cambiar a usuario operador"
unset OS_PROJECT_NAME
unset OS_PROJECT_DOMAIN_NAME
unset OS_SYSTEM_SCOPE
unset OS_DOMAIN_NAME
export OS_USERNAME=$NOMBRE_OPERADOR
export OS_PASSWORD=$CONTRASENA_OPERADOR
export OS_USER_DOMAIN_NAME=$DOMINIO_CLIENTE
export OS_PROJECT_NAME=$PROYECTO_CLIENTE
export OS_PROJECT_DOMAIN_NAME=$DOMINIO_CLIENTE

openstack token issue

echo "√ Ver proyectos con el usuario operador"
openstack domain list
openstack domain show $DOMINIO_CLIENTE
openstack project list
openstack project show $PROYECTO_CLIENTE --domain $DOMINIO_CLIENTE