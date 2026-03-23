@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo --------------------------------------------------
echo Ejecutando script de pruebas de Glance
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
set "DOMINIO_ADMINISTRADOR=dominio-%NOMBRE_ADMINISTRADOR%"
set "PROYECTO_ADMINISTRADOR=proyecto-%NOMBRE_ADMINISTRADOR%"

set "NOMBRE_IMAGEN=mi-cirros"
set "URL_CIRROS=http://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img"
set "FICHERO_CIRROS=%TEMP%\cirros-script.img"

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
echo [*] Conectando como %NOMBRE_ADMINISTRADOR%
call :conectar_como "%NOMBRE_ADMINISTRADOR%" "%CONTRASENA_ADMINISTRADOR%" "%DOMINIO_ADMINISTRADOR%" "%PROYECTO_ADMINISTRADOR%" "%DOMINIO_ADMINISTRADOR%"
openstack token issue

echo [*] Verificar que Glance esta disponible
openstack catalog show image

echo [*] Listar imagenes existentes
openstack image list --status active

echo [*] Subir imagen a Glance (o reutilizar si ya existe en este proyecto)
rem --private filtra solo imagenes del proyecto actual: las de otros alumnos
rem con el mismo nombre son invisibles porque estan en sus propios proyectos.
set "IMAGEN_ID="
for /f %%i in ('openstack image list --private --name "%NOMBRE_IMAGEN%" -f value -c ID 2^>nul') do (
    if not defined IMAGEN_ID set "IMAGEN_ID=%%i"
)
if defined IMAGEN_ID (
    echo   Imagen ya existe en este proyecto !IMAGEN_ID!, reutilizando
) else (
    echo [*] Descargar imagen cirros localmente
    curl -L --output "%FICHERO_CIRROS%" "%URL_CIRROS%"
    dir "%FICHERO_CIRROS%"
    for /f %%i in ('openstack image create --container-format bare --disk-format qcow2 --file "%FICHERO_CIRROS%" --private --min-disk 1 --min-ram 64 --property os_distro=cirros --property os_version=0.6.2 -f value -c id "%NOMBRE_IMAGEN%"') do set "IMAGEN_ID=%%i"
    echo   ID: !IMAGEN_ID!
)

echo [*] Ver detalles de la imagen
openstack image show "%IMAGEN_ID%"

echo [*] Listar imagenes ahora (debe aparecer mi-cirros)
openstack image list --status active

echo [*] Anadir etiquetas (tags)
openstack image set --tag lab --tag cirros "%IMAGEN_ID%"
openstack image show "%IMAGEN_ID%" -c name -c tags

echo [*] Anadir propiedades personalizadas
openstack image set --property arquitectura=x86_64 --property uso=lab "%IMAGEN_ID%"
openstack image show "%IMAGEN_ID%" -c name -c properties

echo [*] Cambiar visibilidad a community (visible para todos los proyectos)
openstack image set --community "%IMAGEN_ID%"
openstack image show "%IMAGEN_ID%" -c name -c visibility

echo [*] Volver a private
openstack image set --private "%IMAGEN_ID%"
openstack image show "%IMAGEN_ID%" -c name -c visibility

echo [*] Proteger imagen
openstack image set --protected "%IMAGEN_ID%"
openstack image show "%IMAGEN_ID%" -c name -c protected

echo   [403 esperado] intentar borrar imagen protegida
openstack image delete "%IMAGEN_ID%" || echo   ^> 403 recibido como se esperaba

echo [*] Desactivar imagen (deja de estar disponible para lanzar instancias)
openstack image set --deactivate "%IMAGEN_ID%"
openstack image show "%IMAGEN_ID%" -c name -c status

echo [*] Reactivar imagen
openstack image set --activate "%IMAGEN_ID%"
openstack image show "%IMAGEN_ID%" -c name -c status

echo [*] Desproteger imagen (necesario para poder borrarla despues)
openstack image set --unprotected "%IMAGEN_ID%"

echo [*] Estado final de la imagen:
openstack image show "%IMAGEN_ID%"

exit /b 0

rem ----------------------------------------------------------
rem :borrar_todo
rem ----------------------------------------------------------
:borrar_todo
echo [*] Conectando como %NOMBRE_ADMINISTRADOR% para borrar
call :conectar_como "%NOMBRE_ADMINISTRADOR%" "%CONTRASENA_ADMINISTRADOR%" "%DOMINIO_ADMINISTRADOR%" "%PROYECTO_ADMINISTRADOR%" "%DOMINIO_ADMINISTRADOR%"

echo [*] Borrando todas las imagenes propias llamadas %NOMBRE_IMAGEN%...
for /f %%i in ('openstack image list --private --name "%NOMBRE_IMAGEN%" -f value -c ID 2^>nul') do (
    echo   Procesando %%i...
    openstack image set --unprotected "%%i" >nul 2>&1
    openstack image delete "%%i" && echo   Borrada %%i || echo   Hubo un problema borrando %%i
)

echo [*] Limpiando fichero temporal...
if exist "%FICHERO_CIRROS%" del /f /q "%FICHERO_CIRROS%"

echo [*] Verificando -- ya no debe aparecer %NOMBRE_IMAGEN%:
openstack image list --status active

exit /b 0
