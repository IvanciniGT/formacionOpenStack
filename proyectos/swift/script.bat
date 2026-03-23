@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo --------------------------------------------------
echo Ejecutando script de pruebas de Swift
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

set "NOMBRE_CONTENEDOR=contenedor-%NOMBRE_ADMINISTRADOR%"
set "NOMBRE_OBJETO=nota.txt"
set "DIR_TRABAJO=%TEMP%\swift-script-%NOMBRE_ADMINISTRADOR%"

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

echo [*] Verificar que Swift esta disponible
openstack catalog show object-store

echo [*] Estado inicial de la cuenta
openstack object store account show

echo [*] Listar contenedores (debe estar vacio)
openstack container list

echo [*] Crear contenedor %NOMBRE_CONTENEDOR%
openstack container create "%NOMBRE_CONTENEDOR%"

echo [*] Ver detalles del contenedor
openstack container show "%NOMBRE_CONTENEDOR%"

echo [*] Listar contenedores ahora
openstack container list

echo [*] Preparar fichero de prueba
if not exist "%DIR_TRABAJO%" mkdir "%DIR_TRABAJO%"
(
    echo Hola OpenStack desde %NOMBRE_ADMINISTRADOR%
    echo version=1.0, entorno=lab
) > "%DIR_TRABAJO%\%NOMBRE_OBJETO%"
type "%DIR_TRABAJO%\%NOMBRE_OBJETO%"

echo [*] Subir objeto al contenedor
rem Cambiamos al directorio de trabajo para que el nombre del objeto sea nota.txt sin ruta
pushd "%DIR_TRABAJO%"
openstack object create "%NOMBRE_CONTENEDOR%" "%NOMBRE_OBJETO%"
popd

echo [*] Listar objetos del contenedor
openstack object list "%NOMBRE_CONTENEDOR%"

echo [*] Listar objetos con detalles (--long)
openstack object list "%NOMBRE_CONTENEDOR%" --long

echo [*] Ver detalles del objeto
openstack object show "%NOMBRE_CONTENEDOR%" "%NOMBRE_OBJETO%"

echo [*] Descargar objeto
openstack object save --file "%DIR_TRABAJO%\nota-descargada.txt" "%NOMBRE_CONTENEDOR%" "%NOMBRE_OBJETO%"
echo   Contenido descargado:
type "%DIR_TRABAJO%\nota-descargada.txt"

echo [*] Anadir metadatos al objeto
openstack object set --property autor=%NOMBRE_ADMINISTRADOR% --property tipo=documento "%NOMBRE_CONTENEDOR%" "%NOMBRE_OBJETO%"
openstack object show "%NOMBRE_CONTENEDOR%" "%NOMBRE_OBJETO%"

echo [*] Anadir metadatos al contenedor
openstack container set --property proyecto=practicas --property entorno=lab "%NOMBRE_CONTENEDOR%"
openstack container show "%NOMBRE_CONTENEDOR%"

echo [*] Hacer contenedor publico (lectura anonima permitida)
openstack container set --property "X-Container-Read=.r:*,.rlistings" "%NOMBRE_CONTENEDOR%"
openstack container show "%NOMBRE_CONTENEDOR%"

echo [*] Volver a privado (quitar ACL de lectura publica)
openstack container unset --property X-Container-Read "%NOMBRE_CONTENEDOR%"
openstack container show "%NOMBRE_CONTENEDOR%"

echo [*] Estado final de la cuenta
openstack object store account show

exit /b 0

rem ----------------------------------------------------------
rem :borrar_todo
rem ----------------------------------------------------------
:borrar_todo
echo [*] Conectando como %NOMBRE_ADMINISTRADOR% para borrar
call :conectar_como "%NOMBRE_ADMINISTRADOR%" "%CONTRASENA_ADMINISTRADOR%" "%DOMINIO_ADMINISTRADOR%" "%PROYECTO_ADMINISTRADOR%" "%DOMINIO_ADMINISTRADOR%"

echo [*] Borrando objeto %NOMBRE_OBJETO% del contenedor %NOMBRE_CONTENEDOR%...
openstack object delete "%NOMBRE_CONTENEDOR%" "%NOMBRE_OBJETO%" && echo   Borrado || echo   Hubo un problema borrando %NOMBRE_OBJETO%

echo [*] Borrando contenedor %NOMBRE_CONTENEDOR%...
openstack container delete "%NOMBRE_CONTENEDOR%" && echo   Borrado || echo   Hubo un problema borrando %NOMBRE_CONTENEDOR%

echo [*] Limpiando directorio de trabajo...
if exist "%DIR_TRABAJO%" rmdir /s /q "%DIR_TRABAJO%"

echo [*] Verificando -- ya no debe aparecer %NOMBRE_CONTENEDOR%:
openstack container list
openstack object store account show

exit /b 0
