
Script para Keystone

1. Crear dominio con un usuario admin                       alumnoX -> dominio-alumnoX-cliente
2. Crear un usuario "manager" para ese dominio              alumnoX-manager
3. Darle role manager para ese dominio
4. Haciamos login con ese usuario y creabamos un proyecyo   alumnoX-proyecto-cliente
5. Con este usuario crear otro:
   alumnox-operador (con role member sobre el proyecto)
5. Con este usuario crear otro:
   alumnox-monitoring (con role reader sobre el proyecto)
6. Hacer login con el usuario operador
7. Acceder al proyecto
    openstack project list                  403 Forbidden   --> GET /v3/projects                Regla en policy bloqueante
    openstack project list --my-proyects                    --> GET /v3/{user_id}/projects      Regla en policy no bloqueante

8. Ver detalles del proyecto:
   openstack project show alumnoX-proyecto-cliente      403 Forbidden  
   ---
   openstack project show <alumnoX-proyecto-cliente-id> 200 OK
    Esos dos van por distintos endpoints. Para uno tenemos acceso en las policies, para el otro no.

---

IDEMPOTENCIA: es la propiedad de una operación que garantiza que el resultado de ejecutar esa operación no depende del estado inicial del sistema.

Si ejecuto el script de creacion y no hay nada, acaberé con todo creado, sin errores, sin problemas.

Si lo ejecuto con todo creado, acabaré con todo creado, sin errores, sin problemas.

Si lo ejecuto con parte creado, acabaré con todo creado, sin errores, sin problemas.

Si lo ejecuto y el usuario operador ya existe, pero tiene role reader y no member, que cuando acabe el script (sin errores) el usuario operador tendrá role member (y se le haya quitado el role reader).

---

HEAT!

Plantilla de recursos con orquetación e idempotencia. Es un servicio de orquestación, que se encarga de crear recursos en el orden correcto, y de manejar dependencias entre ellos... con un lenguaje unificado... válido tanto desde windows, linux, mac... y con idempotencia.
Ese idempotencia es gracias a usar un lenguaje declarativo.

---

YAML es un lenguaje para estructurar datos.
Es una alternativa a XML o JSON.

Lo está petando. Es muy sencillo y va orientado a Seres humanos.


Todo el mundo se está moviendo a YAML:
    Openstack (heat)
    politicas de keystone
    Ansible (Playbooks)
    Kubernetes (manifiestos)
    Helm (charts)
    Red en ubuntu (netplan)
    Docker (docker-compose)
    Gitlab (gitlab-ci) / Github (github actions)

---

# Glance

Imágenes para las máquinas virtuales, máquinas físicas...

## conceptos:

Imagen: es un fichero que contiene el sistema operativo, appliance.

## formatos:
- Formato de la imagen: qcow2, raw, vmdk, vhd, iso...
- Formato del contenedor: "bare", aki, ari, ami...

## Catalogo:

Glance guarda tanto la imagen (fichero) como su metadata (información sobre la imagen, como el formato, el tamaño, etc).
Esto da lugar a que una "Imagen de Glace" pues estar en varios estados:
- La imagen registrada, pero sin fichero (imagen en estado "queued")
- La imagen registrada, con el fichero subido (imagen en estado "active")
- La imagen registrada, con el fichero subido, pero desactivada (imagen en estado "deactivated")
- La imagen registrada, con el fichero subido, pero pero el fichero no funciona. (imagen en estado "killed")

## Visibilidad

Las imágenes las subimos a nivel de proyecto:
- private:              solo el proyecto propietario puede usar la imagen
- shared:               el proyecto propietario puede compartir la imagen con otros proyectos:
                            EXPLICITAMENTE: proyecto A y proyecto B, pero no con otros
- community:            cualquiera del cloud puede usarla, pero no le sale en los listados.
                        debe conocer el id de la imagen para usarla 
- public:               cualquiera del cloud puede usarla, y le sale en los listados de búsqueda.

## Tags

Nos ayudan con los filtros de búsqueda. Son etiquetas que le podemos poner a las imágenes, y luego buscar por ellas.

    so: ubuntu

## Modo protected ON/OFF

Si está activado no se puede borrar la imagen, ni modificar su metadata, ni cambiar su visibilidad. Solo se puede usar para crear instancias.

## Tamaño:

Size: Lo que ocupa el fichero de la imagen (en disco)
Virtual Size: Lo que ocupará la imagen cuando se use para crear una instancia

## Forma de cargar la imagen

- Descarga de la imagen desde URL
- Subir un fichero que yo tengo
- Copiar una imagen que ya tengo en el catálogo (con lo que se reutiliza el mismo fichero, sin ocupar espacio adicional)

## El backend de glance.

Es algo interno.. pero vonviene entenderlo.
Glance es un servicio que gestiona imágenes. Pero esas imágenes se guandan en algun sitio:
- Swift (almacenamiento de objetos ->     ID_DEL_OBJETO -> imagen)
- Cinder (almacenamiento de bloques ->    ID_DEL_BLOQUE -> imagen)

NOTA: A su ver, os recuerdo, que tanto cinder como swift se apoyan en otra herramienta de almacenamiento: Ceph.

    CEPH

        Maquina1                            |           Pools de almacenamiento de Ceph
            HDD1 - OSD1                     |               Cajones/Huecos donde guardo cosas
            HDD2 - OSD2                     |               Estos pools usan OSDs
                                            |
        Maquina2                            |               Un pool tiene PGs (Placement Groups) que se encargan 
            SDD1 - OSD3                     |                   de distribuir los objetos entre los OSDs
            SDD2 - OSD4                     |               Cuando llega un objeto se parte en trozos y cada trozo se manda a un PG
                                            |
        Maquina3                            |               
            HHD1 - OSD5                     |
            NVME1 - OSD6                    |

Montamos servicios por encima de ceph... propios de ceph:
    - CephFS: sistema de archivos distribuido (NFS) --> Pool de almacenamiento de archivos
    - RBD: bloques de almacenamiento (iSCSI)        --> Pool de almacenamiento de bloques
    - RGW: almacenamiento de objetos                --> Pool de almacenamiento de objetos

    Cinder -> RBD               <-        Glance
    Swift ->  RGW               <-
    Manila -> CephFS o RBD

---

# Swift

Swift es el servicio de almacenamiento de objetos de Openstack.

Lo que creamos en swift son CONTENEDORES, y dentro de cada contenedor podemos guardar OBJETOS.
Pensad en un contenedor como si fuera una carpeta, y en los objetos como si fueran archivos dentro de esa carpeta.

No tengo estructura jerárquica, no tengo subcarpetas... tengo contenedores, donde pongo recursos/objetos.

Hay casos, donde un almacenamiento de tipo FileSystem (NFS) no me trae cuenta:
- Mete mucha sobrecarga de protocolo
- Me complica la gestión: Objeto/Recursos = ID

Ejemplos de utilidad:
- Backups              ID Y metadatos del backups? Fecha, Sistema operativo, etc? BBDD
- Videos de Youtube    ID del video, metadatos del video? Fecha, duración, etc? BBDD
- Imágenes de Glance   ID de la imagen, metadatos de la imagen? Formato, tamaño, etc? BBDD

Los objetos lo único que hago es CREARLOS(Subirlos/Cargarlos), LEERLOS(Descargarlos), BORRARLOS, pero no los puedo MODIFICAR (puedo reemplazarlos, pero no modificarlos).
No es un filesystem, es un almacenamiento de objetos.

En los contenedores y objetos puedo poner metadatos, tags, que son pares clave-valor, y me ayudan a organizarme y a buscar los objetos.

- ETAG: MD5 del objeto, para verificar su integridad

# Sobre los contenedores de objetos:
## ACLs de acceso:
- privados
- publicos
- compartidos con otros proyectos

No podemos borrar un contenedor si tiene objetos dentro.

# Podemos establecer cuotas a nivel de contenedor, para limitar el número de objetos que se pueden guardar, o el tamaño total de los objetos que se pueden guardar.

- Limitar el número de objetos: 1000 objetos
- Limitar el tamaño total de los objetos: 10GB

---

# Practica día 4:

Tenemos ya un proyecto en un dominio:

    NOMBRE_DEL_PROYECTO   proyecto-alumnoX-cliente
    NOMBRE_DEL_DOMINIO    dominio-alumnoX-cliente

    USUARIO_MEMBER        alumnoX-operador
    USUARIO_READER        alumnoX-monitoring

Subir 2 imagenes a glance:                      alumnoX-operador
- Descargada previamente a local, cirros.
- Una de ubuntu, descargada desde una URL.

Les ponemos alguna etiqueta: os: cirros, os: ubuntu

Crear un contenedor Swift:                      alumnoX-operador
Subir un documento de texto a ese contenedor:   alumnoX-operador
Ponerle alguna etiqueta: tipo: documento

alumno -> proyecto-alumno
alumnoX-operador -> proyecto-alumno-cliente
Acceder con el usuario reader: alumnoX-monitoring -> proyecto-alumno-cliente

Ver que somos capaces de ver la imagen de glance
Ver que somos capaces de ver el contenedor y el documento de texto en swift


---


Usuarios
                        dominio                         proyecto                        roles
alumno2                 dominio-alumno2                 proyecto-alumno2                admin           < VERIFICAR
alumno2-manager         dominio-alumno2-cliente         proyecto-alumno2-cliente        manager         < VERIFICAR
alumno2-operador        dominio-alumno2-cliente         proyecto-alumno2-cliente        member          < CREAR
alumno2-monitoring      dominio-alumno2-cliente         proyecto-alumno2-cliente        reader          < VERIFICAR


