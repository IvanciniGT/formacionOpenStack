# Prácticas de Glance — Servicio de imágenes

## Objetivo

En estas prácticas vas a:

- entender qué es Glance y para qué sirve en OpenStack
- listar y explorar imágenes disponibles
- subir una imagen desde tu máquina y desde una URL remota
- gestionar metadatos, etiquetas y visibilidad
- entender los estados de una imagen
- proteger y borrar imágenes

## ¿Qué es Glance?

Glance es el servicio de **catálogo de imágenes** de OpenStack.
Almacena y sirve las imágenes de disco que se usan para lanzar máquinas virtuales.

Una imagen en Glance es básicamente:
- los **datos binarios** del disco (el fichero `.img`, `.qcow2`, `.iso`...)
- los **metadatos** que describen la imagen (SO, arquitectura, tamaño mínimo...)

> Glance no ejecuta nada — solo almacena imágenes y las sirve a Nova (el servicio
> de cómputo) cuando alguien lanza una instancia. Sin Glance, no hay VMs.

## Formatos que debes conocer

| Formato disco | Descripción |
|---|---|
| `qcow2` | QEMU/KVM. El más habitual en OpenStack. Soporte thin provisioning y snapshots. |
| `raw` | Imagen sin compresión. Más rápida de leer pero ocupa más espacio. |
| `vmdk` | VMware. Se puede importar pero no es el nativo de KVM. |
| `iso` | Imagen de CD/DVD. Para instalaciones, no para instancias directas. |

| Formato contenedor | Descripción |
|---|---|
| `bare` | Sin contenedor, solo el disco. El más habitual. |
| `ovf` | Formato OVF/OVA de VMware. |

## Tu contexto en este laboratorio

Cada alumno tiene:
- acceso para **ver imágenes públicas o de comunidad** del entorno
- permisos para **subir imágenes privadas** en su proyecto
- sin permisos para modificar imágenes de otros proyectos

---

# 1. Preparación del entorno

## 1.1 Activar entorno y cargar credenciales

```bat
rem Activa el entorno virtual donde instalaste python-openstackclient.
%USERPROFILE%\openstack-client\Scripts\activate

rem Configura tus credenciales. Sustituye <tu_password> por tu contraseña.
set OS_AUTH_URL=https://keystone.ivanosuna.com/v3
set OS_IDENTITY_API_VERSION=3
set OS_USERNAME=alumno1
set OS_PASSWORD=<tu_password>
set OS_PROJECT_NAME=proyecto-alumno1
set OS_USER_DOMAIN_NAME=dominio-alumno1
set OS_PROJECT_DOMAIN_NAME=dominio-alumno1

openstack token issue
```

## 1.2 Comprobar que Glance está disponible

```bat
rem Busca "glance" o "image" en el catálogo.
rem La URL pública es la que usa la CLI para todas las operaciones de imagen.
openstack catalog show image
```

---

# 2. Explorar imágenes existentes

## 2.1 Listar imágenes

```bat
rem Lista las imágenes accesibles desde tu proyecto.
rem Por defecto muestra: imágenes privadas tuyas + públicas/community del entorno.
openstack image list
```

## 2.2 Listar imágenes con detalles

```bat
rem --long muestra: tamaño, checksum, visibilidad, si está protegida, tags, propietario...
rem Puede ser una tabla muy ancha. Útil para auditar el catálogo.
openstack image list --long
```

## 2.3 Filtrar por visibilidad

```bat
rem Solo tus imágenes privadas (las que has subido tú).
openstack image list --private

rem Solo imágenes de comunidad (visibles por todos, sin ser públicas).
openstack image list --community

rem Solo imágenes marcadas como "public" (visibles para todo el mundo).
openstack image list --public

rem Solo las imágenes compartidas contigo desde otro proyecto.
openstack image list --shared
```

## 2.4 Filtrar por estado

```bat
rem "active" significa que la imagen está lista para usar.
rem Otros estados: queued (sin datos), saving (subiéndose), deactivated, deleted.
openstack image list --status active
```

## 2.5 Ver detalles de una imagen

Si hay alguna imagen en el listado, muestra sus detalles:

```bat
rem Sustituye <nombre-o-id> por el nombre o UUID de la imagen.
rem Campos clave: status, visibility, size, disk_format, checksum, protected.
openstack image show <nombre-o-id>
```

---

# 3. Práctica 1 — Subir una imagen desde fichero

## Objetivo

Subir tu propia imagen a Glance.

## 3.1 Descargar una imagen de prueba

Vamos a usar **Cirros**: una imagen Linux mínima (~20 MB) pensada exactamente para
probar OpenStack. No sirve para producción, pero es perfecta para aprender.

En Linux/macOS:
```bash
curl -L http://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img \
     -o cirros.img
ls -lh cirros.img
```

En Windows (PowerShell):
```powershell
Invoke-WebRequest -Uri http://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img `
                  -OutFile cirros.img
dir cirros.img
```

## 3.2 Subir la imagen

```bat
rem Crea la imagen en Glance y sube los datos en un solo paso.
rem --container-format bare: sin contenedor, solo el disco.
rem --disk-format qcow2: formato QEMU/KVM.
rem --file cirros.img: el fichero local a subir.
rem --private: solo visible en tu proyecto (la opción por defecto, pero conviene ser explícito).
rem --min-disk 1: requiere al menos 1 GB de disco para lanzarla.
rem --min-ram 64: requiere al menos 64 MB de RAM.
rem --property os_distro=cirros: metadato estándar del sistema operativo.
rem --property os_version=0.6.2: metadato estándar de la versión.
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

> **Nota Windows:** en CMD no funcionan los saltos de línea con `\`.
> Escribe el comando todo en una sola línea.

## 3.3 Verificar la subida

```bat
rem Muestra los detalles de la imagen recién creada.
rem status=active significa que la subida fue exitosa y la imagen está lista.
rem size es el tamaño en bytes del fichero subido.
rem checksum es el MD5 del fichero: puedes compararlo con el original para verificar integridad.
openstack image show mi-cirros
```

## 3.4 Listar imágenes ahora

```bat
openstack image list
```

## Preguntas

1. ¿Qué significa `status=active`? ¿Qué otros estados puede tener una imagen?
2. ¿Cuál es la diferencia entre `size` y `virtual_size`?
3. ¿Quién es el `owner` de la imagen?

---

# 4. Práctica 2 — Subir imagen desde URL remota

## Objetivo

Subir una imagen directamente desde una URL, sin descargarla localmente.
Glance lo descarga él solo desde Internet.

Este método se llama **web-download** y es útil cuando el fichero es grande
o no quieres ocupar espacio local.

## Pasos

### 4.1 Crear la entrada de imagen

```bat
rem Primero creamos la "ficha" de la imagen en Glance (sin datos aún).
rem status será "queued": la imagen existe pero no tiene datos.
openstack image create \
  --container-format bare \
  --disk-format qcow2 \
  --private \
  --property os_distro=cirros \
  --property os_version=0.6.2 \
  "mi-cirros-web"
```

### 4.2 Verificar que está en estado queued

```bat
openstack image show mi-cirros-web
```

> `status=queued` significa que la imagen existe en el catálogo pero no tiene
> datos binarios todavía. No se puede lanzar una instancia con ella aún.

### 4.3 Lanzar la importación desde URL

```bat
rem --uri: URL pública del fichero de imagen.
rem --method web-download: Glance lo descarga directamente desde esa URL.
rem Glance hace la descarga en segundo plano. El comando termina enseguida.
openstack image import \
  --uri http://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img \
  --method web-download \
  mi-cirros-web
```

### 4.4 Comprobar el estado

```bat
rem Espera unos segundos y comprueba que el estado cambió a "active".
openstack image show mi-cirros-web
```

## Ver métodos de importación disponibles

```bat
rem Muestra qué métodos de importación soporta este Glance.
rem copy-image: copiar desde otro store, glance-direct: subida directa, web-download: desde URL.
openstack image import info
```

## Preguntas

1. ¿Qué ventaja tiene `web-download` respecto a subir el fichero desde local?
2. ¿Qué ocurre si la URL no es accesible desde el servidor de Glance?
3. ¿Puedes usar `web-download` con cualquier URL? ¿Depende de algo?

---

# 5. Práctica 3 — Metadatos, etiquetas y visibilidad

## Objetivo

Gestionar los metadatos de una imagen existente.

## 5.1 Añadir etiquetas

```bat
rem Las etiquetas (tags) son etiquetas libres para clasificar imágenes.
rem Puedes añadir varias con --tag repetido.
rem Son distintas de las propiedades (--property): los tags no tienen valor, solo nombre.
openstack image set --tag lab --tag cirros mi-cirros
openstack image show mi-cirros -c name -c tags
```

## 5.2 Añadir propiedades personalizadas

```bat
rem Las propiedades son pares clave=valor más descriptivos que los tags.
rem Hay propiedades estándar de OpenStack (os_distro, os_version, architecture...)
rem y puedes añadir las tuyas propias.
openstack image set --property arquitectura=x86_64 --property uso=lab mi-cirros
openstack image show mi-cirros -c name -c properties
```

## 5.3 Cambiar la visibilidad

```bat
rem "community": visible para todos los proyectos pero no requiere compartir explícitamente.
rem Es como "public" pero más suave: aparece en los listados de la comunidad.
openstack image set --community mi-cirros
openstack image show mi-cirros -c name -c visibility

rem Vuelve a private:
openstack image set --private mi-cirros
openstack image show mi-cirros -c name -c visibility
```

> Los niveles de visibilidad en Glance son:
> - `private`: solo tu proyecto
> - `shared`: comparte con proyectos específicos
> - `community`: todos pueden verla (sin confirmación explícita)
> - `public`: solo el admin puede marcar imágenes como públicas

## 5.4 Filtrar por nombre

```bat
rem Filtra imágenes cuyo nombre contiene "cirros".
openstack image list --name cirros
```

## Preguntas

1. ¿Cuál es la diferencia entre un `tag` y una `property` en Glance?
2. ¿Qué visibilidad necesitas para que todos los alumnos puedan ver tu imagen?
3. ¿Puede cualquier usuario marcar una imagen como `public`?

---

# 6. Práctica 4 — Protección, desactivación y borrado

## Objetivo

Controlar el ciclo de vida de una imagen.

## 6.1 Proteger una imagen

```bat
rem Una imagen protegida no se puede borrar hasta que se desproteja.
rem Útil para imágenes de producción que no quieres borrar accidentalmente.
openstack image set --protected mi-cirros
openstack image show mi-cirros -c name -c protected
```

## 6.2 Intentar borrar una imagen protegida

```bat
rem Esto debería fallar con error 403.
rem Glance rechaza el borrado de imágenes protegidas.
openstack image delete mi-cirros
```

## 6.3 Desactivar una imagen

```bat
rem Una imagen desactivada sigue existiendo pero no se puede usar para lanzar instancias.
rem status pasará de "active" a "deactivated".
rem Útil para retirar una imagen temporalmente sin borrarla.
openstack image set --deactivate mi-cirros
openstack image show mi-cirros -c name -c status
```

## 6.4 Reactivar la imagen

```bat
rem Vuelve la imagen al estado "active".
openstack image set --activate mi-cirros
openstack image show mi-cirros -c name -c status
```

## 6.5 Descargar una imagen

```bat
rem Descarga los datos binarios de la imagen a un fichero local.
rem --file: nombre del fichero destino.
rem Útil para hacer backups o para migrar imágenes entre entornos.
openstack image save --file cirros-backup.img mi-cirros
ls -lh cirros-backup.img
```

## 6.6 Borrar las imágenes

```bat
rem Primero desprotege:
openstack image set --unprotected mi-cirros

rem Ahora borra. Puedes borrar varias a la vez pasando varios nombres o IDs.
openstack image delete mi-cirros mi-cirros-web

rem Verifica que ya no existen:
openstack image list
```

## Preguntas

1. ¿En qué casos usarías `--deactivate` en vez de borrar la imagen directamente?
2. ¿Qué ocurre con las instancias que están corriendo si borras la imagen con la que se lanzaron?
3. ¿Tiene sentido proteger imágenes de producción? ¿Qué ventaja tiene?

---

# 7. Resumen de comandos

| Operación | Comando |
|---|---|
| Listar imágenes | `openstack image list` |
| Listar con detalles | `openstack image list --long` |
| Filtrar privadas | `openstack image list --private` |
| Filtrar por estado | `openstack image list --status active` |
| Ver imagen | `openstack image show <imagen>` |
| Crear/subir imagen | `openstack image create --file <f> --disk-format qcow2 --container-format bare <nombre>` |
| Importar desde URL | `openstack image import --uri <url> --method web-download <imagen>` |
| Ver métodos import | `openstack image import info` |
| Añadir tag | `openstack image set --tag <tag> <imagen>` |
| Añadir propiedad | `openstack image set --property clave=valor <imagen>` |
| Cambiar visibilidad | `openstack image set --private/--community/--shared <imagen>` |
| Proteger | `openstack image set --protected <imagen>` |
| Desproteger | `openstack image set --unprotected <imagen>` |
| Desactivar | `openstack image set --deactivate <imagen>` |
| Reactivar | `openstack image set --activate <imagen>` |
| Descargar imagen | `openstack image save --file <destino> <imagen>` |
| Borrar imagen | `openstack image delete <imagen>` |
