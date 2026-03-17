# Respuestas del lab — Primeros pasos con OpenStack CLI

> Ejecutado con el usuario **alumno1** contra `https://keystone.ivanosuna.com/v3`
> Fecha: 17 de marzo de 2026 — Cliente: openstack 9.0.0

---

## 1. Configurar el entorno

### Cargar el openrc y verificar variables

```bash
source alumno1-openrc.sh
set | grep ^OS_
```

**Salida:**
```
OS_AUTH_URL=https://keystone.ivanosuna.com/v3
OS_IDENTITY_API_VERSION=3
OS_PASSWORD=<AQUI_TU_PASSWORD>
OS_PROJECT_DOMAIN_NAME=dominio-alumno1
OS_PROJECT_NAME=proyecto-alumno1
OS_USERNAME=alumno1
OS_USER_DOMAIN_NAME=dominio-alumno1
```

> **Nota:** fíjate que no hay `OS_REGION_NAME` definido. El cliente usa `RegionOne` por defecto
> cuando no está definida. En Windows la variable sería `set OS_` (sin el signo igual) para listar.

---

## 2. Verificar autenticación

### `openstack token issue`

```bash
openstack token issue
```

**Salida:**
```
+------------+-----------------------------------------------------------------+
| Field      | Value                                                           |
+------------+-----------------------------------------------------------------+
| expires    | 2026-03-17T19:00:03+0000                                        |
| id         | gAAAAABpuPvzIr0njR4vpYhHhLi3Vdt9MfJPA_x2w8Rp1on6yNlDEJn15Wb73S7|
|            | gLyi8W7vlltQ6LS6NsB41ZrjIcsZGIZ_YpJeVyUW5URsPlzBAisQ7dhrDWtAGPq|
|            | nhjXVoizpY0tnTs8xQKn53m2J8T3X3Zy2get_R9BupUJhqhRYQkLXoI8U       |
| project_id | 6e1deb9087e547369227c551b3a0e814                                |
| user_id    | 35b21c78be1c492e8d6c153e5467ef4c                                |
+------------+-----------------------------------------------------------------+
```

> **Qué vemos:**
> - `expires` — el token caduca en 1 hora (por defecto en Keystone). Pasado ese tiempo
>   hay que autenticarse de nuevo.
> - `id` — el token en sí. Es un string largo opaco que se manda en la cabecera
>   `X-Auth-Token` de cada llamada a la API.
> - `project_id` — el proyecto con el que nos hemos autenticado (`proyecto-alumno1`).
> - `user_id` — el ID interno del usuario `alumno1`.
>
> Si ves un error `HTTP 401 Unauthorized` aquí, para y revisa las variables `OS_*`.

### Token en formato JSON

```bash
openstack token issue -f json
```

**Salida:**
```json
{
  "expires": "2026-03-17T19:00:15+0000",
  "id": "gAAAAABpuPv_vlob6rga7cs1FpmIxdssQQrImsMXJ-CrzX0PY4NTiSN...",
  "project_id": "6e1deb9087e547369227c551b3a0e814",
  "user_id": "35b21c78be1c492e8d6c153e5467ef4c"
}
```

> **Nota:** `token issue` devuelve los mismos 4 campos en todos los formatos.
> Para ver roles y catálogo del token habría que descifrar el JWT o
> usar `openstack token issue` con debug (`--debug`).

---

## 3. ¿Quién soy yo?

### Paso 1 — Obtener el user_id del token

```bash
openstack token issue -f value -c user_id
```

**Salida:**
```
35b21c78be1c492e8d6c153e5467ef4c
```

> `-f value` elimina la tabla y devuelve solo el valor.
> `-c user_id` filtra solo esa columna.
> En Windows copia este valor y pégalo en el siguiente comando.

### Paso 2 — Ver detalles del usuario

```bash
openstack user show 35b21c78be1c492e8d6c153e5467ef4c
```

**Salida:**
```
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| default_project_id  | None                             |
| domain_id           | dominio-alumno1                  |
| email               | None                             |
| enabled             | True                             |
| id                  | 35b21c78be1c492e8d6c153e5467ef4c |
| name                | alumno1                          |
| description         | None                             |
| password_expires_at | None                             |
| options             | {}                               |
+---------------------+----------------------------------+
```

> **Qué vemos:**
> - `domain_id: dominio-alumno1` — el usuario `alumno1` vive en su propio dominio `dominio-alumno1`.
> - `enabled: True` — la cuenta está activa. Si fuese `False` no podría autenticarse.
> - `password_expires_at: None` — la contraseña no caduca nunca (configuración de lab).
> - `default_project_id: None` — no tiene proyecto por defecto asignado; lo obtiene del openrc.

### Ver tu proyecto activo

```bash
openstack project show proyecto-alumno1
```

**Salida:**
```
+-------------+-----------------------------------------------+
| Field       | Value                                         |
+-------------+-----------------------------------------------+
| description | Proyecto del alumno 1.                        |
| domain_id   | dominio-alumno1                               |
| enabled     | True                                          |
| id          | 6e1deb9087e547369227c551b3a0e814              |
| is_domain   | False                                         |
| name        | proyecto-alumno1                              |
| options     | {}                                            |
| parent_id   | dominio-alumno1                               |
| tags        | []                                            |
+-------------+-----------------------------------------------+
```

> El proyecto `proyecto-alumno1` pertenece al dominio `dominio-alumno1`.
> `parent_id: dominio-alumno1` indica que su dominio padre es el dominio del alumno.

### Ver todos los proyectos

```bash
openstack project list
```

**Salida:**
```
+----------------------------------+-----------------+
| ID                               | Name            |
+----------------------------------+-----------------+
| 6e1deb9087e547369227c551b3a0e814 | proyecto-alumno1 |
+----------------------------------+-----------------+
```

> Como `alumno1`, solo ves los proyectos de tu dominio.
> En este caso solo aparece `proyecto-alumno1`.
> El usuario `admin` global vería también `service`, `internal_cinder` y los proyectos del resto de alumnos.

### Ver el dominio

```bash
openstack domain show Default
```

**Salida:**
```
+-------------+--------------------+
| Field       | Value              |
+-------------+--------------------+
| id          | default            |
| name        | Default            |
| enabled     | True               |
| description | The default domain |
| options     | {}                 |
+-------------+--------------------+
```

> El dominio `Default` tiene siempre el ID fijo `default` (en minúsculas).
> Es especial: existe desde la instalación inicial y no se puede borrar.

### Ver todos los dominios

```bash
openstack domain list
```

**Salida:**
```
+----------------------------------+---------+---------+--------------------+
| ID                               | Name    | Enabled | Description        |
+----------------------------------+---------+---------+--------------------+
| af68646f69dc4e98868c2b21c797a163 | service | True    | Domain for service |
| default                          | Default | True    | The default domain |
+----------------------------------+---------+---------+--------------------+
```

> Solo hay dos dominios porque el cluster está limpio (se borró el entorno de prácticas).
> - `Default` — dominio de usuarios de administración.
> - `service` — dominio donde viven las cuentas de los servicios de OpenStack.
>
> Cuando se ejecute `crear_usuarios_keystone.sh` aparecerán aquí `dominio-alumno1..15`
> y `dominio-profesor`.

---

## 4. Regiones

```bash
openstack region list
```

**Salida:**
```
+-----------+---------------+-------------+
| Region    | Parent Region | Description |
+-----------+---------------+-------------+
| RegionOne | None          |             |
+-----------+---------------+-------------+
```

> Solo hay una región: `RegionOne`.
> Es el nombre por defecto que pone OpenStack durante la instalación.
> En grandes clouds públicos hay varias regiones (por ejemplo `eu-west-1`, `us-east-1`).
>
> Todos los endpoints del catálogo están asociados a `RegionOne`.
> Si hubiera varias regiones, cada una tendría sus propios endpoints.

---

## 5. Servicios y catálogo

### Servicios registrados

```bash
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

> Hay más servicios de los esperados. El cloud tiene instalados:
>
> | Servicio   | Tipo           | Función                                  |
> |------------|----------------|------------------------------------------|
> | keystone   | identity       | Autenticación y autorización             |
> | glance     | image          | Gestión de imágenes de máquinas virtuales|
> | swift      | object-store   | Almacenamiento de objetos (como S3)      |
> | cinderv3   | volumev3       | Volúmenes de bloques (como discos)       |
> | placement  | placement      | Gestión de recursos de cómputo           |
>
> Nota: `placement` es un servicio auxiliar que usa Nova (cómputo) para saber dónde
> alojar máquinas virtuales. No se usa directamente desde la CLI en labs básicos.

### Catálogo completo

```bash
openstack catalog list
```

**Salida:**
```
+-----------+--------------+---------------------------------------------------+
| Name      | Type         | Endpoints                                         |
+-----------+--------------+---------------------------------------------------+
| glance    | image        | RegionOne                                         |
|           |              |   admin: https://glance.ivanosuna.com             |
|           |              | RegionOne                                         |
|           |              |   internal: http://glance-                        |
|           |              | api.openstack.svc.cluster.local:9292              |
|           |              | RegionOne                                         |
|           |              |   public: https://glance.ivanosuna.com            |
|           |              |                                                   |
| swift     | object-store | RegionOne                                         |
|           |              |   internal: https://swift.ivanosuna.com/swift/v1/ |
|           |              | AUTH_6e1deb9087e547369227c551b3a0e814             |
|           |              | RegionOne                                         |
|           |              |   public: https://swift.ivanosuna.com/swift/v1/...|
|           |              | RegionOne                                         |
|           |              |   admin: https://swift.ivanosuna.com/swift/v1/... |
|           |              |                                                   |
| keystone  | identity     | RegionOne                                         |
|           |              |   public: https://keystone.ivanosuna.com/v3       |
|           |              | RegionOne                                         |
|           |              |   admin: https://keystone.ivanosuna.com/v3        |
|           |              | RegionOne                                         |
|           |              |   internal: http://keystone-                      |
|           |              | api.openstack.svc.cluster.local:5000/v3           |
|           |              |                                                   |
| placement | placement    | RegionOne                                         |
|           |              |   admin: http://placement-api.openstack...        |
|           |              | RegionOne                                         |
|           |              |   internal: http://placement-api.openstack...     |
|           |              | RegionOne                                         |
|           |              |   public: http://placement.openstack...           |
|           |              |                                                   |
| cinderv3  | volumev3     | RegionOne                                         |
|           |              |   public: https://cinder.ivanosuna.com/v3/...     |
|           |              | RegionOne                                         |
|           |              |   admin: https://cinder.ivanosuna.com/v3/...      |
|           |              | RegionOne                                         |
|           |              |   internal: http://cinder-api.openstack...        |
|           |              |                                                   |
+-----------+--------------+---------------------------------------------------+
```

> **Patrón que se repite en cada servicio:**
> - `public` → URL accesible desde fuera del cluster (Internet / los clientes del curso).
> - `internal` → URL que solo existe dentro del cluster Kubernetes donde corre OpenStack.
>   Usa nombres DNS internos de Kubernetes (`*.openstack.svc.cluster.local`).
> - `admin` → En muchos servicios apunta a la misma URL que `public`.
>   En instalaciones on-premise suele apuntar a una red de gestión separada.
>
> Los alumnos siempre usan el endpoint `public`.

### Endpoints filtrados (solo columnas útiles)

```bash
openstack endpoint list -c "Service Name" -c "Interface" -c "URL" -c "Enabled"
```

**Salida:**
```
+--------------+---------+-----------+-----------------------------------------+
| Service Name | Enabled | Interface | URL                                     |
+--------------+---------+-----------+-----------------------------------------+
| glance       | True    | admin     | https://glance.ivanosuna.com            |
| keystone     | True    | public    | https://keystone.ivanosuna.com/v3       |
| cinderv3     | True    | public    | https://cinder.ivanosuna.com/v3/%(tenan |
|              |         |           | t_id)s                                  |
| swift        | True    | internal  | https://swift.ivanosuna.com/swift/v1/AU |
|              |         |           | TH_%(tenant_id)s                        |
| placement    | True    | admin     | http://placement-                       |
|              |         |           | api.openstack.svc.cluster.local:8778/   |
| swift        | True    | public    | https://swift.ivanosuna.com/swift/v1/AU |
|              |         |           | TH_%(tenant_id)s                        |
| cinderv3     | True    | admin     | https://cinder.ivanosuna.com/v3/%(tenan |
|              |         |           | t_id)s                                  |
| keystone     | True    | admin     | https://keystone.ivanosuna.com/v3       |
| swift        | True    | admin     | https://swift.ivanosuna.com/swift/v1/AU |
|              |         |           | TH_%(tenant_id)s                        |
| glance       | True    | internal  | http://glance-                          |
|              |         |           | api.openstack.svc.cluster.local:9292    |
| keystone     | True    | internal  | http://keystone-                        |
|              |         |           | api.openstack.svc.cluster.local:5000/v3 |
| placement    | True    | internal  | http://placement-                       |
|              |         |           | api.openstack.svc.cluster.local:8778/   |
| cinderv3     | True    | internal  | http://cinder-                          |
|              |         |           | api.openstack.svc.cluster.local:8776/v3 |
| placement    | True    | public    | http://placement.openstack.svc.cluster. |
|              |         |           | local/                                  |
| glance       | True    | public    | https://glance.ivanosuna.com            |
+--------------+---------+-----------+-----------------------------------------+
```

> **Detalle curioso:** las URLs de Cinder y Swift contienen `%(tenant_id)s`.
> Es un placeholder que OpenStack sustituye en tiempo de ejecución por el ID del proyecto
> del usuario autenticado. Así cada usuario accede a su propio espacio de almacenamiento.

### Endpoints solo de Keystone

```bash
openstack endpoint list --service identity -c "Interface" -c "URL"
```

**Salida:**
```
+-----------+---------------------------------------------------------+
| Interface | URL                                                     |
+-----------+---------------------------------------------------------+
| public    | https://keystone.ivanosuna.com/v3                       |
| admin     | https://keystone.ivanosuna.com/v3                       |
| internal  | http://keystone-api.openstack.svc.cluster.local:5000/v3 |
+-----------+---------------------------------------------------------+
```

> Los tres endpoints de Keystone: `public` y `admin` apuntan a la misma URL pública,
> `internal` apunta al pod de Kubernetes directamente por DNS interno.

---

## 6. Versión del cliente y de la API

### Versión del cliente

```bash
openstack --version
```

**Salida:**
```
openstack 9.0.0
```

> `python-openstackclient` versión 9.0.0. Es una versión reciente (2024).
> El número de versión del cliente no tiene por qué coincidir con la versión de OpenStack.

### Versiones de la API

```bash
openstack versions show
```

> Devuelve una tabla muy larga con todas las versiones de API soportadas por cada servicio
> (por ejemplo `image 2.0` hasta `image 2.9` para Glance, etc.).
> Lo importante es confirmar que la versión `3` de identity está en estado `CURRENT` o `STABLE`.

---

## 7. Formatos de salida

### `-f value -c campo` — solo el valor

```bash
openstack token issue -f value -c id
```

**Salida:**
```
gAAAAABpuPyJh54PtG5WZjE9Ww3eOSL_Cktr5oHWSE80tRXRkcupEiRDgX-h1Rq...
```

> Perfecto para scripts: devuelve solo el string, sin tabla, sin cabeceras.
> En bash puedes capturarlo: `TOKEN=$(openstack token issue -f value -c id)`

### `-f json`

```bash
openstack service list -f json
```

**Salida:**
```json
[
  {
    "ID": "2d772fde803241b1b79278aa905c3b49",
    "Name": "glance",
    "Type": "image"
  },
  {
    "ID": "61b126160a8e4cbca53278cef16fa930",
    "Name": "swift",
    "Type": "object-store"
  },
  {
    "ID": "746b314b528c494d98f46895e4d00cb0",
    "Name": "keystone",
    "Type": "identity"
  },
  {
    "ID": "999444fb84dd4932af391c25dc634a13",
    "Name": "placement",
    "Type": "placement"
  },
  {
    "ID": "f488e41862f24b91b57a9f307dcba0a9",
    "Name": "cinderv3",
    "Type": "volumev3"
  }
]
```

> JSON es ideal para procesar con `jq` o desde Python/Ansible.

### `-f yaml`

```bash
openstack service list -f yaml
```

**Salida:**
```yaml
- ID: 2d772fde803241b1b79278aa905c3b49
  Name: glance
  Type: image
- ID: 61b126160a8e4cbca53278cef16fa930
  Name: swift
  Type: object-store
- ID: 746b314b528c494d98f46895e4d00cb0
  Name: keystone
  Type: identity
- ID: 999444fb84dd4932af391c25dc634a13
  Name: placement
  Type: placement
- ID: f488e41862f24b91b57a9f307dcba0a9
  Name: cinderv3
  Type: volumev3
```

> YAML es más legible que JSON para inspección manual.

---

## Resumen de lo que tiene este cloud

| Servicio   | URL pública                          | Para qué sirve                        |
|------------|--------------------------------------|---------------------------------------|
| keystone   | https://keystone.ivanosuna.com/v3    | Autenticación e identidad             |
| glance     | https://glance.ivanosuna.com         | Imágenes de máquinas virtuales        |
| swift      | https://swift.ivanosuna.com          | Almacenamiento de objetos             |
| cinderv3   | https://cinder.ivanosuna.com/v3      | Volúmenes de bloques                  |
| placement  | (solo red interna)                   | Scheduling de recursos (auxiliar)     |

> **Sorpresa del lab:** el cloud tiene más servicios de los que se veían en sesiones anteriores.
> Glance ya lo conocíamos. Swift (object-store) y Cinderv3 (volumev3) son servicios de
> almacenamiento que veremos en módulos posteriores. Placement es interno y nunca
> se usa directamente desde la CLI de usuario.
