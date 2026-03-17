# Prácticas de Swift — Almacenamiento de objetos

## Objetivo

En estas prácticas vas a:

- entender qué es el almacenamiento de objetos y en qué se diferencia del de ficheros
- trabajar con contenedores y objetos desde la CLI
- subir, descargar y borrar objetos
- añadir metadatos a objetos y contenedores
- controlar la visibilidad de un contenedor (privado vs público)

## ¿Qué es Swift?

Swift es el servicio de **almacenamiento de objetos** de OpenStack.
No es un sistema de ficheros: no hay directorios ni rutas reales.
La estructura es plana:

```
cuenta  →  contenedor  →  objeto
```

- **Cuenta**: tu espacio de almacenamiento (ligado a tu proyecto).
- **Contenedor**: como un "bucket" o carpeta de primer nivel. Agrupa objetos.
- **Objeto**: cualquier fichero con sus datos y sus metadatos.

> Swift es ideal para almacenar backups, imágenes, logs, ficheros estáticos de
> web, o cualquier cosa que no necesite un sistema de ficheros completo.
> No es bueno para bases de datos ni para acceso de escritura frecuente y concurrente.

## Tu contexto en este laboratorio

Cada alumno tiene:

- una **cuenta** propia en Swift, vinculada a su proyecto (`AUTH_<project_id>`)
- acceso completo a su propia cuenta
- sin acceso a las cuentas de otros compañeros

---

# 1. Preparación del entorno

## 1.1 Activar entorno y cargar credenciales

```bat
rem Activa el entorno virtual donde instalaste python-openstackclient.
%USERPROFILE%\openstack-client\Scripts\activate

rem Carga tus credenciales. Igual que en los labs anteriores.
call alumno1-openrc.cmd
```

## 1.2 Comprobar que Swift está disponible

Antes de nada, comprueba que el servicio de almacenamiento de objetos está en el catálogo:

```bat
rem Muestra el catálogo de servicios.
rem Busca "swift" o "object-store": esa es la entrada de Swift.
rem La URL pública incluirá AUTH_<tu_project_id>.
openstack catalog list
```

## 1.3 Ver el estado de tu cuenta

```bat
rem Muestra el estado de tu cuenta de almacenamiento:
rem cuántos contenedores tienes, cuántos objetos en total y cuántos bytes usas.
rem "Account" es el identificador de tu espacio: AUTH_<project_id>.
openstack object store account show
```

---

# 2. Trabajar con contenedores

Un contenedor es el nivel de agrupación de Swift. Antes de subir cualquier objeto,
necesitas tener al menos un contenedor.

## 2.1 Listar contenedores

```bat
rem Lista los contenedores que tienes en tu cuenta.
rem Al principio estará vacío.
openstack container list
```

## 2.2 Crear un contenedor

```bat
rem Crea un contenedor llamado "mis-documentos".
rem No requiere ninguna opción adicional: el nombre es suficiente.
rem El contenedor se crea en tu cuenta (proyecto actual).
openstack container create mis-documentos
```

## 2.3 Ver detalles del contenedor

```bat
rem Muestra el estado del contenedor: cuántos objetos tiene, cuántos bytes
rem y la política de almacenamiento ("storage_policy").
rem Si acabas de crearlo, estará vacío.
openstack container show mis-documentos
```

## 2.4 Crear un segundo contenedor

```bat
rem Crea otro contenedor. Los contenedores son gratuitos de crear
rem (hasta el límite de tu quota, normalmente 1000).
openstack container create mis-backups
```

## 2.5 Listar todos los contenedores

```bat
rem Ahora deberías ver los dos contenedores que acabas de crear.
openstack container list
```

---

# 3. Práctica 1 — Subir y gestionar objetos

## Objetivo

Subir ficheros a Swift, listarlos y descargarlos.

## 3.1 Preparar ficheros locales

Crea un par de ficheros de prueba en tu terminal:

```bat
rem Crea un fichero de texto. En Windows CMD:
echo Hola OpenStack, almacenamiento de objetos > nota.txt
echo version=1.0, entorno=produccion > config.ini
```

En Linux/macOS:
```bash
echo "Hola OpenStack, almacenamiento de objetos" > nota.txt
echo "version=1.0, entorno=produccion" > config.ini
```

> **Importante:** ejecuta los comandos de Swift **desde el mismo directorio**
> donde están los ficheros. Swift usa el nombre del fichero local como nombre del objeto.

## 3.2 Subir un objeto

```bat
rem Sube "nota.txt" al contenedor "mis-documentos".
rem El nombre del objeto en Swift será "nota.txt" (igual que el fichero local).
rem La salida muestra: nombre del objeto, contenedor y el hash MD5 (etag).
openstack object create mis-documentos nota.txt
```

## 3.3 Subir otro objeto

```bat
rem Sube "config.ini".
openstack object create mis-documentos config.ini
```

## 3.4 Listar objetos del contenedor

```bat
rem Lista todos los objetos del contenedor.
openstack object list mis-documentos
```

## 3.5 Listar con detalles

```bat
rem --long muestra: nombre, tamaño en bytes, hash MD5, Content-Type y fecha de modificación.
rem El hash (etag) es útil para verificar integridad.
openstack object list mis-documentos --long
```

## 3.6 Ver detalles de un objeto

```bat
rem Muestra los metadatos del objeto: tamaño, tipo de contenido, etag, fecha.
rem Aún no lo descarga: solo lee sus metadatos.
openstack object show mis-documentos nota.txt
```

## 3.7 Descargar un objeto

```bat
rem Descarga el objeto y lo guarda en un fichero local.
rem --file indica el nombre del fichero destino en tu máquina.
openstack object save mis-documentos nota.txt --file nota-descargada.txt
```

Verifica que el contenido es correcto:

```bat
rem En Windows:
type nota-descargada.txt

rem En Linux/macOS:
cat nota-descargada.txt
```

## Preguntas

1. ¿Qué información te da el `etag`? ¿Para qué sirve el hash MD5?
2. ¿Puedes subir el mismo objeto dos veces? ¿Qué pasa con el contenido anterior?
3. ¿En qué se diferencia un objeto de un fichero en un sistema de ficheros tradicional?

---

# 4. Práctica 2 — Metadatos de objetos y contenedores

## Objetivo

Swift permite añadir metadatos personalizados (clave=valor) a cualquier objeto
o contenedor. Esto es útil para clasificar contenido sin necesidad de bases de datos externas.

## 4.1 Añadir metadatos a un objeto

```bat
rem Añade propiedades personalizadas al objeto.
rem Pueden ser cualquier clave=valor que necesites.
rem --property puede repetirse para añadir varios metadatos a la vez.
openstack object set --property autor=alumno1 --property tipo=documento mis-documentos nota.txt
```

## 4.2 Verificar metadatos del objeto

```bat
rem Los metadatos aparecerán en el campo "properties" del show.
openstack object show mis-documentos nota.txt
```

## 4.3 Añadir metadatos al contenedor

```bat
rem Los contenedores también admiten propiedades personalizadas.
rem Se usan, por ejemplo, para políticas de acceso o clasificación.
openstack container set --property proyecto=practicas --property entorno=lab mis-documentos
```

## 4.4 Verificar metadatos del contenedor

```bat
openstack container show mis-documentos
```

## Preguntas

1. ¿Dónde se almacenan los metadatos: en el objeto o en el contenedor?
2. ¿Puedes usar metadatos para buscar objetos? ¿Cómo?
3. ¿Qué utilidad práctica tienen los metadatos en un sistema de almacenamiento de objetos?

---

# 5. Práctica 3 — Control de acceso (ACL)

## Objetivo

Controlar quién puede leer los objetos de un contenedor.
Por defecto los contenedores son **privados**: solo tú puedes acceder.
Puedes hacerlos **públicos** para que cualquiera los lea sin autenticación.

> **Aviso:** en este entorno, la política de acceso público puede estar restringida
> por la configuración del proxy de Swift. Ejecuta los comandos y observa qué ocurre.

## 5.1 Ver la ACL actual

Un contenedor recién creado no tiene ACL → es privado.

```bat
rem Muestra los detalles del contenedor.
rem Si no aparece el campo "properties", el contenedor es privado (sin ACL definida).
openstack container show mis-documentos
```

## 5.2 Hacer el contenedor público

```bat
rem X-Container-Read='.r:*,.rlistings' significa:
rem   .r:*         → cualquier petición puede leer objetos (sin token)
rem   .rlistings   → cualquier petición puede listar el contenedor
rem Es la forma estándar de hacer un contenedor completamente público en Swift.
openstack container set --property 'X-Container-Read=.r:*,.rlistings' mis-documentos
```

## 5.3 Verificar la ACL

```bat
openstack container show mis-documentos
```

Ahora el campo `properties` debería mostrar `X-Container-Read='.r:*,.rlistings'`.

## 5.4 Obtener la URL pública de tu objeto

Tu URL pública tiene esta estructura:

```
https://swift.ivanosuna.com/swift/v1/AUTH_<project_id>/<contenedor>/<objeto>
```

Puedes obtener tu `project_id` así:

```bat
rem El campo "project_id" del token es tu AUTH_<id>.
openstack token issue
```

Y la URL base del servicio:

```bat
rem Busca la línea "public" de swift en el catálogo.
openstack catalog show object-store
```

## 5.5 Quitar el acceso público

```bat
rem Elimina la propiedad X-Container-Read.
rem El contenedor vuelve a ser privado.
openstack container unset --property X-Container-Read mis-documentos
openstack container show mis-documentos
```

## Preguntas

1. ¿Para qué casos tiene sentido un contenedor público?
2. ¿Cuál es la diferencia entre `.r:*` y `.rlistings`?
3. Si quisieras que solo ciertos proyectos puedan leer el contenedor, ¿qué cambiarías en la ACL?

---

# 6. Práctica 4 — Borrar objetos y contenedores

## Objetivo

Limpiar objetos y contenedores. Swift requiere que un contenedor esté vacío
antes de poder borrarlo.

## 6.1 Borrar un objeto individual

```bat
rem Borra el objeto "config.ini" del contenedor.
rem No hay papelera de reciclaje: es inmediato e irreversible.
openstack object delete mis-documentos config.ini
```

## 6.2 Verificar que se ha borrado

```bat
openstack object list mis-documentos
```

## 6.3 Intentar borrar el contenedor con objetos dentro

```bat
rem Esto debería fallar: Swift no borra contenedores no vacíos.
rem El error te explicará que el contenedor no está vacío.
openstack container delete mis-documentos
```

## 6.4 Vaciar y borrar correctamente

```bat
rem Primero borra todos los objetos restantes.
openstack object delete mis-documentos nota.txt

rem Ahora el contenedor está vacío y se puede borrar.
openstack container delete mis-documentos
```

## 6.5 Borrar el segundo contenedor (ya está vacío)

```bat
openstack container delete mis-backups
```

## 6.6 Verificar que todo está limpio

```bat
rem Debe mostrar tabla vacía (sin contenedores).
openstack container list

rem Debe mostrar Containers=0, Objects=0, Bytes=0.
openstack object store account show
```

## Preguntas

1. ¿Por qué Swift obliga a vaciar el contenedor antes de borrarlo?
2. Si tuvieras 10.000 objetos en un contenedor, ¿cómo los borrarías eficientemente?
3. ¿Qué ocurre si intentas descargar un objeto que ya no existe?

---

# 7. Resumen de comandos

| Operación | Comando |
|---|---|
| Estado de la cuenta | `openstack object store account show` |
| Listar contenedores | `openstack container list` |
| Crear contenedor | `openstack container create <nombre>` |
| Ver contenedor | `openstack container show <nombre>` |
| Borrar contenedor | `openstack container delete <nombre>` |
| Subir objeto | `openstack object create <contenedor> <fichero>` |
| Listar objetos | `openstack object list <contenedor>` |
| Listar con detalles | `openstack object list <contenedor> --long` |
| Ver objeto | `openstack object show <contenedor> <objeto>` |
| Descargar objeto | `openstack object save <contenedor> <objeto> --file <destino>` |
| Borrar objeto | `openstack object delete <contenedor> <objeto>` |
| Añadir metadatos | `openstack object set --property clave=valor <contenedor> <objeto>` |
| ACL pública | `openstack container set --property 'X-Container-Read=.r:*,.rlistings' <contenedor>` |
| Quitar ACL | `openstack container unset --property X-Container-Read <contenedor>` |
