# Prácticas de Keystone — Laboratorio guiado

## Objetivo

En estas prácticas vas a:

- autenticarte contra OpenStack
- entender dominios, proyectos, usuarios y roles
- trabajar con la CLI de Keystone
- comprobar la diferencia entre autenticación y autorización
- jugar con tu propio proyecto sin tocar el de otros compañeros

## Tu contexto en este laboratorio

Cada alumno tiene:

- un **dominio** propio (por ejemplo `dominio-alumno1`)
- un proyecto dentro de su dominio (por ejemplo `proyecto-alumno1`)
- un usuario dentro de su dominio
- rol `admin` **en su dominio** — puedes crear usuarios, proyectos y roles dentro de él
- sin permisos en otros dominios ni en la plataforma global

Eso significa que tu dominio es tu reino: puedes gestionarlo libremente sin pisar a otros compañeros.

> **¡Ojo!** Eres admin de tu dominio, no de la plataforma completa.
> Sin embargo, en algunas configuraciones de OpenStack (especialmente con policies
> clásicas o poco restrictivas), un admin de dominio podría tener más visibilidad
> o permisos de los esperados fuera de su dominio.
> En este lab comprobaremos qué ocurre en **nuestro** entorno real.

---

# 1. Preparación del entorno

> **Nota importante para Windows:** en `cmd.exe` los comandos multilínea con `\` no funcionan.
> Escribe siempre los comandos en una sola línea o copia directamente desde aquí.

## 1.1 Activar el entorno virtual (Windows)

Si lo instalaste en Windows con entorno virtual:

```bat
rem Activa el entorno virtual donde instalaste python-openstackclient.
rem Mientras esté activo, el comando "openstack" estará disponible en este terminal.
%USERPROFILE%\openstack-client\Scripts\activate
```

## 1.2 Cargar tu contexto

Antes de poder usar la CLI tienes que decirle a qué cloud conectarte y con qué usuario.
Eso lo hace el archivo `openrc.cmd`: define variables de entorno que el cliente lee automáticamente.

Ejemplo para `alumno1`:

```bat
rem Carga las variables de entorno con tus credenciales.
rem "call" es necesario para que las variables queden activas en este terminal.
rem Sin "call", el fichero se ejecutaría en un subproceso y las variables se perderían.
call alumno1-openrc.cmd
```

## 1.3 Comprobar autenticación

```bat
rem Solicita a Keystone un token de acceso con tus credenciales actuales.
rem Si devuelve datos (id, expires, project_id...) es que la autenticación funciona.
rem Si devuelve error 401, tus credenciales son incorrectas o no has cargado el openrc.
openstack token issue
```

Si esto funciona, ya estás autenticado correctamente.

---

# 2. Tu primera inspección del cloud

Antes de entrar en las prácticas, vale la pena dar un vistazo general a lo que ofrece el cloud.
Estos comandos no modifican nada: solo leen. Son seguros de ejecutar en cualquier momento.

## 2.1 Ver catálogo de servicios

El catálogo es la lista de servicios que OpenStack pone a tu disposición y dónde viven sus APIs.
Es lo primero que Keystone devuelve cuando te autenticas.

```bat
rem Lista todos los servicios disponibles en el cloud y sus endpoints.
rem Cada entrada es un servicio (nova, glance, neutron...) con su URL de acceso.
rem En nuestro entorno verás principalmente keystone e image (glance).
openstack catalog list
```

## 2.2 Ver servicios

```bat
rem Lista los servicios registrados en Keystone por nombre y tipo.
rem El "tipo" identifica para qué sirve: identity, compute, image, network...
rem Un servicio sin endpoint no es accesible desde la CLI.
openstack service list
```

## 2.3 Ver endpoints

```bat
rem Lista todos los endpoints de cada servicio.
rem Un endpoint es la URL real donde está escuchando una API.
rem Cada servicio suele tener tres: public (exterior), internal (red interna) y admin.
openstack endpoint list
```

## 2.4 Ver tu token y contexto

```bat
rem Muestra información del token activo: qué usuario eres, en qué proyecto,
rem cuándo caduca y el identificador único del token.
rem útil para comprobar con qué identidad estás operando en cada momento.
openstack token issue
```

### Qué debes observar

* que el cloud tiene varios servicios
* que Keystone es la puerta de entrada
* que estás operando dentro de un contexto concreto
* que el proyecto importa

---

# 3. Dominios, proyectos, usuarios y roles

Antes de las prácticas interactivas, conviene entender bien la jerarquía de Keystone:

- Un **dominio** es el contenedor de más alto nivel. Agrupa usuarios y proyectos.
- Un **proyecto** (también llamado tenant) es donde viven los recursos: instancias, redes, volúmenes...
- Un **usuario** es una identidad que puede autenticarse.
- Un **rol** es una etiqueta que, combinada con una asignación, define qué puede hacer un usuario en un contexto.

## 3.1 Listar dominios

```bat
rem Lista todos los dominios que existen en el cloud.
rem Cada alumno tiene su propio dominio (dominio-alumno1, dominio-alumno2...).
rem El dominio "Default" es el que usa OpenStack internamente.
openstack domain list
```

## 3.2 Ver tu dominio

```bat
rem Muestra los detalles de tu dominio: nombre, id, si está activo y descripción.
rem El campo "enabled" indica si el dominio está operativo.
openstack domain show dominio-alumno1
```

> Cada alumno tiene su propio dominio. El dominio `Default` existe pero no es el tuyo.

## 3.3 Ver tu proyecto

Ejemplo para `alumno1`:

```bat
rem Muestra los detalles de tu proyecto: nombre, id, dominio al que pertenece,
rem descripción y si está habilitado.
rem Fíjate en el campo "domain_id": confirma que el proyecto vive en tu dominio.
openstack project show proyecto-alumno1
```

## 3.4 Ver tu usuario

```bat
rem Muestra los detalles de tu usuario: nombre, id, dominio al que pertenece
rem y si está habilitado.
rem Sin --domain, busca en todos los dominios; como los nombres son únicos per dominio,
rem es recomendable especificarlo siempre que puedas.
openstack user show alumno1
```

## 3.5 Listar roles

```bat
rem Lista todos los roles disponibles en el cloud.
rem Los roles estándar de OpenStack son: admin, member y reader.
rem Pueden existir roles personalizados que el administrador haya creado.
openstack role list
```

## 3.6 Ver tus asignaciones

```bat
rem Lista las asignaciones de rol de un usuario: qué rol tiene, en qué proyecto o dominio.
rem --names muestra nombres legibles en vez de UUIDs.
rem Una asignación sin scope (proyecto o dominio) no da permisos útiles.
openstack role assignment list --user alumno1 --names
```

### Qué debes entender aquí

* tu usuario no es "el cloud"
* tu proyecto es tu espacio de trabajo
* tu rol tiene sentido dentro de un scope concreto
* autenticación no es lo mismo que autorización

---

# 4. Práctica 1 — ¿Qué puede ver un alumno?

## Objetivo

Comprobar qué puedes ver como usuario de proyecto.

## Comandos

```bat
rem Solicita un nuevo token. Si funciona, la autenticación es correcta.
rem Devuelve: id del token, cuándo caduca, id de tu usuario e id de tu proyecto.
openstack token issue

rem Lista los proyectos que tu usuario puede ver.
rem Con permisos de admin de dominio, es posible que veas todos los proyectos del cloud.
rem Con permisos más restrictivos, solo verías los tuyos.
openstack project list

rem Lista los usuarios que tu usuario puede ver.
rem Igual que con proyectos: el alcance depende de las policies del entorno.
openstack user list

rem Muestra en qué proyectos o dominios tienes rol asignado y cuál es ese rol.
rem --names muestra nombres legibles en vez de UUIDs.
openstack role assignment list --user alumno1 --names
```

## Preguntas

1. ¿Puedes autenticarte?
2. ¿Puedes ver tu proyecto?
3. ¿Puedes listar todos los usuarios del sistema? (¿te sorprende?)
4. ¿Tienes permisos globales o solo en tu proyecto?
5. ¿Puedes ver los proyectos de otros compañeros?

> **Reflexión:** si puedes listar usuarios y proyectos ajenos, ¿significa que puedes modificarlos?
> Pruébalo después de la Práctica 2.

---

# 5. Práctica 2 — Crear un proyecto secreto

## Objetivo

Crear un segundo proyecto propio para experimentar.

> Esta práctica está pensada para que veas qué operaciones puedes hacer dentro de tu dominio.

## Comando

```bat
rem Crea un nuevo proyecto llamado "operacion-croqueta".
rem --domain dominio-alumno1: lo crea DENTRO de tu dominio, no en el Default ni globalmente.
rem --description: texto descriptivo, opcional pero recomendable.
rem El nombre del proyecto tiene que ser único dentro del dominio.
openstack project create --domain dominio-alumno1 --description "Operacion ultrasecreta de croquetas" operacion-croqueta
```

## Verificar

```bat
rem Muestra los detalles del proyecto recén creado: id, nombre, dominio, enabled...
rem Fíjate en "domain_id": debe coincidir con el id de tu dominio.
openstack project show operacion-croqueta

rem Lista todos los proyectos visibles para tu usuario.
rem Deberías ver al menos: proyecto-alumno1 y operacion-croqueta.
openstack project list
```

## Preguntas

1. ¿Te deja crear un proyecto?
2. ¿Dónde se crea: en tu dominio o globalmente?
3. ¿Qué diferencias habría entre esto y ser admin de toda la nube?

> En algunas configuraciones de OpenStack, especialmente con policies clásicas,
> un admin de dominio puede crear proyectos libremente. En otras configuraciones
> más restrictivas, esto podría fallar.
>
> **Intenta ejecutar el comando y observa qué ocurre en tu entorno.**
> Si funciona, anota dónde se crea. Si falla, analiza el error.

---

# 6. Práctica 3 — Crear un usuario ayudante

## Objetivo

Crear un usuario secundario para tu proyecto.

Vamos a crear a `pancracio`, tu fiel ayudante.

## Comando

```bat
rem Crea un nuevo usuario llamado "pancracio" dentro de tu dominio.
rem --domain dominio-alumno1: el usuario pertenece a ese dominio, no al Default.
rem Esto es importante: el mismo nombre en dominios distintos son usuarios DISTINTOS.
rem --password: su contraseña de acceso. Usa una contraseña real aquí.
openstack user create --domain dominio-alumno1 --password '<Escribe aqui tu password>' pancracio
```

## Verificar

```bat
rem Muestra los detalles del usuario: id, nombre, dominio al que pertenece, si está activo.
rem --domain es obligatorio cuando existen usuarios con el mismo nombre en distintos dominios.
openstack user show pancracio --domain dominio-alumno1
```

## Preguntas

1. ¿Te deja crear usuarios?
2. Si no te deja, ¿qué te está enseñando eso sobre permisos?
3. ¿Qué diferencia hay entre existir como usuario y tener permisos reales?

> Si el comando funciona, `pancracio` ya existe como identidad en Keystone dentro de tu dominio,
> pero todavía no tiene permisos útiles en ningún proyecto. Es decir: existe, pero aún no puede
> hacer casi nada interesante.
>
> Como lo has creado en `dominio-alumno1`, ningún otro alumno lo ve ni puede colisionar con él.

---

# 7. Práctica 4 — Dar permisos a tu ayudante

## Objetivo

Asignar a `pancracio` el rol `admin` dentro de tu proyecto.

## Comando

```bat
rem Asigna el rol "admin" a pancracio, con scope en proyecto-alumno1.
rem --user: el usuario al que se asigna el rol.
rem --user-domain: en qué dominio vive ese usuario (necesario para identificarlo).
rem --project: el proyecto donde se aplica el rol.
rem --project-domain: en qué dominio vive ese proyecto.
rem Sin scope (proyecto o dominio), el role add fallaría: hay que decirle dónde aplica.
openstack role add --user pancracio --user-domain dominio-alumno1 --project proyecto-alumno1 --project-domain dominio-alumno1 admin
```

## Verificar

```bat
rem Lista las asignaciones de rol de pancracio.
rem Deberías ver: rol admin, en proyecto-alumno1 del dominio dominio-alumno1.
rem Si no aparece nada, la asignación no se realizó correctamente.
openstack role assignment list --user pancracio --user-domain dominio-alumno1 --names
```

## Preguntas

1. ¿El rol se asigna "en abstracto" o en un proyecto?
2. ¿Qué significa realmente "ser admin" aquí?
3. ¿pancracio puede administrar todo OpenStack o solo tu proyecto?

---

# 8. Práctica 5 — Comprobar autenticación con pancracio

## Objetivo

Probar el acceso de pancracio, tu ayudante recién empoderado.

## Crear un openrc rápido

En vez de cargar un fichero, definimos las variables directamente.
Esto es equivalente a lo que hace `call alumno1-openrc.cmd` pero para pancracio.

```bat
rem URL del endpoint de autenticación de Keystone.
set OS_AUTH_URL=https://keystone.ivanosuna.com/v3

rem Versión de la API de identidad que usamos.
set OS_IDENTITY_API_VERSION=3

rem El usuario con el que nos autenticamos.
set OS_USERNAME=pancracio

rem Su contraseña.
set OS_PASSWORD=<Escribe aqui tu password>

rem El proyecto donde quiere operar pancracio.
set OS_PROJECT_NAME=proyecto-alumno1

rem Dominio donde vive el usuario pancracio.
rem Sin este dato, Keystone no sabe en qué dominio buscar al usuario.
set OS_USER_DOMAIN_NAME=dominio-alumno1

rem Dominio donde vive el proyecto.
set OS_PROJECT_DOMAIN_NAME=dominio-alumno1
```

> Fíjate: tanto el usuario como el proyecto viven en `dominio-alumno1`, no en `Default`.

## Probar

```bat
rem Comprueba que pancracio puede autenticarse y obtener un token.
rem Si funciona, verás los datos del token incluyendo el project_id de proyecto-alumno1.
openstack token issue

rem Intenta mostrar los detalles del proyecto donde pancracio tiene rol.
rem Debería funcionar porque tiene rol admin en ese proyecto.
openstack project show proyecto-alumno1
```

## Preguntas

1. ¿pancracio se autentica?
2. ¿Puede operar dentro del proyecto?
3. ¿Podría operar fuera de tu dominio? (pruébalo)

---

# 9. Práctica 6 — El detective de Keystone

## Objetivo

Resolver pequeñas preguntas usando solo CLI.

## Reto A

Averigua:

* en qué dominio vive tu usuario
* cuál es el nombre exacto de tu proyecto
* qué rol tienes asignado
* si tu usuario tiene permisos de sistema

## Pistas

```bat
rem Muestra los detalles de tu usuario, incluyendo el campo "domain_id".
rem Ese id es el identificador de tu dominio. Puedes cruzarlo con "openstack domain show".
openstack user show alumno1

rem Muestra los detalles de tu proyecto, incluyendo "domain_id" y "id".
rem Confirma que el proyecto pertenece a tu dominio, no al Default.
openstack project show proyecto-alumno1

rem Lista tus asignaciones de rol con nombres legibles.
rem Muestra en qué proyectos o dominios tienes rol y cuál es ese rol.
openstack role assignment list --user alumno1 --names

rem Muestra el token activo: a qué usuario y proyecto corresponde.
rem El campo "project_id" confirma en qué contexto estás operando ahora mismo.
openstack token issue
```

## Reto B

Intenta responder:

* ¿por qué un usuario puede autenticarse y aun así no poder hacer ciertas operaciones?
* ¿qué diferencia hay entre rol y asignación de rol?
* ¿por qué proyecto y dominio no son lo mismo?

---

# 10. Práctica 7 — Comparar roles: admin vs member vs reader

## Objetivo

Entender que no todos los roles son iguales. OpenStack tiene tres roles estándar:

| Rol | Puede hacer |
|---|---|
| `admin` | Todo (en su scope, y con la policy clásica, a veces más de la cuenta) |
| `member` | Operar con recursos (crear instancias, redes...) pero no gestionar identidad |
| `reader` | Solo lectura |

## Pasos

### 10.1 Crear un usuario con rol `member`

Vamos a crear a `menchu`, que solo será miembro del proyecto.
`member` puede operar con recursos (instancias, redes, volúmenes...) pero no gestionar identidad.

```bat
rem Crea a menchu en tu dominio.
openstack user create --domain dominio-alumno1 --password "<Escribe aqui tu password>" menchu

rem Asigna el rol "member" a menchu en tu proyecto.
rem member es menos poderoso que admin: puede operar recursos pero no crear usuarios ni proyectos.
rem Observa que hay que indicar siempre el dominio tanto del usuario como del proyecto.
openstack role add --user menchu --user-domain dominio-alumno1 --project proyecto-alumno1 --project-domain dominio-alumno1 member
```

### 10.2 Autenticarse como `menchu`

Reutilizamos el mismo contexto de shell y solo cambiamos usuario y contraseña.
El resto de variables (`OS_AUTH_URL`, `OS_PROJECT_NAME`, etc.) ya están definidas.

```bat
rem Cambiar de usuario es tan simple como sobreescribir estas variables.
rem No hace falta cerrar y abrir el terminal.
set OS_USERNAME=menchu
set OS_PASSWORD=<Escribe aqui tu password>
set OS_PROJECT_NAME=proyecto-alumno1
set OS_USER_DOMAIN_NAME=dominio-alumno1
set OS_PROJECT_DOMAIN_NAME=dominio-alumno1
```

### 10.3 Probar qué puede hacer

```bat
rem Comprueba que menchu puede autenticarse.
openstack token issue

rem Intenta listar proyectos. ¿Puede verlos todos o solo el suyo?
rem Con rol member, OpenStack puede restringir esto.
openstack project list

rem Intenta listar usuarios. Con member, normalmente esto falla con 403.
rem Eso es lo esperado: member no tiene permisos de gestión de identidad.
openstack user list
```

### 10.4 Crear un usuario con rol `reader`

Vuelve a tu usuario original primero:

```bat
call alumno1-openrc.cmd
```

Ahora crea a `eustaquio`, que solo podrá mirar.

```bat
rem Crea a eustaquio en tu dominio.
openstack user create --domain dominio-alumno1 --password "<Escribe aqui tu password>" eustaquio

rem Asigna el rol "reader" a eustaquio en tu proyecto.
rem reader es el más restrictivo: solo puede leer, nunca modificar ni crear.
rem Es útil para dar acceso a auditores o personas que necesitan ver pero no tocar.
openstack role add --user eustaquio --user-domain dominio-alumno1 --project proyecto-alumno1 --project-domain dominio-alumno1 reader
```

### 10.5 Autenticarse como `eustaquio` y probar

```bat
set OS_USERNAME=eustaquio
set OS_PASSWORD=<Escribe aqui tu password>
set OS_PROJECT_NAME=proyecto-alumno1
set OS_USER_DOMAIN_NAME=dominio-alumno1
set OS_PROJECT_DOMAIN_NAME=dominio-alumno1

rem Comprueba que eustaquio puede autenticarse.
openstack token issue

rem Intenta listar proyectos. Con reader, puede que solo vea los suyos.
openstack project list

rem Intenta listar usuarios. Con reader, lo más probable es un error 403.
openstack user list
```

## Preguntas

1. ¿Qué comandos le funcionan a menchu y cuáles no?
2. ¿Y a eustaquio?
3. ¿En qué se diferencia `member` de `admin`?
4. ¿Tiene sentido que eustaquio no pueda listar proyectos?
5. ¿Por qué pancracio (admin) puede hacer más que los otros dos?

### Limpieza

Vuelve a tu usuario y borra:

```bat
rem Recupera tu contexto original. Esto es importante antes de borrar.
call alumno1-openrc.cmd

rem Borra los usuarios creados en esta práctica.
rem --domain es necesario para identificar al usuario dentro del dominio correcto.
openstack user delete menchu --domain dominio-alumno1
openstack user delete eustaquio --domain dominio-alumno1
```

---

# 11. Práctica 8 — Crear un rol personalizado

## Objetivo

Entender que los roles en OpenStack son simples etiquetas. Crearlos es trivial,
pero **sin unas policies que los reconozcan, no sirven de nada**.

## Pasos

### 11.1 Crear el rol

En OpenStack, crear un rol es simplemente darle un nombre. No define permisos — eso lo hacen las **policies**.

```bat
rem Crea un rol nuevo llamado "ayudante-junior".
rem Esto solo registra el nombre en Keystone. No tiene ningún permiso asociado todavía.
openstack role create ayudante-junior
```

### 11.2 Crear un usuario y asignarle ese rol

```bat
rem Crea a pepito en tu dominio.
openstack user create --domain dominio-alumno1 --password "<Escribe aqui tu password>" pepito

rem Asigna el rol ayudante-junior a pepito en tu proyecto.
rem La asignación existe, pero como las policies no conocen este rol,
rem pepito no podrá hacer nada útil aunque se autentique correctamente.
openstack role add --user pepito --user-domain dominio-alumno1 --project proyecto-alumno1 --project-domain dominio-alumno1 ayudante-junior
```

### 11.3 Verificar la asignación

```bat
rem Comprueba que la asignación existe.
rem Verás: rol ayudante-junior / usuario pepito / proyecto proyecto-alumno1.
openstack role assignment list --user pepito --user-domain dominio-alumno1 --names
```

### 11.4 Autenticarse como pepito y probar

```bat
set OS_USERNAME=pepito
set OS_PASSWORD=<Escribe aqui tu password>
set OS_USER_DOMAIN_NAME=dominio-alumno1
set OS_PROJECT_DOMAIN_NAME=dominio-alumno1
set OS_PROJECT_NAME=proyecto-alumno1

rem Pepito puede obtener un token: la autenticación funciona.
rem Un token válido solo prueba que la contraseña es correcta, no que tenga permisos.
openstack token issue

rem Intenta listar proyectos. Recibirás un error 403 (Forbidden).
rem 403 significa: te identifiqué correctamente, pero no tienes permiso para esto.
openstack project list

rem Mismo resultado: 403. Las policies no asignan ningún permiso a ayudante-junior.
openstack user list
```

## Qué debes observar

Pepito **puede autenticarse** (tiene token válido), pero **no puede hacer nada**:
recibirá errores 403 en todos los comandos que requieren permisos.

Eso es porque el rol `ayudante-junior` existe como etiqueta, pero las **policies**
de Keystone no saben qué acciones le corresponden. Un rol sin policy es decorativo.

## Preguntas

1. ¿Pepito puede autenticarse?
2. ¿Puede listar proyectos o usuarios?
3. ¿Qué diferencia habría si existiera una policy que dijera `ayudante-junior` puede hacer X?
4. ¿En qué se diferencia esto de `member`, que sí tiene policies definidas?

### Limpieza

```bat
rem Vuelve a tu contexto original antes de borrar.
call alumno1-openrc.cmd

rem Borra el usuario pepito. Primero el usuario, luego el rol (no al revés).
openstack user delete pepito --domain dominio-alumno1

rem Borra el rol personalizado. Solo es posible si ningún usuario tiene ese rol asignado.
rem Si pepito todavía existiera con ese rol asignado, este comando fallaría.
openstack role delete ayudante-junior
```

---

# 12. Práctica 9 — Formatos de salida de la CLI

## Objetivo

Aprender a extraer información en diferentes formatos. Muy útil para scripting.

## Formatos disponibles

Todos los comandos `openstack` aceptan `-f <formato>` para cambiar cómo se muestra la salida.

```bat
rem Formato por defecto: tabla bonita, fácil de leer pero difícil de parsear.
openstack token issue -f table

rem JSON: ideal para procesar con jq, Python, scripts... Muy usado en automatización.
openstack token issue -f json

rem YAML: alternativa legible a JSON, usado por herramientas como Ansible.
openstack token issue -f yaml

rem value: imprime solo los valores, sin cabeceras ni bordes. Útil en bash con variables.
openstack token issue -f value

rem -c filtra qué columna quieres ver. Muy útil para extraer un dato concreto.
openstack token issue -f value -c user_id

rem Puedes combinar varios -c para extraer múltiples columnas.
openstack token issue -f value -c project_id -c user_id
```

## Para listados

```bat
rem Lista usuarios en formato JSON. Útil para pasarlo a un script o guardar en fichero.
openstack user list -f json

rem Lista roles en formato CSV. Compatible con Excel y cualquier herramienta de hojas de cálculo.
openstack role list -f csv

rem Lista proyectos devolviendo solo el valor de la columna "Name", uno por línea.
rem Muy útil en bash: for proyecto in $(openstack project list -f value -c Name)
openstack project list -f value -c Name
```

## Preguntas

1. ¿Qué formato usarías en un script de bash?
2. ¿Y para pasarle datos a otra herramienta?
3. ¿Para qué sirve `-c`?

---

# 13. Práctica 10 — Limpieza general

## Objetivo

Dejar tu entorno limpio después de las prácticas.

## Pasos

Vuelve a tu usuario original:

```bat
rem Recarga tu contexto original. Esto sobreescribe cualquier OS_USERNAME o OS_PASSWORD
rem que hayas definido manualmente durante las prácticas anteriores.
call alumno1-openrc.cmd
```

Borra lo que hayas creado durante el lab:

```bat
rem Borra al usuario pancracio de tu dominio.
rem Si ya lo borraste en la Práctica 3, este comando dará error. Es normal.
openstack user delete pancracio --domain dominio-alumno1

rem Borra el proyecto temporal que creaste.
openstack project delete operacion-croqueta --domain dominio-alumno1
```

> Algunos comandos pueden dar error si no llegaste a crear esos recursos. Es normal.

## Verificar

```bat
rem Comprueba que tus asignaciones de rol siguen siendo las correctas.
openstack role assignment list --user alumno1 --names

rem Comprueba que solo quedan tus proyectos originales.
openstack project list
```

---

# 14. Chuletario rápido de Keystone

> **Nota:** Los comandos de esta sección son ejemplos de referencia.
> Si los ejecutas, recuerda borrar después lo que crees (ver sección 18).

## Autenticación y catálogo

```bat
rem Obtén un token válido con tus credenciales actuales.
openstack token issue

rem Muestra los servicios disponibles y sus endpoints (URLs de acceso).
openstack catalog list

rem Lista los servicios registrados en Keystone con su tipo.
openstack service list

rem Lista todos los endpoints configurados para cada servicio.
openstack endpoint list
```

## Dominios

```bat
rem Lista todos los dominios del cloud.
openstack domain list

rem Muestra los detalles de tu dominio.
openstack domain show dominio-alumno1
```

## Proyectos

```bat
rem Lista los proyectos visibles para tu usuario.
openstack project list

rem Muestra detalles de tu proyecto principal.
openstack project show proyecto-alumno1

rem Crea un proyecto nuevo dentro de tu dominio.
openstack project create --domain dominio-alumno1 proyecto-bichitos
```

## Usuarios

```bat
rem Lista los usuarios visibles para tu usuario.
openstack user list

rem Muestra los detalles de tu propio usuario.
openstack user show alumno1

rem Crea un nuevo usuario dentro de tu dominio.
openstack user create --domain dominio-alumno1 --password '<Escribe aqui tu password>' sinforoso
```

## Roles

```bat
rem Lista todos los roles disponibles en el cloud.
openstack role list

rem Muestra los detalles de un rol concreto.
openstack role show admin

rem Asigna un rol a un usuario en un proyecto concreto.
openstack role add --user sinforoso --user-domain dominio-alumno1 --project proyecto-bichitos --project-domain dominio-alumno1 admin

rem Retira ese rol (operación inversa a role add, mismos parámetros).
openstack role remove --user sinforoso --user-domain dominio-alumno1 --project proyecto-bichitos --project-domain dominio-alumno1 admin

rem Lista todas las asignaciones de rol del cloud (con nombres legibles).
openstack role assignment list --names
```

---

# 15. Cosas importantes que debes recordar

* autenticación no es autorización
* un usuario no es un permiso
* un rol sin asignación no sirve de nada
* el dominio es tu espacio aislado: lo que creas allí no interfiere con otros alumnos
* el proyecto es el contexto operativo habitual dentro de un dominio
* `admin` en tu dominio **conceptualmente** no significa admin global
* **pero** según las políticas reales del entorno, podrías tener más visibilidad o permisos de los esperados
* Keystone no es solo login: también es catálogo, contexto y autorización

---

# 16. Errores típicos

## Error 1 — No cargar bien tu `openrc.cmd`

Si al ejecutar `openstack token issue` ves un error 401, casi seguro no has cargado el openrc.

```bat
call alumno1-openrc.cmd
```

Recuerda: cada vez que abres una consola nueva, hay que volver a cargarlo.

## Error 2 — Usar mal el proyecto

Si tu `OS_PROJECT_NAME` no coincide exactamente, la autenticación fallará.
Comprueba con:

```bat
echo %OS_PROJECT_NAME%
```

## Error 3 — Confundir dominio y proyecto

El dominio agrupa proyectos y usuarios. El proyecto es donde viven tus recursos.
No son intercambiables. Tu dominio `dominio-alumno1` contiene tu proyecto `proyecto-alumno1`.

## Error 4 — "Puedo entrar" no significa "puedo hacer cualquier cosa"

Autenticarse (token) no te da permisos automáticamente. Sin un rol asignado en un proyecto, no puedes hacer nada útil.

## Error 5 — Pensar que el nombre del rol lo es todo

El rol `admin` en `dominio-alumno1` NO es lo mismo que `admin` global.
El scope (dónde se asigna) es lo que importa.

## Error 6 — Olvidar que `\` para multilínea no funciona en `cmd.exe`

En Windows, los comandos multilínea con `\` no funcionan. Escribe todo en una línea:

```bat
openstack project create --domain dominio-alumno1 --description "Proyecto de bichos raros" proyecto-bichitos
```

---

# 17. Mini misión final

## Misión

Imagina que eres el administrador de tu pequeño reino dentro de OpenStack.

Tu misión es:

1. comprobar quién eres
2. comprobar en qué proyecto mandas
3. crear a `remedios`, tu nueva ayudante (**dentro de tu dominio**)
4. darle permisos de `member` dentro de tu proyecto
5. demostrar que remedios puede autenticarse pero no crear proyectos nuevos
6. darle rol `admin` y comprobar cómo cambia lo que puede hacer
7. borrar a remedios cuando termines

> Recuerda: todos los recursos viven en tu dominio `dominio-alumnoX`.
> Usa `--domain` en los comandos de creación y borrado.

## Resultado esperado

Si entiendes esta misión y puedes explicar por qué remedios con `member` no puede lo mismo que con `admin`, ya estás entendiendo muy bien Keystone.

---

# 18. Limpieza final completa

Si quieres dejar tu dominio exactamente como estaba al empezar, ejecuta estos comandos.
Algunos darán error si no creaste esos recursos — es normal, ignóralos.

```bat
rem Carga tu contexto original antes de hacer nada.
call alumno1-openrc.cmd
```

## Borrar usuarios creados durante el lab

```bat
rem Borra todos los usuarios que pudiste haber creado durante las prácticas.
rem Si alguno no existe, el comando da error pero los demás se ejecutan igualmente.
openstack user delete pancracio --domain dominio-alumno1
openstack user delete menchu --domain dominio-alumno1
openstack user delete eustaquio --domain dominio-alumno1
openstack user delete remedios --domain dominio-alumno1
openstack user delete sinforoso --domain dominio-alumno1
openstack user delete pepito --domain dominio-alumno1
```

## Borrar proyectos creados durante el lab

```bat
rem Borra los proyectos temporales creados en las prácticas.
rem No puedes borrar proyecto-alumno1: es tu proyecto principal y fue creado por el admin.
openstack project delete operacion-croqueta --domain dominio-alumno1
openstack project delete proyecto-bichitos --domain dominio-alumno1
```

## Borrar roles personalizados creados durante el lab

```bat
rem Borra el rol personalizado que creaste.
rem Un rol solo puede borrarse si ya no tiene ninguna asignación activa.
rem Por eso hay que borrar primero los usuarios que lo tenían asignado.
openstack role delete ayudante-junior
```

## Verificar que solo queda tu proyecto original

```bat
rem Deberías ver solo proyecto-alumno1.
openstack project list --domain dominio-alumno1 -f table

rem Deberías ver solo alumno1.
openstack user list --domain dominio-alumno1 -f table
```

Deberías ver solo:
- Proyecto: `proyecto-alumno1`
- Usuario: `alumno1`

> Si ves más recursos, revísalos y decide si quieres borrarlos.
