# Primeros pasos con OpenStack CLI

## Objetivo

En este laboratorio vas a:

- configurar el entorno para hablar con OpenStack
- verificar que estás correctamente autenticado
- explorar regiones, servicios y endpoints del cloud
- entender con qué identidad estás operando
- aprender los comandos de ayuda y navegación básica
- conocer los dos métodos de autenticación: `openrc` y `clouds.yaml`

> Este lab no modifica nada. Solo lee. Es completamente seguro ejecutarlo en cualquier momento.

---

# 1. Configurar el entorno

Antes de poder hacer cualquier cosa con la CLI, tienes que decirle a OpenStack **quién eres** y **a qué cloud hablas**.

Hay dos métodos para hacerlo. Elige uno (o aprende los dos).

---

## Método A — Fichero openrc (variables de entorno)

El fichero `openrc.cmd` define variables de entorno que el cliente lee automáticamente.

### 1.1 Activar el entorno virtual

```bat
rem Activa el entorno virtual donde instalaste python-openstackclient.
rem Mientras esté activo, el comando "openstack" estará disponible en este terminal.
%USERPROFILE%\openstack-client\Scripts\activate
```

### 1.2 Cargar el openrc

```bat
rem Carga las variables de entorno con tus credenciales.
rem "call" es obligatorio para que las variables queden activas en este terminal.
rem Sin "call", el fichero se ejecutaría en un subproceso y las variables se perderían.
call alumno1-openrc.cmd
```

### 1.3 Verificar qué variables hay cargadas

```bat
rem Muestra el valor de las variables OS_* que están activas en este terminal.
rem Sirve para confirmar que el openrc se ha cargado correctamente.
rem Si alguna variable está vacía o equivocada, aquí lo verás.
set OS_
```

Deberías ver algo como:

```
OS_AUTH_URL=https://keystone.ivanosuna.com/v3
OS_PROJECT_DOMAIN_NAME=dominio-alumno1
OS_PROJECT_NAME=proyecto-alumno1
OS_USER_DOMAIN_NAME=dominio-alumno1
OS_USERNAME=alumno1
OS_PASSWORD=<tu password>
OS_REGION_NAME=RegionOne
OS_IDENTITY_API_VERSION=3
```

---

## Método B — Fichero clouds.yaml

`clouds.yaml` permite almacenar múltiples perfiles de cloud en un solo fichero.

### Ubicación del fichero

- **Windows:** `%APPDATA%\openstack\clouds.yaml`
- **Linux/macOS:** `~/.config/openstack/clouds.yaml`

### Estructura del fichero

```yaml
clouds:
  alumno1:
    auth:
      auth_url: https://keystone.ivanosuna.com/v3
      username: alumno1
      password: Pa$$w0rd
      project_name: proyecto-alumno1
      user_domain_name: dominio-alumno1
      project_domain_name: dominio-alumno1
    region_name: RegionOne
    identity_api_version: 3
```

### Usarlo desde la CLI

```bat
rem Ejecuta el comando usando el perfil "alumno1" definido en clouds.yaml.
rem No necesita haber cargado ningún openrc previamente.
openstack --os-cloud alumno1 project list
```

O bien activarlo como contexto para toda la sesión:

```bat
rem Define el perfil activo para todos los comandos de esta sesión.
rem A partir de aquí no hace falta poner --os-cloud en cada comando.
set OS_CLOUD=alumno1
openstack project list
```

> **Nota:** si tienes cargado un openrc Y también tienes definido `OS_CLOUD`, las variables `OS_*` individuales tienen prioridad sobre `clouds.yaml`. Para evitar confusiones, usa solo uno de los dos métodos.

---

# 2. Verificar autenticación

Una vez configurado el entorno, lo primero es confirmar que puedes obtener un token.

## 2.1 Solicitar un token

```bat
rem Solicita a Keystone un token de acceso con tus credenciales actuales.
rem Si devuelve datos (id, expires, project_id...) la autenticación funciona.
rem Si devuelve "HTTP 401 Unauthorized", las credenciales son incorrectas.
rem Si devuelve "connection refused" o timeout, la URL de Keystone no es accesible.
openstack token issue
```

Salida esperada:

```
+------------+----------------------------------+
| Field      | Value                            |
+------------+----------------------------------+
| expires    | 2026-03-17T11:00:00+0000         |
| id         | gAAAAABh...                      |
| project_id | a3f2...                          |
| user_id    | 8d91...                          |
+------------+----------------------------------+
```

> **Importante:** si este comando falla, para. No tiene sentido continuar sin autenticación. Revisa las variables `OS_*` con `set OS_` o comprueba tu `clouds.yaml`.

## 2.2 Ver el token en formato JSON

```bat
rem Muestra la misma información del token pero en formato JSON.
rem Útil para procesarlo con scripts o para ver los datos más claramente.
rem El comando "token issue" siempre devuelve: id, expires, project_id, user_id.
openstack token issue -f json
```

---

# 3. ¿Quién soy yo?

## 3.1 Ver tu usuario

```bat
rem Muestra la información de tu usuario: id, nombre, dominio y estado (enabled).
rem "show" sin nombre de usuario muestra el usuario autenticado en este momento.
openstack user show $(openstack token issue -f value -c user_id)
```

En Windows `cmd.exe` no hay sustitución de comandos con `$()`. Hazlo en dos pasos:

```bat
rem Paso 1: obtén tu user_id.
rem "-f value" devuelve solo el valor, sin cabeceras de tabla.
rem "-c user_id" filtra solo la columna que nos interesa.
openstack token issue -f value -c user_id
```

```bat
rem Paso 2: pega el ID devuelto en el siguiente comando.
rem Sustituye <ID> por el valor real que obtuviste arriba.
openstack user show <ID>
```

## 3.2 Ver tu proyecto activo

```bat
rem Muestra información del proyecto con el que estás autenticado en este momento.
rem Es el proyecto que aparece en OS_PROJECT_NAME o en tu perfil de clouds.yaml.
openstack project show <nombre-de-tu-proyecto>
```

Ejemplo:

```bat
rem Muestra los detalles del proyecto del alumno 1.
openstack project show proyecto-alumno1
```

## 3.3 Ver tu dominio

```bat
rem Muestra la información del dominio al que pertenece tu usuario.
rem Comprueba que el dominio está habilitado (enabled = True).
openstack domain show dominio-alumno1
```

---

# 4. Regiones

OpenStack soporta múltiples regiones geográficas. Todos los endpoints se asocian a una región.

## 4.1 Ver las regiones disponibles

```bat
rem Lista todas las regiones definidas en este cloud.
rem En nuestro entorno solo hay una: RegionOne.
rem En clouds más grandes puede haber "eu-west-1", "us-east-1", etc.
openstack region list
```

## 4.2 Consultar qué región estás usando

```bat
rem Muestra el valor de la variable que define la región activa.
rem Los comandos de la CLI la usan para saber contra qué endpoints hablar.
set OS_REGION_NAME
```

## 4.3 Cambiar de región temporalmente

Si el cloud tuviese varias regiones, podrías cambiar así:

```bat
rem Cambia la región activa solo para esta sesión de terminal.
rem Todos los comandos posteriores hablarán contra los endpoints de esa región.
set OS_REGION_NAME=OtraRegion
```

---

# 5. Servicios y catálogo

El **catálogo de servicios** es el mapa del cloud: lista qué servicios existen y dónde viven sus APIs.

## 5.1 Ver el catálogo completo

```bat
rem Lista todos los servicios con su nombre, tipo y endpoints públicos.
rem Es lo primero que Keystone devuelve al autenticarte (incluido en el token).
rem En nuestro entorno verás: keystone, glance, swift, cinderv3 y placement.
openstack catalog list
```

## 5.2 Ver solo los servicios (sin endpoints)

```bat
rem Lista los servicios registrados en Keystone por nombre y tipo.
rem El campo "type" identifica la función: identity, compute, image, network...
rem Un servicio aparece aquí aunque no tenga endpoints configurados.
openstack service list
```

## 5.3 Ver los endpoints

Los endpoints son las URLs reales donde escucha cada API.

```bat
rem Lista todos los endpoints de todos los servicios.
rem Cada servicio suele tener hasta tres endpoints:
rem   public   → accesible desde Internet o desde los clientes
rem   internal → solo accesible desde la red interna del cloud
rem   admin    → para operaciones administrativas (no siempre expuesto)
openstack endpoint list
```

## 5.4 Ver los endpoints de un servicio concreto

```bat
rem Filtra los endpoints del servicio "identity" (Keystone).
rem Sustituye "identity" por "image", "compute", etc., para ver otros servicios.
openstack endpoint list --service identity
```

## 5.5 Ver los detalles de un endpoint

```bat
rem Muestra todos los campos de un endpoint concreto: URL, interfaz, región, estado.
rem Sustituye <ID> por el id del endpoint que quieras inspeccionar.
openstack endpoint show <ID>
```

---

# 6. Información de la versión y conectividad

## 6.1 Ver la versión del cliente

```bat
rem Muestra la versión del cliente python-openstackclient instalado.
rem Útil para comprobar si está actualizado o diagnosticar incompatibilidades.
openstack --version
```

## 6.2 Ver las versiones de la API de Keystone

```bat
rem Lista las versiones de la API de Identity disponibles en el endpoint.
rem Comprueba que la versión 3 está en estado "stable" o "current".
openstack versions show
```

---

# 7. Ayuda y navegación

## 7.1 Ayuda general

```bat
rem Muestra la lista completa de comandos disponibles en la CLI.
rem Está organizada por recurso (server, network, image, project...).
openstack help
```

## 7.2 Ayuda de un comando concreto

```bat
rem Muestra la sintaxis, argumentos y opciones de un comando específico.
rem Sustituye "token issue" por cualquier otro comando que quieras consultar.
openstack help token issue
```

O con `--help`:

```bat
rem Alternativa al comando help: añade --help al final del comando.
openstack token issue --help
```

## 7.3 Listar comandos de un recurso

```bat
rem Muestra todos los subcomandos disponibles para "endpoint".
rem Prueba con "project", "user", "domain", "service", "region"...
openstack endpoint --help
```

---

# 8. Formatos de salida

La CLI admite varios formatos de salida. Muy útil para scripting o para ver los datos mejor.

## 8.1 Tabla (por defecto)

```bat
rem Muestra la salida en formato tabla legible para humanos.
rem Es el formato por defecto si no especificas nada.
openstack service list -f table
```

## 8.2 Solo valores (para scripting)

```bat
rem Devuelve solo los valores, sin cabeceras ni bordes de tabla.
rem Ideal para usar la salida en scripts o capturar IDs.
openstack token issue -f value -c id
```

## 8.3 JSON

```bat
rem Devuelve la salida en formato JSON.
rem Útil para procesar con herramientas como jq o para debug detallado.
openstack service list -f json
```

## 8.4 YAML

```bat
rem Devuelve la salida en formato YAML.
rem Similar a JSON pero más legible para humanos.
openstack service list -f yaml
```

## 8.5 Filtrar columnas

```bat
rem Muestra solo las columnas que te interesan.
rem Puedes combinar "-c" varias veces para mostrar múltiples columnas.
openstack endpoint list -c "Service Name" -c "Interface" -c "URL"
```

---

# 9. Práctica guiada — exploración del cloud

Sigue estos pasos en orden. Al final deberías tener una visión clara de qué hay en el cloud.

### Paso 1 — Cargar entorno y verificar

```bat
rem Carga tus credenciales.
call alumno1-openrc.cmd
```

```bat
rem Verifica que las variables están cargadas.
set OS_
```

```bat
rem Comprueba que puedes autenticarte.
openstack token issue
```

### Paso 2 — ¿En qué región estoy?

```bat
rem Comprueba la región activa.
set OS_REGION_NAME
```

```bat
rem Lista todas las regiones del cloud.
openstack region list
```

### Paso 3 — ¿Qué servicios hay?

```bat
rem Lista los servicios disponibles.
openstack service list
```

```bat
rem Lista el catálogo completo con sus endpoints públicos.
openstack catalog list
```

### Paso 4 — ¿Dónde viven las APIs?

```bat
rem Lista todos los endpoints con URL.
openstack endpoint list -c "Service Name" -c Interface -c URL
```

### Paso 5 — ¿Quién soy yo en este cloud?

```bat
rem Obtén tu user_id.
openstack token issue -f value -c user_id
```

```bat
rem Comprueba tus proyectos visibles.
openstack project list
```

```bat
rem Comprueba los dominios que puedes ver.
openstack domain list
```

---

# 10. Errores comunes

| Error | Causa probable | Solución |
|-------|---------------|----------|
| `HTTP 401 Unauthorized` | Credenciales incorrectas o expiradas | Verifica `OS_USERNAME`, `OS_PASSWORD` o recarga el openrc |
| `HTTP 403 Forbidden` | Sin permisos para esa operación | Comprueba qué rol tienes en el proyecto activo |
| `Unable to establish connection` | URL de Keystone incorrecta o sin red | Verifica `OS_AUTH_URL` y conectividad |
| `Missing value auth-url` | No se cargó el openrc | Ejecuta `call openrc.cmd` o `set OS_CLOUD=nombre` |
| `The resource could not be found` | El ID o nombre no existe | Verifica con `list` que el recurso existe |
| `SSL certificate verify failed` | Certificado autofirmado | Añade `--insecure` o configura `cacert` |

---

# 11. Referencia rápida

```bat
rem === AUTENTICACIÓN ===
call alumno1-openrc.cmd          rem carga credenciales
openstack token issue            rem verifica autenticación
set OS_                          rem muestra variables activas

rem === IDENTIDAD ===
openstack user show <id>         rem detalles de usuario
openstack project list           rem proyectos visibles
openstack domain list            rem dominios visibles
openstack region list            rem regiones del cloud

rem === SERVICIOS ===
openstack service list           rem servicios registrados
openstack catalog list           rem catálogo con endpoints
openstack endpoint list          rem todos los endpoints

rem === AYUDA ===
openstack help                   rem lista de comandos
openstack help <comando>         rem ayuda de un comando
openstack <comando> --help       rem alternativa

rem === FORMATOS ===
openstack ... -f table           rem tabla (por defecto)
openstack ... -f value -c campo  rem solo el valor de una columna
openstack ... -f json            rem JSON
openstack ... -f yaml            rem YAML
```