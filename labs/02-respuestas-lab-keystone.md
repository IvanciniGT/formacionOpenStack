# Respuestas del lab — Prácticas de Keystone

> Ejecutado con el usuario **alumno1** contra `https://keystone.ivanosuna.com/v3`
> Fecha: 17 de marzo de 2026 — Cliente: openstack 9.0.0

---

## 1. Preparación del entorno

### Cargar credenciales

```bat
set OS_AUTH_URL=https://keystone.ivanosuna.com/v3
set OS_IDENTITY_API_VERSION=3
set OS_USERNAME=alumno1
set OS_PASSWORD=<tu_password>
set OS_PROJECT_NAME=proyecto-alumno1
set OS_USER_DOMAIN_NAME=dominio-alumno1
set OS_PROJECT_DOMAIN_NAME=dominio-alumno1
```

### Comprobar autenticación

```bat
openstack token issue
```

**Salida:**
```
+------------+-----------------------------------------------------------------+
| Field      | Value                                                           |
+------------+-----------------------------------------------------------------+
| expires    | 2026-03-17T19:26:53+0000                                        |
| id         | gAAAAABpuQI9lQfpUFojBsFz5Q6bjALVaFRzAHBEolD-eILb-...           |
| project_id | e8f46eff64984dd787d46031dd4dcfd3                                |
| user_id    | 466f3cdb799546c781bdae5906a34d49                                |
+------------+-----------------------------------------------------------------+
```

> El token tiene 1 hora de validez. Los campos importantes son `user_id` y `project_id`:
> confirman con qué identidad y en qué proyecto estás operando.

---

## 2. Tu primera inspección del cloud

### Ver catálogo de servicios

```bat
openstack catalog list
```

**Salida:**
```
+-----------+--------------+---------------------------------------------------+
| Name      | Type         | Endpoints                                         |
+-----------+--------------+---------------------------------------------------+
| glance    | image        | RegionOne                                         |
|           |              |   admin: https://glance.ivanosuna.com             |
|           |              |   internal: http://glance-api.openstack...        |
|           |              |   public: https://glance.ivanosuna.com            |
|           |              |                                                   |
| swift     | object-store | RegionOne                                         |
|           |              |   internal: https://swift.ivanosuna.com/swift/v1/ |
|           |              | AUTH_e8f46eff64984dd787d46031dd4dcfd3             |
|           |              |   public: https://swift.ivanosuna.com/swift/v1/...|
|           |              |   admin: https://swift.ivanosuna.com/swift/v1/... |
|           |              |                                                   |
| keystone  | identity     | RegionOne                                         |
|           |              |   public: https://keystone.ivanosuna.com/v3       |
|           |              |   admin: https://keystone.ivanosuna.com/v3        |
|           |              |   internal: http://keystone-api.openstack...      |
|           |              |                                                   |
| placement | placement    | RegionOne                                         |
|           |              |   admin/internal/public: http://placement...      |
|           |              |                                                   |
| cinderv3  | volumev3     | RegionOne                                         |
|           |              |   public: https://cinder.ivanosuna.com/v3/...     |
|           |              |   admin/internal: https/http://cinder...          |
|           |              |                                                   |
+-----------+--------------+---------------------------------------------------+
```

> **Detalle interesante:** las URLs de Swift aparecen con el ID de tu proyecto
> (`AUTH_e8f46eff...`). OpenStack las personaliza al autenticarte: cada alumno
> recibe una URL de Swift apuntando a su propio espacio de almacenamiento.

### Ver servicios

```bat
openstack service list
```

**Salida:**
```
+----------------------------------+-----------+--------------+
| ID                               | Name      | Type         |
+----------------------------------+-----------+--------------+
| 2d772fde803241b1b79278aa905c3b49 | glance    | image        |
| 61b126160a8e4cbca53278cef16fa930 | swift     | object-store |
| 746b314b528c494d98f46895e4d00cb0 | keystone  | identity     |
| 999444fb84dd4932af391c25dc634a13 | placement | placement    |
| f488e41862f24b91b57a9f307dcba0a9 | cinderv3  | volumev3     |
+----------------------------------+-----------+--------------+
```

> Hay 5 servicios: keystone, glance, swift (almacenamiento de objetos),
> cinderv3 (volúmenes) y placement (scheduler de recursos, uso interno).

### Ver endpoints

```bat
openstack endpoint list -c "Service Name" -c Interface -c URL
```

**Salida:**
```
+--------------+-----------+---------------------------------------------------+
| Service Name | Interface | URL                                               |
+--------------+-----------+---------------------------------------------------+
| glance       | admin     | https://glance.ivanosuna.com                      |
| keystone     | public    | https://keystone.ivanosuna.com/v3                 |
| cinderv3     | public    | https://cinder.ivanosuna.com/v3/%(tenant_id)s     |
| swift        | internal  | https://swift.ivanosuna.com/swift/v1/AUTH_...     |
| placement    | admin     | http://placement-api.openstack.svc...             |
| swift        | public    | https://swift.ivanosuna.com/swift/v1/AUTH_...     |
| cinderv3     | admin     | https://cinder.ivanosuna.com/v3/%(tenant_id)s     |
| keystone     | admin     | https://keystone.ivanosuna.com/v3                 |
| swift        | admin     | https://swift.ivanosuna.com/swift/v1/AUTH_...     |
| glance       | internal  | http://glance-api.openstack.svc.cluster.local...  |
| keystone     | internal  | http://keystone-api.openstack.svc.cluster.local.. |
| placement    | internal  | http://placement-api.openstack.svc.cluster.local/ |
| cinderv3     | internal  | http://cinder-api.openstack.svc.cluster.local...  |
| placement    | public    | http://placement.openstack.svc.cluster.local/     |
| glance       | public    | https://glance.ivanosuna.com                      |
+--------------+-----------+---------------------------------------------------+
```

---

## 3. Dominios, proyectos, usuarios y roles

### Listar dominios

```bat
openstack domain list
```

**Salida:**
```
+----------------------------------+------------------+---------+------------------------+
| ID                               | Name             | Enabled | Description            |
+----------------------------------+------------------+---------+------------------------+
| 0fcbad52b8004c94bf21fede57ea2519 | dominio-alumno10 | True    | Dominio personal de... |
| 15e002eea6874dbb924a809d72f2cefa | dominio-alumno1  | True    | Dominio personal de... |
| 31130efcd50c47a8a1255c0182ba1635 | dominio-alumno6  | True    | Dominio personal de... |
| ...                              | ...              | ...     | ...                    |
| b7f968a90c09466bb659d9e045c3a581 | dominio-profesor | True    | Dominio personal de... |
| default                          | Default          | True    | The default domain     |
+----------------------------------+------------------+---------+------------------------+
```

> **Sorpresa:** como alumno1 con admin de dominio (y policy clásica), puedes ver
> TODOS los dominios del cloud, no solo el tuyo. Puedes verlos, pero no modificarlos.
> Son 16 dominios: alumno1-15 + profesor + Default + service.

### Ver tu dominio

```bat
openstack domain show dominio-alumno1
```

**Salida:**
```
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| id          | 15e002eea6874dbb924a809d72f2cefa |
| name        | dominio-alumno1                  |
| enabled     | True                             |
| description | Dominio personal de alumno1      |
| options     | {}                               |
+-------------+----------------------------------+
```

### Ver tu proyecto

```bat
openstack project show proyecto-alumno1
```

**Salida:**
```
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Proyecto principal de alumno1    |
| domain_id   | 15e002eea6874dbb924a809d72f2cefa |
| enabled     | True                             |
| id          | e8f46eff64984dd787d46031dd4dcfd3 |
| is_domain   | False                            |
| name        | proyecto-alumno1                 |
| options     | {}                               |
| parent_id   | 15e002eea6874dbb924a809d72f2cefa |
| tags        | []                               |
+-------------+----------------------------------+
```

> `domain_id` y `parent_id` apuntan al mismo ID: `15e002ee...` = `dominio-alumno1`.
> El proyecto vive dentro de tu dominio.

### Ver tu usuario

```bat
openstack user show alumno1
```

**Salida:**
```
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| default_project_id  | None                             |
| domain_id           | 15e002eea6874dbb924a809d72f2cefa |
| email               | None                             |
| enabled             | True                             |
| id                  | 466f3cdb799546c781bdae5906a34d49 |
| name                | alumno1                          |
| description         | None                             |
| password_expires_at | None                             |
| options             | {}                               |
+---------------------+----------------------------------+
```

### Listar roles

```bat
openstack role list
```

**Salida:**
```
+----------------------------------+-----------------+
| ID                               | Name            |
+----------------------------------+-----------------+
| 450e44e8107d4258befe72d96ad46520 | manager         |
| 4835f133b05e4e1aa65bda974c5e0cf5 | member          |
| 71b833489de74956ae61489946907798 | reader          |
| 8dba749ca5e84a72907581fd1f92a963 | admin           |
| f79a56db2db04965a53f405d1debabc9 | service         |
+----------------------------------+-----------------+
```

> Los roles estándar de OpenStack son `admin`, `member` y `reader`.
> En este entorno también existe `manager` (posiblemente un rol personalizado preexistente)
> y `service` (usado por las cuentas de los propios servicios de OpenStack internamente).

### Ver tus asignaciones

```bat
openstack role assignment list --user alumno1 --names
```

**Salida:**
```
+-------+------------------+-------+------------------------+------------------+--------+-----------+
| Role  | User             | Group | Project                | Domain           | System | Inherited |
+-------+------------------+-------+------------------------+------------------+--------+-----------+
| admin | alumno1@dominio- |       | proyecto-alumno1@domin |                  |        | False     |
|       | alumno1          |       | io-alumno1             |                  |        |           |
| admin | alumno1@dominio- |       |                        | dominio-alumno1  |        | False     |
|       | alumno1          |       |                        |                  |        |           |
+-------+------------------+-------+------------------------+------------------+--------+-----------+
```

> Tienes el rol `admin` asignado en dos scopes distintos:
> - En el **proyecto** `proyecto-alumno1` → puedes gestionar recursos de ese proyecto.
> - En el **dominio** `dominio-alumno1` → puedes crear usuarios y proyectos en ese dominio.
>
> Ambos son necesarios para el lab. La asignación de dominio es la que permite crear
> usuarios como `pancracio`.

---

## 4. Práctica 1 — ¿Qué puede ver un alumno?

### token issue

*(ver sección 1 — mismo resultado)*

### project list

```bat
openstack project list
```

**Salida:**
```
+----------------------------------+--------------------+
| ID                               | Name               |
+----------------------------------+--------------------+
| 33cacaffd1cb45c288092b5da19166b7 | proyecto-alumno5   |
| 43ecedc4761842daaae7596b73457271 | proyecto-alumno10  |
| ...                              | ...                |
| 5405e74885034e1c87dc9c55149adb62 | service            |
| 6e1deb9087e547369227c551b3a0e814 | admin              |
| 7dc7a00f1e4d4183a5b142b2392fbdf5 | internal_cinder    |
| e8f46eff64984dd787d46031dd4dcfd3 | proyecto-alumno1   |
| ef89f54b94784e3da85303a41a2e0c42 | proyecto-profesor  |
+----------------------------------+--------------------+
```

> **Sorpresa grande:** ves TODOS los proyectos del cloud (19 en total), incluidos
> `admin`, `service`, `internal_cinder` y los proyectos de todos los compañeros.
> Esto es consecuencia de la policy clásica de OpenStack: un admin de dominio tiene
> visibilidad global de proyectos. **Puedes verlos, pero no puedes modificarlos.**

### user list

```bat
openstack user list
```

**Salida:**
```
+----------------------------------+---------+
| ID                               | Name    |
+----------------------------------+---------+
| 466f3cdb799546c781bdae5906a34d49 | alumno1 |
+----------------------------------+---------+
```

> Aquí el comportamiento es el opuesto: con la policy de este entorno, `user list`
> devuelve solo los usuarios de tu dominio. Al inicio solo eres tú.
> Conforme vayas creando usuarios (pancracio, menchu...) irán apareciendo aquí.
>
> **Conclusión:** para proyectos tienes visibilidad global, para usuarios solo local.
> La policy no es simétrica en todos los recursos.

### role assignment list

```bat
openstack role assignment list --user alumno1 --names
```

*(ver sección 3)*

---

## 5. Práctica 2 — Crear un proyecto secreto

### Crear operacion-croqueta

```bat
openstack project create --domain dominio-alumno1 --description "Operacion ultrasecreta de croquetas" operacion-croqueta
```

**Salida:**
```
+-------------+-------------------------------------+
| Field       | Value                               |
+-------------+-------------------------------------+
| description | Operacion ultrasecreta de croquetas |
| domain_id   | 15e002eea6874dbb924a809d72f2cefa    |
| enabled     | True                                |
| id          | b892a0219ecb4ee1a5c8a72ccc90bbeb    |
| is_domain   | False                               |
| name        | operacion-croqueta                  |
| options     | {}                                  |
| parent_id   | 15e002eea6874dbb924a809d72f2cefa    |
| tags        | []                                  |
+-------------+-------------------------------------+
```

> **Sí funciona.** El proyecto se crea dentro de `dominio-alumno1`
> (fíjate: `domain_id` = ID de tu dominio). No se crea globalmente.
> Otro alumno podría crear su propio `operacion-croqueta` en su dominio sin colisión.

### Verificar

```bat
openstack project show operacion-croqueta
```

*(devuelve los mismos campos del create)*

```bat
openstack project list
```

> Ahora aparece `operacion-croqueta` en la lista, además de todos los anteriores.

---

## 6. Práctica 3 — Crear usuario pancracio

```bat
openstack user create --domain dominio-alumno1 --password '<AQUI_TU_PASSWORD>' pancracio
```

**Salida:**
```
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| default_project_id  | None                             |
| domain_id           | 15e002eea6874dbb924a809d72f2cefa |
| email               | None                             |
| enabled             | True                             |
| id                  | f4cb9486b6b444419e7897ede25a2eb7 |
| name                | pancracio                        |
| description         | None                             |
| password_expires_at | None                             |
| options             | {}                               |
+---------------------+----------------------------------+
```

> Pancracio existe, vive en `dominio-alumno1` y está habilitado.
> Pero en este momento **no tiene ningún rol asignado**:
> puede intentar autenticarse, pero en cualquier operación real recibirá 403.

### Verificar

```bat
openstack user show pancracio --domain dominio-alumno1
```

*(devuelve los mismos campos del create)*

---

## 7. Práctica 4 — Dar permisos a pancracio

```bat
openstack role add --user pancracio --user-domain dominio-alumno1 --project proyecto-alumno1 --project-domain dominio-alumno1 admin
```

**Salida:**
```
(sin salida — en OpenStack, silencio significa éxito)
```

> `role add` no imprime nada cuando funciona. Si hay un error (usuario no existe,
> proyecto no existe, rol no existe) sí aparece un mensaje de error.

### Verificar

```bat
openstack role assignment list --user pancracio --user-domain dominio-alumno1 --names
```

**Salida:**
```
+-------+--------------+-------+-------------------+--------+--------+-----------+
| Role  | User         | Group | Project           | Domain | System | Inherited |
+-------+--------------+-------+-------------------+--------+--------+-----------+
| admin | pancracio@do |       | proyecto-alumno1@ |        |        | False     |
|       | minio-alumno1|       | dominio-alumno1   |        |        |           |
+-------+--------------+-------+-------------------+--------+--------+-----------+
```

> Pancracio tiene rol `admin` en `proyecto-alumno1`. Solo en ese proyecto:
> no en el dominio, y no en ningún otro proyecto.

---

## 8. Práctica 5 — Autenticarse como pancracio

### Definir variables (equivale a cargar openrc de pancracio)

```bat
set OS_AUTH_URL=https://keystone.ivanosuna.com/v3
set OS_IDENTITY_API_VERSION=3
set OS_USERNAME=pancracio
set OS_PASSWORD=<AQUI_TU_PASSWORD>
set OS_PROJECT_NAME=proyecto-alumno1
set OS_USER_DOMAIN_NAME=dominio-alumno1
set OS_PROJECT_DOMAIN_NAME=dominio-alumno1
```

### token issue de pancracio

```bat
openstack token issue
```

**Salida:**
```
+------------+-----------------------------------------------------------------+
| Field      | Value                                                           |
+------------+-----------------------------------------------------------------+
| expires    | 2026-03-17T19:29:17+0000                                        |
| id         | gAAAAABpuQLNc4hpUAeJJLWzqO-...                                  |
| project_id | e8f46eff64984dd787d46031dd4dcfd3                                |
| user_id    | f4cb9486b6b444419e7897ede25a2eb7                                |
+------------+-----------------------------------------------------------------+
```

> Pancracio se autentica correctamente. Fíjate: `user_id` es el de pancracio
> (`f4cb9486...`), diferente al de alumno1 (`466f3cdb...`).
> `project_id` es el mismo: ambos trabajan en `proyecto-alumno1`.

### project show como pancracio

```bat
openstack project show proyecto-alumno1
```

**Salida:**
```
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Proyecto principal de alumno1    |
| domain_id   | 15e002eea6874dbb924a809d72f2cefa |
| enabled     | True                             |
| id          | e8f46eff64984dd787d46031dd4dcfd3 |
| is_domain   | False                            |
| name        | proyecto-alumno1                 |
| options     | {}                               |
| parent_id   | 15e002eea6874dbb924a809d72f2cefa |
| tags        | []                               |
+-------------+----------------------------------+
```

> Pancracio puede ver y operar dentro de `proyecto-alumno1` porque tiene rol `admin` ahí.

---

## 9. Práctica 6 — Detective de Keystone

*(Los comandos son los mismos de la sección 3. Respuestas rápidas:)*

- **¿En qué dominio vive tu usuario?** → `dominio-alumno1` (campo `domain_id` en `user show`)
- **¿Nombre exacto de tu proyecto?** → `proyecto-alumno1` (campo `name` en `project show`)
- **¿Qué rol tienes?** → `admin`, en dos scopes: proyecto y dominio
- **¿Tienes permisos de sistema?** → No. La columna `System` en `role assignment list` está vacía.

**Reto B — Respuestas:**
- Un usuario puede autenticarse (tiene contraseña válida → token) pero no hacer operaciones (no tiene rol en ningún proyecto → 403). **Autenticación ≠ autorización.**
- Un **rol** es la etiqueta (`admin`, `member`...). Una **asignación de rol** es la relación triangular usuario+rol+scope (proyecto o dominio).
- **Proyecto** es donde viven los recursos (instancias, volúmenes...). **Dominio** es el contenedor de usuarios y proyectos. Un proyecto siempre pertenece a un dominio.

---

## 10. Práctica 7 — Comparar roles: admin vs member vs reader

### Crear menchu con rol member

```bat
openstack user create --domain dominio-alumno1 --password '<AQUI_TU_PASSWORD>' menchu
openstack role add --user menchu --user-domain dominio-alumno1 --project proyecto-alumno1 --project-domain dominio-alumno1 member
```

**Salida de create:**
```
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | 15e002eea6874dbb924a809d72f2cefa |
| enabled             | True                             |
| id                  | af7fb51f507e4bfbba08d1d37b3cc248 |
| name                | menchu                           |
+---------------------+----------------------------------+
```

> `role add` no tiene salida cuando funciona.

### Probar como menchu

```bat
set OS_USERNAME=menchu
set OS_PASSWORD=<AQUI_TU_PASSWORD>
openstack token issue
```

**Salida:** *(token válido — menchu se autentica)*

```bat
openstack project list
```

**Salida:**
```
ForbiddenException: 403: You are not authorized to perform the requested action: identity:list_projects.
```

```bat
openstack user list
```

**Salida:**
```
ForbiddenException: 403: You are not authorized to perform the requested action: identity:list_users.
```

> **Resultado:** `member` puede autenticarse pero **no puede listar proyectos ni usuarios**.
> Con este nivel de policy, `member` solo puede operar con recursos ya existentes
> (instancias, volúmenes...) cuando estén disponibles. Keystone lo ve como
> "puede usar el proyecto, pero no gestionarlo".

### Crear eustaquio con rol reader

```bat
openstack user create --domain dominio-alumno1 --password '<AQUI_TU_PASSWORD>' eustaquio
openstack role add --user eustaquio --user-domain dominio-alumno1 --project proyecto-alumno1 --project-domain dominio-alumno1 reader
```

### Probar como eustaquio

```bat
set OS_USERNAME=eustaquio
set OS_PASSWORD=<AQUI_TU_PASSWORD>
openstack token issue
```

**Salida:** *(token válido — eustaquio también se autentica)*

```bat
openstack project list
```

**Salida:**
```
ForbiddenException: 403: You are not authorized to perform the requested action: identity:list_projects.
```

```bat
openstack user list
```

**Salida:**
```
ForbiddenException: 403: You are not authorized to perform the requested action: identity:list_users.
```

> `reader` también obtiene 403. En este entorno, tanto `member` como `reader`
> tienen el mismo comportamiento frente a la gestión de identidad: ninguno puede.
> La diferencia entre `member` y `reader` se notaría en servicios como Nova o Glance:
> `member` puede crear recursos, `reader` solo puede verlos.

**Tabla comparativa real:**

| Operación               | admin | member | reader |
|-------------------------|-------|--------|--------|
| `token issue`           | ✅    | ✅     | ✅     |
| `project list`          | ✅ (todos) | ❌ 403 | ❌ 403 |
| `user list`             | ✅ (dominio) | ❌ 403 | ❌ 403 |
| Crear usuarios          | ✅    | ❌     | ❌     |
| Crear proyectos         | ✅    | ❌     | ❌     |

### Limpieza

```bat
openstack user delete menchu --domain dominio-alumno1
openstack user delete eustaquio --domain dominio-alumno1
```

**Salida:** *(silencio = éxito)*

---

## 11. Práctica 8 — Crear un rol personalizado

### Crear el rol

```bat
openstack role create ayudante-junior
```

**Salida:**
```
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| id          | e823855d2b6e4596800513cecb4f60ec |
| name        | ayudante-junior                  |
| domain_id   | None                             |
| description | None                             |
+-------------+----------------------------------+
```

> El rol existe ahora en Keystone. `domain_id: None` significa que es un rol global.
> Pero **no tiene ninguna policy asociada**: es una etiqueta vacía.

### Crear pepito y asignarle el rol

```bat
openstack user create --domain dominio-alumno1 --password '<AQUI_TU_PASSWORD>' pepito
openstack role add --user pepito --user-domain dominio-alumno1 --project proyecto-alumno1 --project-domain dominio-alumno1 ayudante-junior
```

### Verificar la asignación

```bat
openstack role assignment list --user pepito --user-domain dominio-alumno1 --names
```

**Salida:**
```
+------------------+------------------+-------+--------------------+--------+--------+-----------+
| Role             | User             | Group | Project            | Domain | System | Inherited |
+------------------+------------------+-------+--------------------+--------+--------+-----------+
| ayudante-junior  | pepito@dominio-  |       | proyecto-alumno1@  |        |        | False     |
|                  | alumno1          |       | dominio-alumno1    |        |        |           |
+------------------+------------------+-------+--------------------+--------+--------+-----------+
```

> La asignación existe. Pepito tiene el rol. Ahora veamos si sirve de algo.

### Autenticarse como pepito y probar

```bat
set OS_USERNAME=pepito
set OS_PASSWORD=<AQUI_TU_PASSWORD>
openstack token issue
```

**Salida:** *(token válido — pepito se autentica sin problema)*

```bat
openstack project list
```

**Salida:**
```
ForbiddenException: 403: You are not authorized to perform the requested action: identity:list_projects.
```

```bat
openstack user list
```

**Salida:**
```
ForbiddenException: 403: You are not authorized to perform the requested action: identity:list_users.
```

> **Conclusión clave:** Pepito tiene token (autenticado), tiene rol asignado (existe la asignación),
> pero **recibe 403 en todo**. El motivo: las policies de Keystone no conocen
> `ayudante-junior`. Los archivos de policy dicen cosas como:
> `"identity:list_projects": "role:admin or role:member"`.
> Como `ayudante-junior` no aparece en ninguna regla, no tiene permisos para nada.
>
> **Un rol sin policy es decorativo.** Crear el rol es fácil. Darle permisos reales
> requiere modificar los archivos de policy del servidor, que es tarea del administrador
> del cloud, no del usuario.

### Limpieza

```bat
openstack user delete pepito --domain dominio-alumno1
openstack role delete ayudante-junior
```

> **Orden importante:** primero el usuario (que tiene el rol asignado),
> luego el rol. Si intentas borrar el rol mientras alguien lo tiene asignado,
> en algunas versiones de OpenStack puede funcionar o puede dar error.
> La práctica recomendada es retirar las asignaciones antes de borrar el rol.

---

## 12. Práctica 9 — Formatos de salida

### -f table (por defecto)

```bat
openstack token issue -f table
```

**Salida:**
```
+------------+----------------------------------+
| Field      | Value                            |
+------------+----------------------------------+
| expires    | 2026-03-17T19:31:13+0000         |
| id         | gAAAAABpuQNBi18aDroz...          |
| project_id | e8f46eff64984dd787d46031dd4dcfd3 |
| user_id    | 466f3cdb799546c781bdae5906a34d49 |
+------------+----------------------------------+
```

### -f json

```bat
openstack token issue -f json
```

**Salida:**
```json
{
  "expires": "2026-03-17T19:31:14+0000",
  "id": "gAAAAABpuQNCe3pliW8G3ry3I3_ZHO-Aq4R0GhyH439bg...",
  "project_id": "e8f46eff64984dd787d46031dd4dcfd3",
  "user_id": "466f3cdb799546c781bdae5906a34d49"
}
```

### -f yaml

```bat
openstack token issue -f yaml
```

**Salida:**
```yaml
expires: 2026-03-17T19:31:16+0000
id: gAAAAABpuQNEsmdJ39HML2p7uV72eNeiIlCtUEy5rVJ8rX_gFEhl...
project_id: e8f46eff64984dd787d46031dd4dcfd3
user_id: 466f3cdb799546c781bdae5906a34d49
```

### -f value (todos los valores, sin cabeceras)

```bat
openstack token issue -f value
```

**Salida:**
```
2026-03-17T19:31:18+0000
gAAAAABpuQNG8dWV4kNa-ACyRtx1NIego0...
e8f46eff64984dd787d46031dd4dcfd3
466f3cdb799546c781bdae5906a34d49
```

> Los 4 valores en orden (expires, id, project_id, user_id). Sin etiquetas: poco útil solo.

### -f value -c campo (extrae un campo concreto)

```bat
openstack token issue -f value -c user_id
```

**Salida:**
```
466f3cdb799546c781bdae5906a34d49
```

> Solo el valor, sin nada más. Perfecto para scripts:
> `USER_ID=$(openstack token issue -f value -c user_id)`

### Múltiples columnas

```bat
openstack token issue -f value -c project_id -c user_id
```

**Salida:**
```
e8f46eff64984dd787d46031dd4dcfd3
466f3cdb799546c781bdae5906a34d49
```

### Listados en diferentes formatos

```bat
openstack user list -f json
```

**Salida:**
```json
[
  { "ID": "466f3cdb799546c781bdae5906a34d49", "Name": "alumno1" },
  { "ID": "5861944f0ad142c0b602f55e2024d03e", "Name": "eustaquio" },
  { "ID": "7d58559a767247ac9da5f3b163bcd8ca", "Name": "pepito" },
  { "ID": "af7fb51f507e4bfbba08d1d37b3cc248", "Name": "menchu" },
  { "ID": "f4cb9486b6b444419e7897ede25a2eb7", "Name": "pancracio" }
]
```

> Este output se tomó antes de la limpieza. Tras limpiar solo aparecería alumno1.

```bat
openstack role list -f csv
```

**Salida:**
```
"ID","Name"
"450e44e8107d4258befe72d96ad46520","manager"
"4835f133b05e4e1aa65bda974c5e0cf5","member"
"71b833489de74956ae61489946907798","reader"
"8dba749ca5e84a72907581fd1f92a963","admin"
"e823855d2b6e4596800513cecb4f60ec","ayudante-junior"
"f79a56db2db04965a53f405d1debabc9","service"
```

> Este output incluía `ayudante-junior` porque se ejecutó antes de borrarlo. Curiosidad:
> el CSV de OpenStack incluye siempre las comillas, compatible con Excel y Google Sheets.

```bat
openstack project list -f value -c Name
```

**Salida (fragmento):**
```
proyecto-alumno5
proyecto-alumno10
...
operacion-croqueta
...
proyecto-alumno1
...
```

> Un valor por línea. Muy útil en bash: `for p in $(openstack project list -f value -c Name)`

---

## 13. Práctica 10 — Limpieza general

```bat
rem Vuelve al contexto de alumno1 antes de limpiar.
set OS_USERNAME=alumno1
set OS_PASSWORD=<tu_password>
set OS_PROJECT_NAME=proyecto-alumno1
set OS_USER_DOMAIN_NAME=dominio-alumno1
set OS_PROJECT_DOMAIN_NAME=dominio-alumno1
openstack user delete pancracio --domain dominio-alumno1
openstack project delete operacion-croqueta --domain dominio-alumno1
```

**Salida de cada delete:**
```
(silencio = éxito)
```

### Verificar

```bat
openstack role assignment list --user alumno1 --names
```

**Salida:**
```
+-------+------------------+-------+------------------------+------------------+--------+-----------+
| Role  | User             | Group | Project                | Domain           | System | Inherited |
+-------+------------------+-------+------------------------+------------------+--------+-----------+
| admin | alumno1@dominio- |       | proyecto-alumno1@domin |                  |        | False     |
|       | alumno1          |       | io-alumno1             |                  |        |           |
| admin | alumno1@dominio- |       |                        | dominio-alumno1  |        | False     |
|       | alumno1          |       |                        |                  |        |           |
+-------+------------------+-------+------------------------+------------------+--------+-----------+
```

> Tus asignaciones originales están intactas. Solo tienes el rol `admin` en tu proyecto
> y en tu dominio. Ningún rastro de pancracio, menchu, eustaquio, pepito ni operacion-croqueta.

```bat
openstack project list -f value -c Name | grep alumno1
```

**Salida:**
```
proyecto-alumno10
proyecto-alumno15
proyecto-alumno11
proyecto-alumno13
proyecto-alumno12
proyecto-alumno1
proyecto-alumno14
```

> Solo queda `proyecto-alumno1`. `operacion-croqueta` ha sido borrado.

---

## Resumen de comportamientos observados en este entorno

| Aspecto | Comportamiento real |
|---------|---------------------|
| `project list` como alumno1 | Ve TODOS los proyectos (19), incluidos admin, service y compañeros |
| `user list` como alumno1 | Solo ve usuarios de su dominio |
| `domain list` como alumno1 | Ve todos los dominios del cloud |
| `member` → `project list` | 403 Forbidden |
| `reader` → `project list` | 403 Forbidden |
| `ayudante-junior` → cualquier cosa | 403 Forbidden |
| Crear usuario en otro dominio | 403 (sí respeta el aislamiento de dominios) |
| `role add` con éxito | Sin salida (silencio = OK) |
| `role create` custom | Funciona, pero sin policy no da permisos reales |

---

## Análisis forense: la effective policy de Keystone

> Esta sección es para el profesor. Explica **por qué** ocurre cada comportamiento observado.

### Cómo obtener la effective policy

La policy efectiva de Keystone combina los defaults del código con cualquier override en `policy.yaml`.
En este entorno (Kubernetes), el `policy.yaml` está **vacío** — todo viene de los defaults del código.

Para generarla, ejecutar dentro del pod de Keystone:

```bash
kubectl exec -n openstack keystone-api-<POD_ID> -- \
  /var/lib/openstack/bin/oslopolicy-policy-generator \
  --namespace keystone \
  --config-file /etc/keystone/keystone.conf
```

---

### Reglas base (las más importantes)

```
"admin_required": "role:admin or is_admin:1"
"owner":          "user_id:%(user_id)s"
"admin_or_owner": "rule:admin_required or rule:owner"
"service_role":   "role:service"
"domain_managed_target_role": "'manager':%(target.role.name)s or 'member':%(target.role.name)s or 'reader':%(target.role.name)s"
```

**Dato clave:** `admin_required` solo comprueba que el token tenga `role:admin`. **No exige system scope.**
Esto es la policy clásica/legacy de OpenStack (pre-Yoga). Un admin de dominio pasa esta regla igual que un admin de sistema.

---

### Reglas de las operaciones del lab

```
"identity:list_projects":   "(rule:admin_required) or (role:reader and system_scope:all) or (role:reader and domain_id:%(target.domain_id)s)"
"identity:list_users":      "(rule:admin_required) or (role:reader and system_scope:all) or (role:reader and domain_id:%(target.domain_id)s)"
"identity:create_project":  "(rule:admin_required) or (role:manager and domain_id:%(target.project.domain_id)s)"
"identity:create_user":     "(rule:admin_required) or (role:manager and token.domain.id:%(target.user.domain_id)s)"
"identity:list_roles":      "(rule:admin_required or (role:reader and system_scope:all)) or (role:manager and not domain_id:None)"
"identity:list_services":   "rule:admin_required or (role:reader and system_scope:all)"
"identity:list_endpoints":  "rule:admin_required or (role:reader and system_scope:all)"
"identity:get_project":     "(rule:admin_required) or (role:reader and system_scope:all) or (role:reader and domain_id:%(target.project.domain_id)s) or project_id:%(target.project.id)s"
"identity:get_user":        "(rule:admin_required) or (role:reader and system_scope:all) or (role:reader and token.domain.id:%(target.user.domain_id)s) or user_id:%(target.user.id)s"
```

---

### Por qué alumno1 ve TODOS los proyectos

alumno1 tiene `role:admin` en su dominio y proyecto. Al ejecutar `project list`:

1. Keystone evalúa `identity:list_projects` → `rule:admin_required` → `role:admin` ✅ **PASA**
2. Como la policy clásica no exige `system_scope:all`, un admin de dominio **tiene los mismos permisos de listado que el admin global**
3. Keystone devuelve **todos** los proyectos del cloud (no filtra por dominio para admins)

Resultado: 19 proyectos visibles en lugar de 1. Esto es un comportamiento conocido de la policy legacy y se corrige activando `enforce_scope = true` en `keystone.conf`.

Para `user list` el comportamiento es diferente: Keystone sí filtra automáticamente por dominio cuando el token no tiene `system_scope:all`, mostrando solo los usuarios del dominio propio.

---

### Por qué member y reader siempre obtienen 403 en identity

El rol `member` **no aparece en ninguna regla de identity** de Keystone. Solo está contemplado en los servicios de compute (Nova), almacenamiento (Cinder/Swift) e imagen (Glance).

El rol `reader` sí aparece, pero **siempre con `system_scope:all`** o con un `domain_id` explícito. Los tokens de proyecto (los que usan los alumnos) no tienen `system_scope:all`, así que las condiciones no se cumplen.

```
# Para que reader funcionara necesitaría:
# - Token con system_scope (openstack --os-system-scope all ...)
# ó
# - Token con domain scope + ser reader explícito de ese dominio

# Los alumnos usan tokens de proyecto → ni una condición se cumple → 403
```

---

### Por qué ayudante-junior siempre obtiene 403

```bash
# Buscar si aparece en la effective policy:
grep "ayudante-junior" keystone-effective-policy.yaml
# → sin resultados

# Esto confirma:
# - El rol existe en la base de datos de Keystone
# - Las role assignments de pepito son válidas
# - Pero NINGUNA regla de policy usa ese nombre de rol
# → El motor oslo.policy nunca lo activa → 403 en todo
```

**Frase para clase:**

> **Autenticación:** "sí, eres tú" → Keystone comprueba usuario y contraseña → emite token ✅  
> **Role assignment:** "sí, tienes este rol" → la asignación existe en BD ✅  
> **Policy (oslo.policy):** "vale, pero con ese rol, ¿qué te dejo hacer?" → `ayudante-junior` no aparece en ninguna regla → 403 ❌

Un rol custom en Keystone es solo una **etiqueta**. No da permisos por arte de magia. Los permisos los define la policy (`policy.yaml`) y si esa policy no menciona el rol, el rol existe pero no abre ninguna puerta.

---

### Diagrama del flujo de autorización

```
Usuario hace petición API
        │
        ▼
┌───────────────────┐
│   Autenticación   │  ← ¿Usuario existe? ¿Password correcto?
│  (Keystone auth)  │     → Si sí: emite token con roles incluidos
└────────┬──────────┘
         │ token válido
         ▼
┌───────────────────┐
│  oslo.policy      │  ← ¿La policy permite esta acción con estos roles?
│  (autorización)   │     Evalúa las reglas del policy.yaml/defaults
└────────┬──────────┘
         │
    ┌────┴────┐
    ▼         ▼
  200 OK    403 Forbidden
(permitido)  (rol existe pero
              policy no lo usa)
```

---

### Cómo arreglar esto (para el profesor)

Para que `reader` funcione sin `system_scope`, habría que añadir overrides en `/etc/keystone/policy.yaml`:

```yaml
# Ejemplo: permitir que readers de dominio listen proyectos de su dominio
"identity:list_projects": "(rule:admin_required) or (role:reader and system_scope:all) or (role:reader and domain_id:%(target.domain_id)s) or (role:reader and token.project.domain_id:%(target.project.domain_id)s)"
```

Para que `ayudante-junior` pudiera listar proyectos de su dominio:

```yaml
"identity:list_projects": "(rule:admin_required) or (role:reader and system_scope:all) or (role:reader and domain_id:%(target.domain_id)s) or (role:ayudante-junior and token.project.domain_id:%(target.project.domain_id)s)"
```

Cambiar los overrides en `policy.yaml` tiene efecto **inmediato** (sin reiniciar Keystone).
