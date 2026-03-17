# Respuestas del lab — Prácticas de Swift

> Ejecutado con el usuario **profesor** contra `https://swift.ivanosuna.com`  
> Fecha: 17 de marzo de 2026 — Cliente: openstack 9.0.0

---

## 1. Preparación del entorno

### Comprobar que Swift está disponible

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
|           |              |   public: https://glance.ivanosuna.com            |
|           |              |                                                   |
| swift     | object-store | RegionOne                                         |
|           |              |   internal: https://swift.ivanosuna.com/swift/v1/ |
|           |              | AUTH_4bf95451094d4f659bfdba7d716c71da             |
|           |              |   public: https://swift.ivanosuna.com/swift/v1/   |
|           |              | AUTH_4bf95451094d4f659bfdba7d716c71da             |
|           |              |   admin: https://swift.ivanosuna.com/swift/v1/    |
|           |              | AUTH_4bf95451094d4f659bfdba7d716c71da             |
|           |              |                                                   |
| keystone  | identity     | RegionOne                                         |
|           |              |   public: https://keystone.ivanosuna.com/v3       |
|           |              |   admin: https://keystone.ivanosuna.com/v3        |
|           |              |                                                   |
+-----------+--------------+---------------------------------------------------+
```

> La URL de Swift incluye tu `AUTH_<project_id>`. OpenStack la personaliza
> al autenticarte: cada usuario recibe una URL que apunta a su propio espacio.

### Ver el estado de la cuenta

```bat
openstack object store account show
```

**Salida (cuenta vacía al inicio):**
```
+------------+---------------------------------------+
| Field      | Value                                 |
+------------+---------------------------------------+
| Account    | AUTH_4bf95451094d4f659bfdba7d716c71da |
| Bytes      | 0                                     |
| Containers | 0                                     |
| Objects    | 0                                     |
| properties | Quota-Containers='1000'               |
+------------+---------------------------------------+
```

> `Account` es el identificador de tu espacio en Swift. Siempre es `AUTH_` seguido
> del ID de tu proyecto. La quota de contenedores en este entorno es de 1000.

---

## 2. Trabajar con contenedores

### Listar contenedores (vacío al inicio)

```bat
openstack container list
```

**Salida:**
```
(sin salida — la cuenta está vacía)
```

### Crear un contenedor

```bat
openstack container create mis-documentos
```

**Salida:**
```
+---------------------------------------+----------------+------------------------------------------------------+
| account                               | container      | x-trans-id                                           |
+---------------------------------------+----------------+------------------------------------------------------+
| AUTH_4bf95451094d4f659bfdba7d716c71da | mis-documentos | tx00000a9ed67949aa3a9ea-0069b99e24-71854-swift-store |
+---------------------------------------+----------------+------------------------------------------------------+
```

> `x-trans-id` es el identificador de la transacción. Útil para depurar si algo
> falla: con este ID los administradores pueden rastrear la operación en los logs.

### Ver detalles del contenedor

```bat
openstack container show mis-documentos
```

**Salida (recién creado, vacío):**
```
+----------------+---------------------------------------+
| Field          | Value                                 |
+----------------+---------------------------------------+
| account        | AUTH_4bf95451094d4f659bfdba7d716c71da |
| bytes_used     | 0                                     |
| container      | mis-documentos                        |
| object_count   | 0                                     |
| storage_policy | default-placement                     |
+----------------+---------------------------------------+
```

### Crear segundo contenedor y listar

```bat
openstack container create mis-backups
openstack container list
```

**Salida:**
```
+----------------+
| Name           |
+----------------+
| mis-backups    |
| mis-documentos |
+----------------+
```

> Los contenedores se listan en orden alfabético.

---

## 3. Práctica 1 — Subir y gestionar objetos

### Subir objetos

```bat
openstack object create mis-documentos nota.txt
```

**Salida:**
```
+----------+----------------+----------------------------------+
| object   | container      | etag                             |
+----------+----------------+----------------------------------+
| nota.txt | mis-documentos | bcdce838c35417cbf614b9e5148c94a7 |
+----------+----------------+----------------------------------+
```

> El `etag` es el hash MD5 del contenido del fichero. Sirve para verificar
> que la subida fue correcta y que el fichero no se corrompió en el camino.

```bat
openstack object create mis-documentos config.ini
```

**Salida:**
```
+------------+----------------+----------------------------------+
| object     | container      | etag                             |
+------------+----------------+----------------------------------+
| config.ini | mis-documentos | 99c9d51d18f44ae19e06b734adaf69eb |
+------------+----------------+----------------------------------+
```

### Listar objetos

```bat
openstack object list mis-documentos
```

**Salida:**
```
+------------+
| Name       |
+------------+
| config.ini |
| nota.txt   |
+------------+
```

### Listar con detalles

```bat
openstack object list mis-documentos --long
```

**Salida:**
```
+-------------+-------+----------------------------------+----------------+--------------------------+
| Name        | Bytes | Hash                             | Content Type   | Last Modified            |
+-------------+-------+----------------------------------+----------------+--------------------------+
| config.ini  |    47 | 99c9d51d18f44ae19e06b734adaf69eb |                | 2026-03-17T18:32:56.444Z |
| nota.txt    |    32 | bcdce838c35417cbf614b9e5148c94a7 | text/plain     | 2026-03-17T18:32:37.492Z |
+-------------+-------+----------------------------------+----------------+--------------------------+
```

> El campo `Content Type` puede quedar vacío si Swift no detecta el tipo
> automáticamente. `text/plain` se detecta porque la extensión `.txt` es conocida.

### Ver detalles de un objeto

```bat
openstack object show mis-documentos nota.txt
```

**Salida:**
```
+----------------+---------------------------------------+
| Field          | Value                                 |
+----------------+---------------------------------------+
| account        | AUTH_4bf95451094d4f659bfdba7d716c71da |
| container      | mis-documentos                        |
| content-length | 32                                    |
| content-type   | text/plain                            |
| etag           | bcdce838c35417cbf614b9e5148c94a7      |
| last-modified  | Tue, 17 Mar 2026 18:32:37 GMT         |
| object         | nota.txt                              |
+----------------+---------------------------------------+
```

### Estado de la cuenta con objetos

```bat
openstack object store account show
```

**Salida:**
```
+------------+---------------------------------------+
| Field      | Value                                 |
+------------+---------------------------------------+
| Account    | AUTH_4bf95451094d4f659bfdba7d716c71da |
| Bytes      | 79                                    |
| Containers | 1                                     |
| Objects    | 2                                     |
| properties | Quota-Containers='1000'               |
+------------+---------------------------------------+
```

> 79 bytes = 32 (nota.txt) + 47 (config.ini). Swift actualiza la cuenta en tiempo real.

### Descargar un objeto

```bat
openstack object save mis-documentos nota.txt --file nota-descargada.txt
cat nota-descargada.txt
```

**Salida:**
```
Hola OpenStack, almacenamiento de objetos
```

> El objeto se descarga íntegro. Si quieres verificar integridad, calcula el MD5
> del fichero descargado y compáralo con el `etag`:
> `md5sum nota-descargada.txt` (Linux) o `certutil -hashfile nota-descargada.txt MD5` (Windows)

---

## 4. Práctica 2 — Metadatos de objetos y contenedores

### Añadir metadatos a un objeto

```bat
openstack object set --property autor=alumno1 --property tipo=documento mis-documentos nota.txt
```

*(sin salida — significa que se aplicó correctamente)*

### Ver objeto con metadatos

```bat
openstack object show mis-documentos nota.txt
```

**Salida:**
```
+----------------+------------------------------------------+
| Field          | Value                                    |
+----------------+------------------------------------------+
| account        | AUTH_4bf95451094d4f659bfdba7d716c71da    |
| container      | mis-documentos                           |
| content-length | 32                                       |
| content-type   | text/plain                               |
| etag           | bcdce838c35417cbf614b9e5148c94a7         |
| last-modified  | Tue, 17 Mar 2026 18:32:37 GMT            |
| object         | nota.txt                                 |
| properties     | Autor='alumno1', Tipo='documento'        |
+----------------+------------------------------------------+
```

> Fíjate: las claves se normalizan con la primera letra en mayúscula
> (`autor` → `Autor`). El contenido del objeto no cambia al añadir metadatos.

### Añadir metadatos al contenedor

```bat
openstack container set --property proyecto=practicas --property entorno=lab mis-documentos
openstack container show mis-documentos
```

**Salida:**
```
+----------------+------------------------------------------+
| Field          | Value                                    |
+----------------+------------------------------------------+
| account        | AUTH_4bf95451094d4f659bfdba7d716c71da    |
| bytes_used     | 79                                       |
| container      | mis-documentos                           |
| object_count   | 2                                        |
| properties     | Entorno='lab', Proyecto='practicas'      |
| storage_policy | default-placement                        |
+----------------+------------------------------------------+
```

---

## 5. Práctica 3 — Control de acceso (ACL)

### Ver ACL actual (sin ACL → privado)

```bat
openstack container show mis-documentos
```

> Si no aparece `X-Container-Read` en `properties`, el contenedor es privado.
> Solo tú (con tu token) puedes acceder.

### Hacer el contenedor público

```bat
openstack container set --property 'X-Container-Read=.r:*,.rlistings' mis-documentos
openstack container show mis-documentos
```

**Salida:**
```
+----------------+------------------------------------------+
| Field          | Value                                    |
+----------------+------------------------------------------+
| account        | AUTH_4bf95451094d4f659bfdba7d716c71da    |
| bytes_used     | 79                                       |
| container      | mis-documentos                           |
| object_count   | 2                                        |
| properties     | Entorno='lab', Proyecto='practicas',     |
|                | X-Container-Read='.r:*,.rlistings'       |
| storage_policy | default-placement                        |
+----------------+------------------------------------------+
```

> **Importante:** aunque la ACL permite acceso público, el proxy de Swift
> puede estar configurado con restricciones adicionales. En este entorno,
> el acceso anónimo está bloqueado en la capa de proxy/red.
> El comando funciona correctamente — es la infraestructura quien restringe el acceso anónimo.

### Quitar la ACL pública

```bat
openstack container unset --property X-Container-Read mis-documentos
openstack container show mis-documentos
```

**Salida:**
```
+----------------+---------------------------------------+
| Field          | Value                                 |
+----------------+---------------------------------------+
| account        | AUTH_4bf95451094d4f659bfdba7d716c71da |
| bytes_used     | 79                                    |
| container      | mis-documentos                        |
| object_count   | 2                                     |
| properties     | Entorno='lab', Proyecto='practicas'   |
| storage_policy | default-placement                     |
+----------------+---------------------------------------+
```

> `X-Container-Read` ha desaparecido → el contenedor vuelve a ser privado.

---

## 6. Práctica 4 — Borrar objetos y contenedores

### Borrar un objeto

```bat
openstack object delete mis-documentos config.ini
openstack object list mis-documentos
```

**Salida:**
```
+----------+
| Name     |
+----------+
| nota.txt |
+----------+
```

### Intentar borrar contenedor no vacío

```bat
openstack container delete mis-documentos
```

**Salida:**
```
Failed to delete container with name or ID 'mis-documentos': ConflictException: 409:
Client Error for url: https://swift.ivanosuna.com/swift/v1/AUTH_.../mis-documentos,
There was a conflict when trying to complete your request.
Failed to delete 1 of 1 containers.
```

> Error 409 Conflict: el contenedor tiene objetos dentro.
> Swift protege los datos exigiendo que vacíes el contenedor antes de borrarlo.

### Vaciar y borrar correctamente

```bat
openstack object delete mis-documentos nota.txt
openstack container delete mis-documentos
openstack container delete mis-backups
openstack container list
```

**Salida:**
```
(sin salida — no hay contenedores)
```

```bat
openstack object store account show
```

**Salida:**
```
+------------+---------------------------------------+
| Field      | Value                                 |
+------------+---------------------------------------+
| Account    | AUTH_4bf95451094d4f659bfdba7d716c71da |
| Bytes      | 0                                     |
| Containers | 0                                     |
| Objects    | 0                                     |
| properties | Quota-Containers='1000'               |
+------------+---------------------------------------+
```

> Todo limpio. `Bytes=0`, `Containers=0`, `Objects=0`.

---

## Respuestas a las preguntas

**Práctica 1:**

1. El `etag` es el MD5 del contenido. Sirve para detectar corrupciones o verificar que dos objetos tienen el mismo contenido. Si el MD5 del fichero descargado coincide con el `etag`, la descarga fue perfecta.
2. Sí, puedes subir el mismo objeto dos veces. Swift lo sobreescribe silenciosamente. No hay versiones (a menos que habilites versionado en el contenedor).
3. Un objeto Swift es inmutable una vez creado: no puedes editarlo parcialmente, solo reemplazarlo completo. No hay rutas reales ni permisos de sistema de ficheros. Los metadatos viajan con el objeto.

**Práctica 2:**

1. Los metadatos se almacenan en el servidor de Swift asociados al objeto o al contenedor. No se guardan en el fichero local.
2. La API de Swift permite buscar por metadatos usando peticiones HTTP directas, pero la CLI de OpenStack no tiene un comando de búsqueda por metadatos. Se necesita listar y filtrar manualmente.
3. Clasifar objetos por versión, autor, estado, tipo... sin necesidad de organizar en carpetas. Útil para pipelines de procesamiento, auditoría o ciclos de vida.

**Práctica 3:**

1. Contenido estático de web (HTML, imágenes, CSS, JS), backups públicos, archivos de distribución de software.
2. `.r:*` permite descargar objetos individuales sin autenticación. `.rlistings` permite además listar el contenido del contenedor. Sin `.rlistings`, alguien puede descargar un objeto si conoce su nombre, pero no puede descubrir qué hay en el contenedor.
3. Cambiarías `.r:*` por el ID del proyecto autorizado: `AUTH_<project_id>`.

**Práctica 4:**

1. Para evitar pérdidas accidentales de datos. Un borrado en cascada silencioso sería peligroso en producción.
2. Con la herramienta `swift` (cliente nativo) que tiene `--delete-all`. Con la CLI de OpenStack habría que listar y borrar en bucle desde un script.
3. Se obtiene un error 404 Not Found.
