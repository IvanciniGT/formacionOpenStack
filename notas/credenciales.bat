rem Esta es la ruta del Openstack (keystone)
set OS_AUTH_URL=https://keystone.ivanosuna.com/v3
set OS_IDENTITY_API_VERSION=3


rem Datos identificativos del usuario (3)

rem Nombre del usuario
set OS_USERNAME=profesor
rem Dominio donde existe el usuario
set OS_USER_DOMAIN_NAME=dominio-profesor 
rem Contraseña del usuario
set OS_PASSWORD='Pa$$w0rd'

rem SCOPE DE ACCESO
rem Hay 3 scopes:

rem Global, de system (1)

rem Proyecto (2)
rem Nombre del proyecto
set OS_PROJECT_NAME=proyecto-profesor
rem Dominio del proyecto
set OS_PROJECT_DOMAIN_NAME=dominio-profesor

rem dominio (1)
rem set OS_DOMAIN_NAME=dominio-profesor
