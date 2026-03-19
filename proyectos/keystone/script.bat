@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo --------------------------------------------------
echo Ejecutando script de pruebas de Keystone
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

set "NOMBRE_MANAGER=%NOMBRE_ADMINISTRADOR%-manager"
set "CONTRASENA_MANAGER=%CONTRASENA_ADMINISTRADOR%"

set "NOMBRE_OPERADOR=%NOMBRE_ADMINISTRADOR%-operador"
set "CONTRASENA_OPERADOR=%CONTRASENA_ADMINISTRADOR%"

set "NOMBRE_MONITORING=%NOMBRE_ADMINISTRADOR%-monitoring"
set "CONTRASENA_MONITORING=%CONTRASENA_ADMINISTRADOR%"

set "DOMINIO_CLIENTE=dominio-%NOMBRE_ADMINISTRADOR%-cliente"
set "PROYECTO_CLIENTE=proyecto-%NOMBRE_ADMINISTRADOR%-cliente"

rem ----------------------------------------------------------
rem Main
rem ----------------------------------------------------------

if "%ACCION%"=="borrar" (
    call :borrar_todo
) else (
    call :crear_proyecto
)

exit /b 0

rem ==========================================================
rem SUBROUTINES
rem ==========================================================

rem ----------------------------------------------------------
rem :conectar_como <usuario> <password> <dominio_usuario> [proyecto] [dominio_proyecto]
rem
rem Sin proyecto: scope de dominio  -> OS_DOMAIN_NAME
rem Con proyecto: scope de proyecto -> OS_PROJECT_NAME + OS_PROJECT_DOMAIN_NAME
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
rem :crear_proyecto
rem ----------------------------------------------------------
:crear_proyecto
echo [*] Conectando con administrador
call :conectar_como "%NOMBRE_ADMINISTRADOR%" "%CONTRASENA_ADMINISTRADOR%" "%DOMINIO_ADMINISTRADOR%" "proyecto-%NOMBRE_ADMINISTRADOR%" "%DOMINIO_ADMINISTRADOR%"
openstack token issue

echo [*] Crear dominio para el cliente
openstack domain create "%DOMINIO_CLIENTE%" --description "Dominio del cliente %NOMBRE_ADMINISTRADOR%"
openstack domain show "%DOMINIO_CLIENTE%"

echo [*] Crear usuario manager
openstack user create "%NOMBRE_MANAGER%" --password "%CONTRASENA_MANAGER%" --domain "%DOMINIO_CLIENTE%"
openstack user show "%NOMBRE_MANAGER%" --domain "%DOMINIO_CLIENTE%"

echo [*] Asignar rol manager al usuario manager en el dominio del cliente
openstack role add --user "%NOMBRE_MANAGER%" --user-domain "%DOMINIO_CLIENTE%" --domain "%DOMINIO_CLIENTE%" manager

echo [*] Cambiar a usuario manager
call :conectar_como "%NOMBRE_MANAGER%" "%CONTRASENA_MANAGER%" "%DOMINIO_CLIENTE%"
openstack token issue

echo [*] Ver dominios con el usuario manager
openstack domain list

echo [*] Crear proyecto para el cliente
openstack project create "%PROYECTO_CLIENTE%" --domain "%DOMINIO_CLIENTE%" --description "Proyecto del cliente %NOMBRE_ADMINISTRADOR%"
openstack project show "%PROYECTO_CLIENTE%" --domain "%DOMINIO_CLIENTE%"

echo [*] Crear usuario operador
openstack user create "%NOMBRE_OPERADOR%" --password "%CONTRASENA_OPERADOR%" --domain "%DOMINIO_CLIENTE%"
openstack user show "%NOMBRE_OPERADOR%" --domain "%DOMINIO_CLIENTE%"

echo [*] Asignar rol member al usuario operador en el proyecto del cliente
openstack role add --user "%NOMBRE_OPERADOR%" --user-domain "%DOMINIO_CLIENTE%" --project "%PROYECTO_CLIENTE%" --project-domain "%DOMINIO_CLIENTE%" member

echo [*] Crear usuario monitoring
openstack user create "%NOMBRE_MONITORING%" --password "%CONTRASENA_MONITORING%" --domain "%DOMINIO_CLIENTE%"
openstack user show "%NOMBRE_MONITORING%" --domain "%DOMINIO_CLIENTE%"

echo [*] Asignar rol reader al usuario monitoring en el proyecto del cliente
openstack role add --user "%NOMBRE_MONITORING%" --user-domain "%DOMINIO_CLIENTE%" --project "%PROYECTO_CLIENTE%" --project-domain "%DOMINIO_CLIENTE%" reader

echo [*] Verificar asignaciones de rol
openstack role assignment list --project "%PROYECTO_CLIENTE%" --project-domain "%DOMINIO_CLIENTE%" --names

echo [*] Cambiar a usuario operador (member)
call :conectar_como "%NOMBRE_OPERADOR%" "%CONTRASENA_OPERADOR%" "%DOMINIO_CLIENTE%" "%PROYECTO_CLIENTE%" "%DOMINIO_CLIENTE%"
openstack token issue

rem -------------------------------------------------------
rem DEMO policies Keystone con rol member
rem -------------------------------------------------------

echo   [403 esperado] project list
echo     GET /v3/projects
echo     policy: identity:list_projects
echo     regla:  rule:admin_required or (role:reader and system_scope:all) or ...
echo     member no aparece en ninguna regla de identity -> 403
openstack project list || echo     ^> 403 recibido como se esperaba

echo   [403 esperado] project show por nombre
echo     GET /v3/projects?name=X^&domain_id=Y  ^<- list interno, misma policy -> 403
openstack project show "%PROYECTO_CLIENTE%" --domain "%DOMINIO_CLIENTE%" || echo     ^> 403 recibido como se esperaba

echo   [200 OK] project list --my-projects
echo     GET /v3/auth/projects
echo     policy: identity:list_projects_for_user
echo     regla:  ""  (vacia = sin restriccion) -> 200
openstack project list --my-projects

echo   [200 OK] project show por ID
echo     GET /v3/projects/{id}  ^<- acceso directo, sin list previo
echo     policy: identity:get_project
echo     regla:  ... or project_id:%%(target.project.id)s
echo     token scopeado al proyecto -> condicion cumplida -> 200
set "PROYECTO_ID="
for /f %%i in ('openstack project list --my-projects -f value -c ID') do set "PROYECTO_ID=%%i"
openstack project show "%PROYECTO_ID%"

echo [*] Cambiar a usuario monitoring (reader)
call :conectar_como "%NOMBRE_MONITORING%" "%CONTRASENA_MONITORING%" "%DOMINIO_CLIENTE%" "%PROYECTO_CLIENTE%" "%DOMINIO_CLIENTE%"
openstack token issue

rem -------------------------------------------------------
rem DEMO policies Keystone con rol reader
rem -------------------------------------------------------

echo   [403 esperado] project list
echo     GET /v3/projects
echo     policy: identity:list_projects
echo     regla:  rule:admin_required or (role:reader and system_scope:all) or ...
echo     reader aparece en la regla, pero SOLO con system_scope:all
echo     los tokens de proyecto estandar no tienen system_scope -> 403
openstack project list || echo     ^> 403 recibido como se esperaba

echo   [403 esperado] project show por nombre
echo     GET /v3/projects?name=X^&domain_id=Y  ^<- list interno, misma policy -> 403
openstack project show "%PROYECTO_CLIENTE%" --domain "%DOMINIO_CLIENTE%" || echo     ^> 403 recibido como se esperaba

echo   [200 OK] project list --my-projects
echo     GET /v3/auth/projects
echo     policy: identity:list_projects_for_user
echo     regla:  ""  (vacia = sin restriccion) -> 200
openstack project list --my-projects

echo   [200 OK] project show por ID
echo     GET /v3/projects/{id}  ^<- acceso directo, sin list previo
echo     policy: identity:get_project
echo     regla:  ... or project_id:%%(target.project.id)s -> 200
echo     (la diferencia entre member y reader se vera en Nova/Cinder/Glance)
set "PROYECTO_ID="
for /f %%i in ('openstack project list --my-projects -f value -c ID') do set "PROYECTO_ID=%%i"
openstack project show "%PROYECTO_ID%"

exit /b 0

rem ----------------------------------------------------------
rem :borrar_todo
rem ----------------------------------------------------------
:borrar_todo
echo [*] Conectando con administrador para borrar
call :conectar_como "%NOMBRE_ADMINISTRADOR%" "%CONTRASENA_ADMINISTRADOR%" "%DOMINIO_ADMINISTRADOR%" "proyecto-%NOMBRE_ADMINISTRADOR%" "%DOMINIO_ADMINISTRADOR%"

echo [*] Borrando usuario monitoring...
openstack user delete "%NOMBRE_MONITORING%" --domain "%DOMINIO_CLIENTE%" && echo   Borrado || echo   Hubo un problema borrando %NOMBRE_MONITORING%

echo [*] Borrando usuario operador...
openstack user delete "%NOMBRE_OPERADOR%" --domain "%DOMINIO_CLIENTE%" && echo   Borrado || echo   Hubo un problema borrando %NOMBRE_OPERADOR%

echo [*] Borrando usuario manager...
openstack user delete "%NOMBRE_MANAGER%" --domain "%DOMINIO_CLIENTE%" && echo   Borrado || echo   Hubo un problema borrando %NOMBRE_MANAGER%

echo [*] Borrando proyecto del cliente...
openstack project delete "%PROYECTO_CLIENTE%" --domain "%DOMINIO_CLIENTE%" && echo   Borrado || echo   Hubo un problema borrando %PROYECTO_CLIENTE%

echo [*] Deshabilitando dominio del cliente...
openstack domain set "%DOMINIO_CLIENTE%" --disable && echo   Deshabilitado || echo   Hubo un problema deshabilitando %DOMINIO_CLIENTE%

echo [*] Borrando dominio del cliente...
openstack domain delete "%DOMINIO_CLIENTE%" && echo   Borrado || echo   Hubo un problema borrando %DOMINIO_CLIENTE%

echo [*] Todo borrado correctamente
exit /b 0
