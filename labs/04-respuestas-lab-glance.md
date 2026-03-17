# Respuestas del lab — Prácticas de Glance

> Ejecutado con el usuario **profesor** contra `https://glance.ivanosuna.com`  
> Fecha: 17 de marzo de 2026 — Cliente: openstack 9.0.0

---

## 1. Preparación del entorno

### Comprobar que Glance está disponible

```bat
openstack catalog show image
```

**Salida:**
```
+-----------+----------------------------------------------+
| Field     | Value                                        |
+-----------+----------------------------------------------+
| endpoints | RegionOne                                    |
|           |   admin: https://glance.ivanosuna.com        |
|           |   internal: http://glance-api.openstack...   |
|           |   public: https://glance.ivanosuna.com       |
|           |                                              |
| id        | 2d772fde803241b1b79278aa905c3b49             |
| name      | glance                                       |
| type      | image                                        |
+-----------+----------------------------------------------+
```

---

## 2. Explorar imágenes existentes

### Listar imágenes (cuenta nueva, sin imágenes)

```bat
openstack image list
```

**Salida:**
```
(sin salida — no hay imágenes visibles para este proyecto)
```

> En un entorno de producción verías imágenes públicas del sistema (Ubuntu, CentOS...).
> En este entorno de laboratorio, cada alumno trabaja con sus propias imágenes.

### Ver métodos de importación disponibles

```bat
openstack image import info
```

**Salida:**
```
+----------------+-----------------------------------------+
| Field          | Value                                   |
+----------------+-----------------------------------------+
| import-methods | copy-image, glance-direct, web-download |
+----------------+-----------------------------------------+
```

> Este Glance soporta tres métodos de importación:
> - `glance-direct`: subida directa desde el cliente (el método de `--file`)
> - `web-download`: Glance descarga desde una URL por su cuenta
> - `copy-image`: copia entre stores de Glance

---

## 3. Práctica 1 — Subir imagen desde fichero

### Descargar imagen de prueba (cirros ~20 MB)

```bash
curl -L http://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img -o cirros.img
ls -lh cirros.img
```

**Salida:**
```
-rw-r--r-- 1 usuario usuario 20M mar 17 19:34 cirros.img
```

### Subir la imagen

```bat
openstack image create \
  --container-format bare \
  --disk-format qcow2 \
  --file cirros.img \
  --private \
  --min-disk 1 \
  --min-ram 64 \
  --property os_distro=cirros \
  --property os_version=0.6.2 \
  "mi-cirros"
```

**Salida:**
```
+------------------+---------------------------------------------------------------------------------------------------+
| Field            | Value                                                                                             |
+------------------+---------------------------------------------------------------------------------------------------+
| checksum         | c8fc807773e5354afe61636071771906                                                                  |
| container_format | bare                                                                                              |
| created_at       | 2026-03-17T18:34:46Z                                                                              |
| disk_format      | qcow2                                                                                             |
| file             | /v2/images/da26cf74-6aba-4cbb-9ede-03d0ca378abb/file                                              |
| id               | da26cf74-6aba-4cbb-9ede-03d0ca378abb                                                              |
| min_disk         | 1                                                                                                 |
| min_ram          | 64                                                                                                |
| name             | mi-cirros                                                                                         |
| owner            | 4bf95451094d4f659bfdba7d716c71da                                                                  |
| properties       | os_distro='cirros', os_hidden='False', os_version='0.6.2',                                        |
|                  | owner_specified.openstack.md5='', owner_specified.openstack.object='images/mi-cirros',            |
|                  | owner_specified.openstack.sha256='', stores='rbd'                                                 |
| protected        | False                                                                                             |
| schema           | /v2/schemas/image                                                                                 |
| size             | 21430272                                                                                          |
| status           | active                                                                                            |
| tags             |                                                                                                   |
| updated_at       | 2026-03-17T18:34:51Z                                                                              |
| virtual_size     | 117440512                                                                                         |
| visibility       | private                                                                                           |
+------------------+---------------------------------------------------------------------------------------------------+
```

> **Fíjate en:**
> - `status=active`: la imagen subió correctamente y está lista para lanzar instancias.
> - `size=21430272` (≈20 MB): el tamaño real del fichero comprimido en disco.
> - `virtual_size=117440512` (≈112 MB): el tamaño del disco cuando se despliega la imagen.
> - `checksum`: MD5 del fichero. Sirve para verificar que la subida fue correcta.
> - `stores='rbd'`: en este entorno las imágenes se guardan en Ceph (RBD), no en filesystem.

### Listar imágenes

```bat
openstack image list
```

**Salida:**
```
+--------------------------------------+-----------+--------+
| ID                                   | Name      | Status |
+--------------------------------------+-----------+--------+
| da26cf74-6aba-4cbb-9ede-03d0ca378abb | mi-cirros | active |
+--------------------------------------+-----------+--------+
```

---

## 4. Práctica 2 — Subir imagen desde URL remota

### Crear la entrada de imagen (estado queued)

```bat
openstack image create \
  --container-format bare \
  --disk-format qcow2 \
  --private \
  --property os_distro=cirros \
  --property os_version=0.6.2 \
  "mi-cirros-web"
```

**Salida:**
```
+------------------+---------------------------------------------------------------------------------------------------+
| Field            | Value                                                                                             |
+------------------+---------------------------------------------------------------------------------------------------+
| container_format | bare                                                                                              |
| created_at       | 2026-03-17T18:36:27Z                                                                              |
| disk_format      | qcow2                                                                                             |
| file             | /v2/images/71f8f1b5-c581-4adb-a186-7f9f3256b6d5/file                                              |
| id               | 71f8f1b5-c581-4adb-a186-7f9f3256b6d5                                                              |
| min_disk         | 0                                                                                                 |
| min_ram          | 0                                                                                                 |
| name             | mi-cirros-web                                                                                     |
| owner            | 4bf95451094d4f659bfdba7d716c71da                                                                  |
| properties       | os_distro='cirros', os_hidden='False', os_version='0.6.2',                                        |
|                  | owner_specified.openstack.md5='', owner_specified.openstack.object='images/mi-cirros-web',        |
|                  | owner_specified.openstack.sha256=''                                                               |
| protected        | False                                                                                             |
| schema           | /v2/schemas/image                                                                                 |
| status           | queued                                                                                            |
| tags             |                                                                                                   |
| updated_at       | 2026-03-17T18:36:27Z                                                                              |
| visibility       | private                                                                                           |
+------------------+---------------------------------------------------------------------------------------------------+
```

> `status=queued`: la imagen existe en el catálogo pero no tiene datos binarios.
> No se puede lanzar una instancia con ella hasta que tenga datos.

### Lanzar la importación desde URL

```bat
openstack image import \
  --uri http://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img \
  --method web-download \
  mi-cirros-web
```

*(sin salida — el comando dispara la importación y termina)*

> El comando termina enseguida. Glance descarga el fichero en segundo plano.
> Dependiendo del tamaño y la velocidad, puede tardar unos segundos o minutos.

### Comprobar el estado tras la importación

```bat
openstack image show mi-cirros-web -c name -c status -c size
```

**Salida (tras unos segundos):**
```
+--------+---------------+
| Field  | Value         |
+--------+---------------+
| name   | mi-cirros-web |
| size   | 21430272      |
| status | active        |
+--------+---------------+
```

> `status=active` confirma que la importación terminó correctamente.
> El `size` es idéntico al de la imagen subida desde local: misma imagen, distinto método.

### Listar con dos imágenes

```bat
openstack image list
```

**Salida:**
```
+--------------------------------------+---------------+--------+
| ID                                   | Name          | Status |
+--------------------------------------+---------------+--------+
| da26cf74-6aba-4cbb-9ede-03d0ca378abb | mi-cirros     | active |
| 71f8f1b5-c581-4adb-a186-7f9f3256b6d5 | mi-cirros-web | active |
+--------------------------------------+---------------+--------+
```

---

## 5. Práctica 3 — Metadatos, etiquetas y visibilidad

### Añadir etiquetas

```bat
openstack image set --tag lab --tag cirros mi-cirros
openstack image show mi-cirros -c name -c tags
```

**Salida:**
```
+-------+-----------+
| Field | Value     |
+-------+-----------+
| name  | mi-cirros |
| tags  | cirros, lab |
+-------+-----------+
```

### Cambiar visibilidad a community

```bat
openstack image set --community mi-cirros
openstack image show mi-cirros -c name -c visibility -c status
```

**Salida:**
```
+------------+-----------+
| Field      | Value     |
+------------+-----------+
| name       | mi-cirros |
| status     | active    |
| visibility | community |
+------------+-----------+
```

> Con `community`, todos los proyectos del cloud pueden ver y usar esta imagen.
> A diferencia de `public`, no requiere permisos de admin para asignarla.

### Volver a private

```bat
openstack image set --private mi-cirros
openstack image show mi-cirros -c name -c visibility
```

**Salida:**
```
+------------+-----------+
| Field      | Value     |
+------------+-----------+
| name       | mi-cirros |
| visibility | private   |
+------------+-----------+
```

---

## 6. Práctica 4 — Protección, desactivación y borrado

### Proteger una imagen

```bat
openstack image set --protected mi-cirros
openstack image show mi-cirros -c name -c protected
```

**Salida:**
```
+-----------+-----------+
| Field     | Value     |
+-----------+-----------+
| name      | mi-cirros |
| protected | True      |
+-----------+-----------+
```

### Intentar borrar imagen protegida

```bat
openstack image delete mi-cirros
```

**Salida:**
```
Failed to delete image with name or ID 'mi-cirros': ForbiddenException: 403:
Client Error for url: https://glance.ivanosuna.com/v2/images/da26cf74-6aba-4cbb-9ede-03d0ca378abb,
403 Forbidden: Image da26cf74-6aba-4cbb-9ede-03d0ca378abb is protected and cannot be deleted.
Failed to delete 1 of 1 images.
```

> Error 403 Forbidden. Glance rechaza el borrado. Hay que desproteger primero.
> Este mecanismo protege imágenes de producción de borrados accidentales.

### Desactivar una imagen

```bat
openstack image set --deactivate mi-cirros
openstack image show mi-cirros -c name -c status
```

**Salida:**
```
+--------+---------------------+
| Field  | Value               |
+--------+---------------------+
| name   | mi-cirros           |
| status | deactivated         |
+--------+---------------------+
```

> `deactivated`: la imagen existe pero no se puede usar para lanzar instancias.
> Nova rechazará cualquier intento de lanzar una VM con esta imagen.
> No se pierden los datos: la imagen sigue almacenada en Ceph.

### Reactivar la imagen

```bat
openstack image set --activate mi-cirros
openstack image show mi-cirros -c name -c status
```

**Salida:**
```
+--------+-----------+
| Field  | Value     |
+--------+-----------+
| name   | mi-cirros |
| status | active    |
+--------+-----------+
```

### Descargar una imagen

```bat
openstack image save --file cirros-backup.img mi-cirros
ls -lh cirros-backup.img
```

**Salida:**
```
-rw-r--r-- 1 usuario usuario 20M mar 17 19:35 cirros-backup.img
```

> El fichero descargado tiene el mismo tamaño que el original subido (≈20 MB).
> Para verificar integridad: `md5sum cirros-backup.img` debe dar `c8fc807773e5354afe61636071771906`.

### Borrar ambas imágenes

```bat
openstack image set --unprotected mi-cirros
openstack image delete mi-cirros mi-cirros-web
```

*(sin salida — significa que el borrado fue exitoso)*

```bat
openstack image list
```

**Salida:**
```
(sin salida — no quedan imágenes)
```

---

## Resumen de estados de una imagen

| Estado | Significado |
|---|---|
| `queued` | Registrada en el catálogo pero sin datos binarios |
| `saving` | Subiendo datos (solo durante la subida directa) |
| `active` | Datos subidos y disponible para usar |
| `deactivated` | Existe pero no se puede usar para lanzar instancias |
| `killed` | Error durante la subida — imagen no usable |
| `deleted` | Marcada para borrado (puede estar en proceso de limpieza) |

---

## Respuestas a las preguntas

**Práctica 1:**

1. `status=active` significa que la imagen tiene datos y está lista para lanzar VMs. Otros estados: `queued` (sin datos), `saving` (subiendo), `deactivated` (bloqueada), `killed` (error).
2. `size` es el tamaño real del fichero almacenado (el qcow2 comprimido, ≈20 MB). `virtual_size` es el tamaño del disco virtual que ve la VM al arrancar (el disco "desenrollado", ≈112 MB). Son distintos porque qcow2 usa thin provisioning: solo ocupa lo que tiene datos reales.
3. El `owner` es el ID del proyecto que la subió. Solo ese proyecto puede borrarla o cambiar su visibilidad (salvo admins).

**Práctica 2:**

1. `web-download` evita que el fichero pase por tu máquina: si tienes una imagen de 10 GB, no tienes que descargarla y volver a subirla. Glance la descarga directamente desde el origen. Más rápido y sin consumo de ancho de banda local.
2. Si la URL no es accesible desde el servidor de Glance, la importación falla y la imagen queda en `queued` o `killed`. Glance descarga desde su red, no desde la tuya.
3. La URL debe ser accesible desde la red del servidor de Glance (HTTP/HTTPS público). Depende de la conectividad del servidor OpenStack, no de la tuya.

**Práctica 3:**

1. Un `tag` es una etiqueta sin valor (solo nombre), útil para clasificación rápida y filtrado. Una `property` es un par clave=valor con información más detallada (metadatos). Los tags son más visibles en los listados; las properties se muestran juntas en el campo `properties`.
2. Necesitas `--community` o `--public`. `community` lo puede hacer cualquier usuario sobre su propia imagen; `public` solo lo puede hacer un admin global.
3. No. Solo el admin del cloud puede marcar imágenes como `public`. Un usuario normal puede marcarlas como `community` o `shared`.

**Práctica 4:**

1. `--deactivate` es útil cuando detectas un problema en una imagen (vulnerabilidad de seguridad, corrupción) pero no quieres borrarla porque puede estar en uso o necesitas investigarla primero. El borrado es irreversible; la desactivación no.
2. Nada. Las instancias ya lanzadas no dependen de la imagen original: cuando Nova lanza una VM, copia (o enlaza) los datos de la imagen al volumen de boot de la instancia. Borrar la imagen Glance no afecta a instancias en ejecución.
3. Sí. Proteger evita borrados accidentales. En producción, las imágenes base del sistema deberían estar siempre protegidas. El flujo correcto para retirarlas sería: desactivar → verificar que nadie la usa → desproteger → borrar.
