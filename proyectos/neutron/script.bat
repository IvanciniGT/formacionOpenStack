@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo --------------------------------------------------
echo Ejecutando script de pruebas de Neutron
echo --------------------------------------------------

rem ----------------------------------------------------------
rem Parseo de argumentos
rem ----------------------------------------------------------

set ACCION=crear
set NOMBRE_ADMINISTRADOR=

:parse_args
if "%~1"=="" goto end_parse
if /i "%~1"=="--borrar" (
    set ACCION=borrar
    shift
    goto parse_args
)
if /i "%~1"=="--admin" (
    if "%~2"=="" (
        echo Error: --admin requiere un nombre de usuario
        exit /b 1
    )
    set NOMBRE_ADMINISTRADOR=%~2
    shift
    shift
    goto parse_args
)
echo Uso: %~nx0 --admin ^<usuario^> [--borrar]
exit /b 1

:end_parse

if "%NOMBRE_ADMINISTRADOR%"=="" (
    echo Error: es obligatorio indicar el administrador con --admin ^<usuario^>
    echo Uso: %~nx0 --admin ^<usuario^> [--borrar]
    exit /b 1
)

rem ----------------------------------------------------------
rem Variables
rem ----------------------------------------------------------

set "URL_KEYSTONE=https://keystone.ivanosuna.com/v3"
set "VERSION_DEL_API_DE_KEYSTONE=3"

set "CONTRASENA_ADMINISTRADOR=Pa$$w0rd"

set "NOMBRE_OPERATOR=%NOMBRE_ADMINISTRADOR%-operador"
set "NOMBRE_MONITORING=%NOMBRE_ADMINISTRADOR%-monitoring"

set "DOMINIO_CLIENTE=dominio-%NOMBRE_ADMINISTRADOR%-cliente"
set "PROYECTO_CLIENTE=proyecto-%NOMBRE_ADMINISTRADOR%-cliente"

set "RED=red-%NOMBRE_ADMINISTRADOR%"
set "SUBNET_1=%RED%-1"
set "CIDR_1=10.1.0.0/24"
set "GATEWAY_1=10.1.0.1"
set "SUBNET_2=%RED%-2"
set "CIDR_2=10.2.0.0/24"
set "IP_MARIADB=10.2.0.10"

set "ROUTER=router-%NOMBRE_ADMINISTRADOR%"
set "RED_EXTERNA=external"

set "SG_NGINX=sg-%NOMBRE_ADMINISTRADOR%-nginx"
set "SG_MARIADB=sg-%NOMBRE_ADMINISTRADOR%-mariadb"
set "PUERTO_MARIADB=puerto-%NOMBRE_ADMINISTRADOR%-mariadb"

rem ----------------------------------------------------------
rem Main
rem ----------------------------------------------------------

if "%ACCION%"=="borrar" (
    call :borrar_todo
) else (
    call :crear_recursos
)

exit /b 0

rem ==========================================================
rem SUBROUTINES
rem ==========================================================

rem ----------------------------------------------------------
rem :conectar_como <usuario> <password> <dominio_usuario> [proyecto] [dominio_proyecto]
rem ----------------------------------------------------------
:conectar_como
set "OS_AUTH_URL=%URL_KEYSTONE%"
set "OS_IDENTITY_API_VERSION=%VERSION_DEL_API_DE_KEYSTONE%"
set "OS_USERNAME=%~1"
set "OS_PASSWORD=%~2"
set "OS_USER_DOMAIN_NAME=%~3"
set "OS_PROJECT_NAME="
set "OS_PROJECT_DOMAIN_NAME="
set "OS_DOMAIN_NAME="
set "OS_SYSTEM_SCOPE="
if "%~4"=="" (
    set "OS_DOMAIN_NAME=%~3"
) else (
    set "OS_PROJECT_NAME=%~4"
    if "%~5"=="" (
        set "OS_PROJECT_DOMAIN_NAME=%~3"
    ) else (
        set "OS_PROJECT_DOMAIN_NAME=%~5"
    )
)
exit /b 0

rem ----------------------------------------------------------
rem :crear_recursos
rem ----------------------------------------------------------
:crear_recursos
echo [*] Conectando como operator (%NOMBRE_OPERATOR%) en %PROYECTO_CLIENTE%
call :conectar_como "%NOMBRE_OPERATOR%" "%CONTRASENA_ADMINISTRADOR%" "%DOMINIO_CLIENTE%" "%PROYECTO_CLIENTE%" "%DOMINIO_CLIENTE%"
openstack token issue

echo [*] Verificar que Neutron esta disponible
openstack catalog show network

echo [*] Ver la red externa (provider) disponible
openstack network show "%RED_EXTERNA%"
openstack subnet list --network "%RED_EXTERNA%"

rem ----------------------------------------------------------
rem RED
rem ----------------------------------------------------------
echo [*] Crear red interna %RED%
for /f "tokens=*" %%i in ('openstack network create "%RED%" -f value -c id') do set RED_ID=%%i
openstack network show "%RED_ID%"

rem ----------------------------------------------------------
rem SUBNET 1: para NGINX - con DHCP
rem ----------------------------------------------------------
echo [*] Crear subnet %SUBNET_1% (%CIDR_1%) con DHCP -- para NGINX
for /f "tokens=*" %%i in ('openstack subnet create "%SUBNET_1%" --network "%RED_ID%" --subnet-range "%CIDR_1%" --gateway "%GATEWAY_1%" --dns-nameserver 8.8.8.8 -f value -c id') do set SUBNET_1_ID=%%i
openstack subnet show "%SUBNET_1_ID%"

rem ----------------------------------------------------------
rem SUBNET 2: para MariaDB - sin DHCP, IP fija
rem ----------------------------------------------------------
echo [*] Crear subnet %SUBNET_2% (%CIDR_2%) sin DHCP -- para MariaDB
for /f "tokens=*" %%i in ('openstack subnet create "%SUBNET_2%" --network "%RED_ID%" --subnet-range "%CIDR_2%" --gateway "10.2.0.1" --no-dhcp -f value -c id') do set SUBNET_2_ID=%%i
openstack subnet show "%SUBNET_2_ID%"

rem ----------------------------------------------------------
rem PUERTO con IP fija para MariaDB
rem ----------------------------------------------------------
echo [*] Crear puerto %PUERTO_MARIADB% con IP fija %IP_MARIADB%
for /f "tokens=*" %%i in ('openstack port create --network "%RED_ID%" --fixed-ip "subnet=%SUBNET_2_ID%,ip-address=%IP_MARIADB%" "%PUERTO_MARIADB%" -f value -c id') do set PUERTO_MARIADB_ID=%%i
openstack port show "%PUERTO_MARIADB_ID%"

rem ----------------------------------------------------------
rem ROUTER
rem ----------------------------------------------------------
echo [*] Crear router %ROUTER%
for /f "tokens=*" %%i in ('openstack router create "%ROUTER%" -f value -c id') do set ROUTER_ID=%%i

echo [*] Conectar router a la red externa (gateway)
openstack router set "%ROUTER_ID%" --external-gateway "%RED_EXTERNA%"

echo [*] Anadir subnet-1 al router (NGINX tiene salida a internet)
openstack router add subnet "%ROUTER_ID%" "%SUBNET_1_ID%"

echo [*] Anadir subnet-2 al router (MariaDB tiene salida a internet)
openstack router add subnet "%ROUTER_ID%" "%SUBNET_2_ID%"

openstack router show "%ROUTER_ID%"

rem ----------------------------------------------------------
rem SECURITY GROUP NGINX: 80, 443 + ICMP + SSH
rem ----------------------------------------------------------
echo [*] Crear security group %SG_NGINX% (NGINX: HTTP 80, HTTPS 443, ICMP, SSH)
for /f "tokens=*" %%i in ('openstack security group create "%SG_NGINX%" --description "Reglas para la VM de NGINX: HTTP, HTTPS, ICMP, SSH" -f value -c id') do set SG_NGINX_ID=%%i

openstack security group rule create "%SG_NGINX_ID%" --protocol tcp --dst-port 80 --ingress
openstack security group rule create "%SG_NGINX_ID%" --protocol tcp --dst-port 443 --ingress
openstack security group rule create "%SG_NGINX_ID%" --protocol icmp --ingress
openstack security group rule create "%SG_NGINX_ID%" --protocol tcp --dst-port 22 --ingress

openstack security group rule list "%SG_NGINX_ID%" --column Direction --column "IP Protocol" --column "Port Range" --column "IP Range"

rem ----------------------------------------------------------
rem SECURITY GROUP MARIADB: 3306 desde la red interna
rem ----------------------------------------------------------
echo [*] Crear security group %SG_MARIADB% (MariaDB: puerto 3306 desde red interna)
for /f "tokens=*" %%i in ('openstack security group create "%SG_MARIADB%" --description "Reglas para la VM de MariaDB: MySQL 3306 solo desde red interna" -f value -c id') do set SG_MARIADB_ID=%%i

openstack security group rule create "%SG_MARIADB_ID%" --protocol tcp --dst-port 3306 --ingress --remote-ip "%CIDR_1%"
openstack security group rule create "%SG_MARIADB_ID%" --protocol icmp --ingress --remote-ip "%CIDR_1%"
openstack security group rule create "%SG_MARIADB_ID%" --protocol tcp --dst-port 22 --ingress --remote-ip "%CIDR_1%"

openstack security group rule list "%SG_MARIADB_ID%" --column Direction --column "IP Protocol" --column "Port Range" --column "IP Range"

rem ----------------------------------------------------------
rem FLOATING IP para NGINX
rem ----------------------------------------------------------
echo [*] Reservar floating IP para NGINX
for /f "tokens=*" %%i in ('openstack floating ip create "%RED_EXTERNA%" -f value -c id') do set FIP_ID=%%i
for /f "tokens=*" %%i in ('openstack floating ip show "%FIP_ID%" -f value -c floating_ip_address') do set FIP_ADDR=%%i
echo   Floating IP reservada: %FIP_ADDR% (id: %FIP_ID%)

rem ----------------------------------------------------------
rem RESUMEN - visto como monitoring (rol reader)
rem ----------------------------------------------------------
echo [*] Cambiando a monitoring (reader) para el resumen
call :conectar_como "%NOMBRE_MONITORING%" "%CONTRASENA_ADMINISTRADOR%" "%DOMINIO_CLIENTE%" "%PROYECTO_CLIENTE%" "%DOMINIO_CLIENTE%"

echo.
echo ======================================================
echo RESUMEN DE TOPOLOGIA (visto como monitoring/reader)
echo ======================================================
openstack network list
openstack subnet list
openstack router list
openstack security group list
openstack floating ip list

echo.
echo   FIP NGINX:          %FIP_ADDR%
echo   Puerto MariaDB:     %PUERTO_MARIADB%  IP=%IP_MARIADB%
echo   SG Nginx:           %SG_NGINX%
echo   SG MariaDB:         %SG_MARIADB%
echo.
echo   PROXIMO PASO: lanzar las VMs en Nova
echo     VM nginx:    --nic net-id=^<id-%RED%^>              --security-group %SG_NGINX%
echo     VM mariadb:  --nic port-id=^<id-%PUERTO_MARIADB%^>  --security-group %SG_MARIADB%

exit /b 0

rem ----------------------------------------------------------
rem :borrar_todo
rem ----------------------------------------------------------
:borrar_todo
echo [*] Conectando como operator (%NOMBRE_OPERATOR%) para borrar
call :conectar_como "%NOMBRE_OPERATOR%" "%CONTRASENA_ADMINISTRADOR%" "%DOMINIO_CLIENTE%" "%PROYECTO_CLIENTE%" "%DOMINIO_CLIENTE%"

echo [*] Liberando floating IPs...
for /f "tokens=*" %%i in ('openstack floating ip list -f value -c ID') do (
    openstack floating ip delete "%%i" && echo   FIP %%i eliminada || echo   Problema eliminando FIP %%i
)

echo [*] Borrando puerto %PUERTO_MARIADB%...
openstack port delete "%PUERTO_MARIADB%" && echo   Borrado || echo   Hubo un problema borrando %PUERTO_MARIADB%

echo [*] Quitando subnets del router...
openstack router remove subnet "%ROUTER%" "%SUBNET_1%" && echo   %SUBNET_1% desconectada || echo   Problema desconectando %SUBNET_1%
openstack router remove subnet "%ROUTER%" "%SUBNET_2%" && echo   %SUBNET_2% desconectada || echo   Problema desconectando %SUBNET_2%

echo [*] Quitando gateway del router...
openstack router unset "%ROUTER%" --external-gateway && echo   Gateway eliminado || echo   Problema eliminando gateway

echo [*] Borrando router %ROUTER%...
openstack router delete "%ROUTER%" && echo   Borrado || echo   Hubo un problema borrando %ROUTER%

echo [*] Borrando subnets...
openstack subnet delete "%SUBNET_1%" && echo   %SUBNET_1% borrada || echo   Hubo un problema borrando %SUBNET_1%
openstack subnet delete "%SUBNET_2%" && echo   %SUBNET_2% borrada || echo   Hubo un problema borrando %SUBNET_2%

echo [*] Borrando red %RED%...
openstack network delete "%RED%" && echo   Borrada || echo   Hubo un problema borrando %RED%

echo [*] Borrando security group %SG_NGINX%...
openstack security group delete "%SG_NGINX%" && echo   Borrado || echo   Hubo un problema borrando %SG_NGINX%

echo [*] Borrando security group %SG_MARIADB%...
openstack security group delete "%SG_MARIADB%" && echo   Borrado || echo   Hubo un problema borrando %SG_MARIADB%

echo [*] Estado final:
openstack network list
openstack security group list
openstack floating ip list

exit /b 0
