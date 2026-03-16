
# De qué esto del OpenStack?

Es una plataforma que nos permite crear y operar nubes privadas y públicas.


Software libre? Free Software = FreeWare + Open Source
    ^^^^
    GNU: Richard Stallman, 1983, Free Software Foundation: GPL.
    Es decir:
        OpenSource: Puedo ver el código fuente.
        Freeware: Puedo usar el software sin pagar por él.

Openstack:
- Es OpenSource, puedo ver el código fuente.. incluso editarlo y a ayudar a mejorarlo.
- Es Freeware? Bueno... aquí entramos en otra.
  - El código base de Openstack es Freeware.. pero trabajar a pelo... tiene problemas:
      - Las instalaciones son duras!
      - No hay soporte serio... 4 foros en internet:
Hay empresas que ofrecen soporte comercial para Openstack y distros que además del páquete Openstack a pelo. me ponen cositas encima:
- Programas/Procedimientos de instalacion más fáciles 
- Preconfiguraciones
- Decisiones ya tomadas de antemano en cuanto a qué herramientas de virtualización, almacenamiento, etc. usar.
- Herramientas de monitorización, etc.

Ejemplos:
    - RedHat OpenStack : RHOSO: Redhat OpenShift Platform for OpenStack
    - Canonical OpenStack: COS: Canonical OpenStack
    - Mirantis OpenStack: MOS: Mirantis OpenStack

NOTA: 
- Conjunto de herramientas para virtualización: El cloud, cuando necesite virtualizar, usará herramientas de virtualización, pero OpenStack no trae nada de virtualización out-of-the box... no es un VMware. Ni tiene hipervisor para Máquinas propio (esXI, hyperV, kvm), ni para redes (OVS, Linux Bridge), ni para almacenamiento (Ceph, etc.). 
---

# Componentes de Openstack

Openstack no es un programa. Son cientos de programas. Esos programas viene agrupados en componentes. Una instalación base de openstack incluye ciertos componentes obligatorios... Pero además de esos, luego vamos montando encima otros componentes, dependiendo de los servicios que queramos ofrecer a nuestros usuarios.

Los servicios los agrupamos en categorias/componentes, que identificamos con un nombre. Habrá uno o varios programas en el cloud que se encargan de ofrecer ese servicio.

## Por ejemplo: AWS: Amazon Web Services

- El servicio que gestiona máquinas virtuales: EC2
- Hay servicios de almacenamiento:
  - EBS: Elastic Block Storage: Almacenamiento en bloque, como un disco duro virtual.
  - S3: Simple Storage Service: Almacenamiento de objetos, como archivos en la nube.
  - Almacenamiento a nivel de file system: EFS: Elastic File System
- Servicios para provisioanr clusters de kubernetes: EKS: Elastic Kubernetes Service
- Otro servicios para clusters de kubernetes: ROSA: RedHat OpenShift Service on AWS

En OpenStack, hay ciertos programas de base... que entran siempre... para ofrecer los servicios más básicos y necesarios:
- MariaDB / Galera
- Keystone: (IAM) Servicio de identidad, autenticación y autorización.
             Es el programa que se encarga de gestionar los usuarios, los roles, los permisos, proyectos, etc.
             Cualquier cosa que quiera hacer contra un servicio de OpenStack, primero tiene que autenticarse contra Keystone, y luego Keystone le dará un token de acceso (que tendrá una serie de permisos asociados a él), y ese token de acceso es el que se usará para hacer las peticiones contra los servicios de OpenStack.
- Almacenamiento:
  - Cinder: Almacenamiento de bloques.
  - Swift: Almacenamiento de objetos.
  - Manila: Almacenamiento a nivel de file system.
  - Glance: Almacenamiento de imágenes de máquinas virtuales (ISOs)
    - A su vez, este servicio puede apoyarse en Swift o en Cinder.

    Y todos ellos por abajo, al final lo que usan es un CEPH.

---

Ceph... Esto no es openstack. Es otra de esas cosas de mase que necesito al montar un cluster de OS:
- MariaDB
- Memcached
- RabitMQ
- Ceph

Ceph es una herramienta de almacenameinto que ofrece: almacenamiento de:
    - Objetos: Rados
    - Ficheros: CephFS
    - Bloques: RBD
Realmente, Ceph trabaja todo con almacenamiento de objetos internamente: RADOS.
Un archivo, (cephfs) Se guarda como un objeto dentro de RADOS.
Un bloque de almacenamiento (RBD) se guarda como un objeto dentro de RADOS.
Ese almacenamiento de objetos, puede exportarse también a los usaurios finales: RadosGW, que es un servicio de almacenamiento de objetos compatible con S3.

Lo que permites es un sistema de almacenamiento con redundancia, tolerante a fallos, escalable. Cada dato se guarda replicado.
Es algo parecido a un RAID... pero el RAID si lo tengo en un nodo/cabina, sigo teniendo un SINGLE POINT OF FAILURE... si se me jode el nodo/cabina, se me jode el RAID... 
En cambio, con Ceph, cada dato se guarda replicado en varios nodos, por lo que si se me jode un nodo, no pierdo el dato, porque lo tengo replicado en otros nodos. Es algo parecido a un almacenamiento hiperconvergente (Nutanix, etc.) pero a lo bestia... 
El throughput de lectura/escritura es bestial.. puedo leer/escribir un archivo a trozos desde varios nodos.
Tengo un archivo de 30Mbs.. que se parte en trozos de 5Mbs... cada trozo se guarda en un nodo diferente... y cuando quiero leer ese archivo, lo puedo leer a trozos desde varios nodos, por lo que el throughput de lectura/escritura es bestial.

    Nodo1
        Pools de discos \
    Nodo2                                                               < RADOSGW
        Pools de discos -   Pool de almacenamiento <- Objetos (RADOS)   < CephFS
    Nodo3                                                               < RBD
        Pools de discos /

    En Ceph cada disco físico es gestionado por lo que se llama un OSD (Object Storage Daemon).
    Lo que configuramos son pools de almacenamiento.
    Y cuando guardo algo, lo guardo en un pool de almacenamiento, y el Ceph se encarga de:
    - Partir ese algo en trozos
    - Guardar cada trozo en varios Nodos (OSDs) para tener redundancia y tolerancia a fallos.

    Cada pool de almacenamiento puede tener un nivel de replicación diferente.

    Ceph no es solo la herramienta. Tambien define su propio protocolo de acceso a ese almacenamiento. El protocolo ceph es soportado out-of-the-box por el kernel LINUX.

    De ceph... pasa lo mismo que con OpenStack o que con GNU/Linux... el código base de ceph es Freeware.. pero trabajar a pelo... tiene problemas:
      - Las instalaciones son duras!
      - No hay soporte serio... 4 foros en internet

    Por ejemplo, Redhat ofrece su soporte comercial para Redhat Ceph Storage, que es una distribución de Ceph con soporte comercial, y además ofrece herramientas adicionales para facilitar la instalación, configuración y monitorización de Ceph.

    Esto es un producto diferente a OpenStack. Igual que MariaDB es un producto diferente a OpenStack. Pero ambos son componentes que necesito usar para montar un cluster de OpenStack.
---

Acabamos de decir que Ceph ofrece almacenamiento a nivel de:
- Bloque 
- Ficheros
- Objetos

Pero luego... hemos dicho que OpenStack también ofrece servicios de almacenamiento a nivel de:
- bloque (Cinder) -> Ceph RBD
- ficheros (Manila) -> CephFS
- objetos (Swift) -> Ceph RadosGW
Pregunta... Si ya tengo Ceph... para que cojones quiero OpenStack: Cinder, Manilla y Swift


Volvemos a la mis diferencia que virtualización -> cloud.
- Virtualización es tecnología.
- Cloud es forma de entrega de un producto/servicio -> Autoservicio + Automatización

Yo puedo crear máquinas virtuales con KVM, o puedo usar el servicio NOVA de Openstack para que NOVA use KVM para al final darme una MV.
La gestión de la MV es del hipervisor, no de Openstack (NOVA)
Openstack me da una forma más sencilla (autoservicio, automatización...) de acceder a esa MV.

Con almacenamiento igual:
- CEPH es tecnología
- cinder, Manila, Swift me aislan de esa tecnología y me permiten acceder a ella de forma más sencilla (autoservicio, automatización...)


    Tecnologías de base     Openstack (capa de auto-servicio)
    -------------------     ---------------------------------
    CEPH < RadosGW          < Swift     < Glance
         < RDB              < Cinder    < 
         < CephFS           < Manila

    KVM                     < Nova

    OVS                     < Neutron

                            < HORIZON


    * Una simplificación absurda pero efectiva, desde el punto de vista pedagógico sería:
      - Openstack me da unos formularios que los usuarios pueden rellenar. 
      - Captura los datos (por ejemplo, crear MV con Tales características, con este sistema operativo, etc.)
      - Habla con un backend (KVM) para que cree la máquina virtual con esas características, con ese sistema operativo, etc.
      Básicamente eso es el Openstack... Es mucho más.,.. pero como concepto va por ahí! 

      Lo que pasa es que luego no quiero a un usuario rellenando formularios en una web. Trabajar en una web tiene problemas?
      (por qué odiamos los syadmins los GUI y queremos una puñetera terminal?)
      - Porque NO ES AUTOMATIZABLE. Es a base de rellenar campitos a mano..
      - Y que probabilidades hay de cagarla al meter datos a mano? MUCHA
      - Y cuanto tardo? En 1 poco.. en 100? MUCHO
      - Y puedo replicarlo? NO
      - Dejo traza de lo que hice? NINGUNA
      - Hay documentación al respecto? NASTI DE PLASTI

        Eso es lo que un script me resuelve! 

        En openstack tenemos un componente que es un dashboard gráfico (bastante cutre!): HORIZON !
        Aprenderemos a usarlo... pero más peso le vamos a dar al cli: 
            $ openstack
        Ese es el que podemos automatizar.

        aunque ... tampoco es lo que más nos gusta a día de hoy... QUE ALTERNATIVA ES LA GUAY ENTONCES?

Es decir, openstack reemplaza a los sysadmins que antes procesaban tickets para:
- Provisión de máquinas virtuales
- Provisión de almacenamiento
- Provisión de redes
- Configurar reglas de firewall, etc.

---

El trabajo de sysadmin ha muerto tal y como lo conocemos... pero ha muerto hace varios años!
El trabajo hoy en día de un sysadmin ya no es administrar sistemas... sino hacer programas que administren sistemas.. o configurar esos programas.... Esta más cerca del trabajo de programador.
Esto realmente lo hacemos desde hace décadas: script sh, ps1 = PROGRAMA para automatizar lo que antes hacía a mano:
- Despliegue

El cli no es que no sea guay... es que usa un paradigma de programación que cada día odiamos más.

Al crear un programa, uso un lenguaje de programación. Y al usar el lenguaje puedo optar por distintos paradigmas de programación.

Paradigma de programación = Nombre hortera que los desarrolladores ponemos a las formas de usar un lenguaje.
En los lenguajes naturales (los que hablamos: Español, Vasco, Catalán, ingles...) también tenemos paradigmas:

> Felipe, IF(Condicional) Si hay algo que no sea una silla debajo de la ventana:
>   Felipe, quítalo!     IMPERATIVO: ORDEN
> Felipe if no hay silla debajo de la ventana:
>      Felipe, IS NOT SILLA (silla == FALSE) GOTO IKEA! Compras silla Imperativo: ORDEN
> Felipe, pon una silla debajo de la ventana.           Imperativo: ORDEN

Odiamos el lenguaje imperativo. Cada día más... aunque estamos muy habituados a él.. Llevámos décadas usándolo.

· mkdir ventana -> make directory ventana <- Imperativo
· cd ventana -> change directory ventana <- Imperativo
· mkdir silla -> make directory silla <- Imperativo

El lenguaje imperativo tiene un problemón. Nos hace olvidar nuestro objetivo. Hace que nos centremos en el cómo conseguir nuestro objetivo.
Eso da lugar a la guarrada de programas típicos de lenguaje imperativo.

> Felipe, debajo de la ventana tiene que haber una silla. Es tu responsabilidad. DECLARATIVO: OBJETIVO

No le estoy diciendo a Felipe lo que debe hacer... sino lo que quiero tener.
Le explico como SON LAS COSAS. 
Al hacerle responsable, lo que le estoy diciendo en realidad es que no solo es reponsable de conseguir el objetivo, sino también de establecer el plan adecuado para conseguirlo.

Esta forma de hablar da lugar a programas mucho más sencillos de redactar.
Y Además lleva aparejada una cosa llamada IDEMPOTENCIA!

Idempotencia: Da igual el estado de partida, el resultado final siempre es el mismo.
Esto de cara a autoamtizar es una gloria... Y me resuelve la principal problemática de muchos scripts...
Imaginad que hago un script.. y se ha quedado a medias en ejecución.

Todas las herramienats que triunfan a día de hoy en el mundo IT lo hacen por usar un lenguaje declarativ:
- Spring / JAVA
- Angular
- Terraform
- Ansible
- Kubernetes
- Docker Compose
- HEAT (Openstack)

Todo eso son herramientas que usan un lenguaje declarativo.

En el mundo de la infra, hoy en día tenemos un concepto: IaC: Infrastructure as Code = Terraform (HEAT)

Qué significa eso de IaC?
- No es solo que voy a definir/provisionar la infra mediante un código/programa
- Sino que la trato como si fuera un programa: Lo primero de todo, con control de versiones.

Infra       v1.0.0 -> v1.1.0 -> v1.1.1
Sistema     v1.0.0 -> v2.0.0 (meto ahora un sistema de caché) -> v.2.0.1

            App -> BBDD
                    APP -> Sistema de caché -> BBDD
                            memcached (Otro componente que por cierto usa Openstack y es obligatorio, igual que ceph o que mariadb)

Hoy en día, entendemos la infra como un ser vivo... igual que el programa.
Y vamos generando versiones de la infra... que voy a tratar como si de código se tratasen: Sujetas a CONTROL DE VERSIONES!
Seguramente hay relación entra las versiones de la infra y las versiones del software que corre en esa infra... aunque no una relación 1-1

Herramientas como terraform o heat, me permiten definir la infra usando un lenguaje declarativo:
- Quiero tener 3 servidores con tales características
- Quiero tener una subred con tales características
- Quiero tener un balanceador de carga con tales características
- Quiero tener un volumen de almacenamiento con tales características
- Quiero tener una base de datos con tales características
- Quiero tener una IP pública con tales características

Eso es un programa, no uno que use lenguaje imperativo. Es un programa que usa lenguaje declarativo. Y lo voy a tratar como un programa, con control de versiones, etc.

Terraform tiene módulos para trabajar contra Openstack, y también tiene módulos para trabajar contra AWS, Azure, etc. 

Heat, otro de los componentes de Openstack, es una herramienta de orquestación que me permite definir la infra usando un lenguaje declarativo, y luego esa definición de la infra se traduce en llamadas a los servicios de Openstack para crear/mantener esa infra.
Pero eso ya es trabajo de HEAT (nuestro Felipe de turno)

Mi trabajo no es ya crear la infra... sino definirla para que HEAT la cree por mi... y luego mantener esa definición para que HEAT mantenga la infra por mi.

HEAT lo que hará ees llamadas a los servicios de Openstack para crear/mantener esa infra.
- Llamadas a NOVA para crear máquinas virtuales
- Llamadas a NEUTRON para crear redes, subredes, IPs, etc.
- Llamadas a CINDER para crear volúmenes de almacenamiento
- Llamadas a MANILA para crear sistemas de almacenamiento a nivel de file system

PAra eso usa los servicios WEB REST de Openstack. Esos servicios REST son los que también usan los usuarios finales para interactuar con Openstack, pero HEAT lo hace de forma automatizada.

              <- HORIZON (GUI)      RUINA!!!!
    Openstack <- cli ($ openstack)  NO ESTA MAL... pero mejorable!
              <- HEAT (IaC)         GUAY! 
                 terraform (IaC)    GUAY!

# Heat o terraform?

Si estoy en el mundo Openstack lo normal es usar HEAT.. además me da funciones más propias de openstack
Si uso varios clouds, quizás me convenga usar terraform... que me permite trabajar con todos ellos... y no necesito formar al equipo en 50 herramientas diferentes... con terraform me formo en terraform y ya puedo trabajar con todos los clouds que quiera.

Esos ficheros, donde declaramos la infra, los meteremos en un git, sujetos a control de versiones. Y Seguiré un control de ciclo de vida similar al que uso en software para versionar mi infra y evolucionarla.


Evolución:
    Yo creo una MV dentro de VMWare
    Yo le pido a Openstack que cree una MV "dentro de VMWare"
    Yo defino una infra (MV) y alguien (HEAT) la crea por mi dentro de VMWare <<< AQUI ES DONDE ESTAMOS = IaC

---

# Esquema semántico de versionado: semver

v.A.B.C

                    Cúando suben?
    A?  Mayor       Breaking change: Cuando se hacen cambios que rompen la compatibilidad con versiones anteriores.
    B?  Minor       Cuando se añaden funcionalidades
                    (Siendo puristas, cuando marco funcionalidades como obsoletas también)
                    + Pueden venir adicionalmente arreglos de bugs...
    C?  Patch       Arreglos de bugs.

---

# Automatizar?

Automatizar es crear una máquina (o cambiar el comportamiento de una mediante un programa) que haga lo que antes hacía un humano con sus manos.

Puedo automatizar el lavado de la ropa: 
Máquina: LAVADORA (que incluso tiene PROGRAMAS de lavado: Fría, delicada...)

En nuestro caso, la máquina la tenemos: Computadora. Lo que hacemos es crar programas / configurarlos para que hagan lo que antes hacía un humano con sus manos.

- Antes un humano iba al VSphere a crear una VM, a petición de otro humano
- Ahora tengo un programa (OpenStack-Nova) que:
  - Ayuda en la captura de los datos de la petición del otro humano (antes era un email cutre... o un ticket al cau... o llamada de teléfono)
  - Automatiza el proceso de creación de la máquina virtual, que antes hacía un humano con sus manos (o con el ratón, pero con sus manos al fin y al cabo)

Openstack reemplaza al operador, en el lado del proveedor.
Sigue habiendo un humano al otro lado... el que hace la petición... Seguro? Me interesa?

El cloud ha automatizado sus procesos. GUAY!
Yo, consumidor del cloud... quiero automatizar los mios?

---

# DEVOPS?

Es una cultura, filosofía, un movimiento... en pro de la automatización.
Quñe quiero automatizar? TODO lo que implica poner un software en un entorno de producción:
- Desarrollo
- Empaquetado (make, maven, gradle, etc)
- Pruebas
- Puesta en disposición de mi cliente de mi producto
- Despliegue
- Operación (arranque, parada, reinicio, escalado, etc.)
- Monitorización (comprobaciones, revisión de logs, etc.)

Quiero automatizar todo entre el dev -> ops.
Y lo más fácil de automatizar ha sido la parte del OPS.
- Provisionamiento de infraestructura (máquinas virtuales, almacenamiento, redes, etc.) 
- Configuración de esa infraestructura (instalación de software, configuración de software, etc.) / Planchar máquinas
- Instalación de software (paquetes, etc.) Despliegues
- Operación de esa infraestructura (arranque, parada, reinicio, escalado, etc.) y de los programas que corren en esa infraestructura.
- Monitorización de esa infraestructura y de los programas que corren en esa infraestructura.

Herramientas con las que automatizamos eso:
- Terraform, CloudFormation, Heat (otro de los componentes de OpenStack) para el provisionamiento de infraestructura.
- Ansible, puppet, chef, saltstack, etc. para la configuración de esa infraestructura (planchar máquinas) y para la instalación de software (despliegues)
- Contenedores (kubernetes, Openshift...) para la monitorización y operación.
  - Apoyados además con Prometheus, Grafana, etc. para la monitorización.

Esas herramientas sueltas automatizan tareas. 
Luego lo que queremos es automatizar PROCESOS: Orquestar todas esas tareas para que se ejecuten en el orden correcto, con las dependencias correctas, etc. Para eso tenemos herramientas de orquestación como Jenkins, Gitlab CI/CD, etc.
---

Hay muchos tipos de servicios de almacenamiento:
- Almacenamiento en bloque: iSCSI.
- Almacenamiento de objetos: S3, Minio.
- Almacenamiento a nivel de file system: NFS.

En base a mi necesidad, me convendrá más un tipo de almacenamiento u otro.

Quiero montar un WordPress. Tiene varios componentes:
- Apache/Nginx: Servidor web, que se encarga de servir las páginas web a los usuarios.
- Soporte de PHP: El lenguaje en el que está escrito WordPress.
- BBDD: MySQL o MariaDB

Los Apaches/Nginx/Wordpress... necesitan un volumen de almacenamiento. Cada vez que subo un fichero a mi web (imagen, pdf) lo guardo en ese volumen de almacenamiento. Pregunta... Me interesa aquí un Sistema de almacenamiento orientado a bloques o a ficheros?

        Cluster activo/activo: Galera

        MariaDB1                                Wordpress1

        MariaDB2        < Balanceador     <     Wordpress2      < Balanceador    < Proxy reverso    <<  Usuarios

        MariaBD3                                Wordpress3

Cuando trabajamos con archivos, un SO permite gestionar el acceso a esos archivos de 2 formas:
- Acceso secuencial:   Leo el archivo desde el principio hasta el final. O escribo el archivo desde el principio hasta el final. O si acaso le añado cosas por el culo (Append). Ideal para ficheros de text.. o cuando manejo el archivo como una unidad.
- Acceso aleatorio:    Puedo leer o escribir en cualquier parte del archivo. Ideal para bases de datos. Unas BBDD los datos los guardan en unos pocos ficheros.

    Los Wordpress todos deben usar el mismo conjunto de archivos... en modo READ/WRITE: NFS es ideal para esto.
    No habrá problema en que 2 Wordpress traten de escribir simultáneamente en el mismo archivo... lo gestiona wordpress.

    Lo que pasa es que NFS mete cierta sobrecarga. 

    Los MariaDB me interesa que tengan cada uno sus archivos de datos o compartido? Cada uno sus archivos.

    Para qué un cluster activo / Activo de BBDD? HA
    Si solo me interesa HA, puedo montar un cluster Activo/pasivo: BBDD Maestra y replcias (mirriring) y es más sencillo.
    Si monto cluster Activo / Activo: Escalabilidad: más capacidad de escritura/lectura.. Más throughput... pero es más complejo de montar y mantener.
        Tenemos un doble problema:
            - Qué tal es para un SO tener varios procesos modificando el mismo archivo? NO
              Tenemos varios procesos de BBDD modificando el mismo archivo... NO
                No es como el WP... donde cada upload es un archivo diferente... 
                La BBDD hemos dicho que guarda todos los datos en pocos archivos... 
            - Cada proceso tiene que tener sus archivos... además los datos no se guardan en todos ellos.


        MariaDB1        dato1   dato2
        MariaDB2        dato1   dato3
        MariaDB3        dato2   dato3

        Con un MariaDB puedo guardar 1 dato por unidad de tiempo.
        Con 3 mariasbd puedo guardar 3 datos por 2 unidad de tiempo.
        Es decir, la mejora potencial (teórica) de rendimiento al montar un cluster es del 50% y es frustrante.

        Para MariaDB no necesito una forma/protocolo de guardar datos de forma que varios procesos (mariasdbs) puedan estar simultáneamente escribiendo en el mismo archivo... porque cada proceso tiene sus archivos de datos...
        NFS aqui no me aporta nada... más que sobrecarga del protocolo.
        Me interesa un almacenamiento orientado a bloques, que es más rápido, y cada proceso de MariaDB tiene sus archivos de datos en su propio bloque de almacenamiento. iSCSI y cada maría DB el suyo
        Para WP me interesa NFS y compartido entre todos.

        Si hago backups... ahí casi mejor un almacenamiento de objetos... Guardo el backup como una unidad, identificada por un nombre, y luego puedo recuperar ese backup cuando lo necesite. S3, Minio, etc.
---


# Linux?

No es un SO. Es un kernel de SO.
Un SO no es un programa... son un huevo de programas:
- Kernel: Es el núcleo del sistema operativo, son un huevo de programas programa que se encargan de gestionar los recursos del sistema y de proporcionar una interfaz entre el hardware y el software. El kernel de Linux es el más popular, pero hay otros kernels como el de Windows, el de MacOS, etc.
- Shells
- Cargador de arranque
- Librerías
- Aplicaciones

De hecho Linux es el kernel de SO más usado del mundo. Pero vamos... ordenes de magnitud por encima de Windows, que es el segundo kernel más usado del mundo. Hay muchos SO que usan Linux...De hecho hay un SO que convierte el solito a Linux en el kernel de SO más usado del mundo... Android!

Hay un SO, que usa el kernel de linux, que usamos mucho sobre todo en servidores: GNU/Linux. Ese sistema operativo se ofrece también en forma de distros:
    - Debian: Ubuntu, Mint, etc.
    - RedHat: CentOS, Fedora, Oracle Linux, etc.
    - Suse: OpenSuse, etc.
    - Arch: Manjaro, etc.

Esas distros llevan un GNU/Linux, con ciertos añadidos:
- Programa de instalación amable
- Programas adicionales preconfigurados (gestores de paquetes, bash.)
- Soporte comercial (RedHat, Suse, etc.)

GNU Linux es OpenSource, y Freeware. Algunas distros de Linux no son Freeware, porque no son gratuitas, aunque siguen siendo OpenSource.

RHEL es OpenSource, pero no es Freeware, porque no es gratuita. RedHat vende su soporte comercial, y ese soporte comercial es lo que hace que RHEL no sea Freeware. Si soy una empresa, si algo va mal, necesito un pouñetero teléfono y llamar a que me resuelvan la torrija!

Oye .. gilipollas no soy... por qué pagaría yo por una distro si tengo otras gratis? Puedo montar incluso GNU/Linux.. y monto yo el resto por encima.

Windows, que no es un SO. Windows es una familia de sistemas operativos, cada uno con su propio kernel, shell, cargador de arranque, librerías y aplicaciones. Windows 10, Windows Server 2019, etc.
Microsoft ha tenido 2 kernels en su historia:
- DOS -> MSDOS -> Windows 3.1 -> Windows 95 -> Windows 98 -> Windows ME
- NT ( New technology ) -> Windows NT 3.1 -> Windows NT 4.0 -> Windows 2000 -> Windows XP -> Windows Server 2003 -> Windows Vista -> Windows Server 2008 -> Windows 7 -> Windows Server 2012 -> Windows 8 -> Windows Server 2016 -> Windows 10 -> Windows Server 2019

---

# Cloud vs Virtualización

## Cloud

Conjuto de servicios que una empresa de IT ofrece a sus clientes de forma que accede a ellos:
- Autoprovisionamiento (Yo cliente, soy el que opera contra la nube, manejas los servicios)
- Autamatización de lado del proveedor
- Además, no se limita a servicios de Infraestructura, sino también a servicios de plataforma y software (PaaS, SaaS)
Hay varios tipos de servicios:
- Infraestructura como servicio (IaaS):
  - Máquina virtual o física
  - Almacenamiento
  - Red
- Plataforma como servicio (PaaS):
  - BBDD
  - Gestor de mensajería (Kafka, RabbitMQ)
- Software como servicio (SaaS):
  - Aquí, la diferencia con el PaaS es que mientras los programas que contrato en PaaS los uso para montar yo software final que proveo a mis clientes, en SaaS, el software que contrato es el que uso para proveer servicios a mis clientes. Ejemplo: Gmail, Dropbox, etc.

Todos esos servicios, al final precisan de una infraestructura física, y ahí es donde entra la virtualización.

    Cloud = Virtualización + Servicios (autoprovisionamiento, automatización, etc.)

---

# App1: App hospitalaria

    Día 1               100 usuarios
    Día 100             100 usuarios   Aquí no hay problema. Llamo a Fermin (Dell/Ibm)
    Día 1000            100 usuarios

# App2: 

    Día 1               100 usuarios
    Día 100             1000 usuarios   Aquí ya hay un problema: Escalabilidad vertical: MAS MAQUINA!
    Día 1000            10000 usuarios

# App3: Esto es Internet!

    Día n               100 usuarios
    Día n+1             1M usuarios
    Día n+2             0 usuarios
    Día n+3             10M usuarios

    No tenemos ni que ir a días... por horas o minutos.

    Web telepi:
        00:00h - 0 estoy cerrado
        08:00h - 0 sigo cerrado
        10:00h - 4 usuarios
        13:00h - 100 usuarios               Aquí necesito ESCALABILIDAD HORIZONTAL: MÁS MAQUINAS!
        14:00h - 10000 usuarios
        17:00h - 200 usuarios
        20:30h - Madrid/Barça -    1M usuarios
        23:45h - 0 usuarios

        Aquí no tengo un problema.. tengo un problemón!
        A qué dimensiono la infra?

        Aquí no me da para llamar al Fermín!

    Aquí es el puto donde los clouds se vuelven imprescindibles, por la automatización y el autoprovisionamiento.

    Yo lo único que hago es poner mi tarjeta de crédito en el cloud... y a partir de ahí: YO ME LA GUISO YO ME LA COMO!
    Las tareas las hago yo. El cloud tiene procesos AUTOMATIZADOS reemplazando al Fermín y a los técnicos que venían a instalarme las máquinas, configurar la red, etc.

    Mi trabajo no está automatizado, pero el del proveedor sí. Fijo... Oye.. el mío podría estar automatizado también... <- IaC

    Si el cloud es público, la infra la gestiona la empresa que monta el cloud... y provee los servicios.
    Si el cloud es privado, la infra la gestiona la empresa que monta el cloud... pero los servicios los consume la empresa que monta el cloud... o no!

                        GESTIÓN DEL CLOUD / INFRA                Adquisición de servicios

    Cloud público:     Proveedor del cloud                       Cliente del cloud
    Cloud privado:     Empresa que monta el cloud                Empresa que monta el cloud
                            Equipo de IT del cliente                    Equipo de IT del cliente
                            para dar soporte al cloud                   que consume los servicios del cloud


Para una empresa pequeña, montar un cloud privado no es rentable, porque el coste de montar el cloud es mayor que el beneficio que le va a sacar. En cambio, para una empresa grande, montar un cloud privado sí es rentable, porque el coste de montar el cloud es menor que el beneficio que le va a sacar.


---

Las herramientas de virtualización, me permiten obtener "servicios" de infraestructura, algo de plataforma algunas (bbdd). Pero sin autoprovisionamiento ni automatización.

- Alguien entra en el VMWare crea al final la máquina virtual, la configura, etc. Es un proceso manual (al menos el Virtualizador no ofrece mucho aquí.)
     Usuario que necesita desplegar una App -> Petición al CAU: "Necesito una máquina virtual con estas características, con este sistema operativo, etc." -> CAU -> Técnico del CAU -> Provisión de la máquina virtual -> Configuración de la máquina virtual -> Entrega de la máquina virtual al usuario. Pasan días o semanas hasta que el usuario tiene la máquina virtual lista para usar.
- En cambio, con un cloud, el usuario puede autoprovisionarse la máquina virtual, y el proceso de provisión y configuración de la máquina virtual está automatizado, por lo que el usuario puede tener la máquina virtual lista para usar en minutos u horas.

Empezamos aquí? Posiblemente no!

Cuando se adopta esta estrategia de cloud, lo normal es que haya un equipo centralizado que se encarga de gestionar el cloud, y los usuario siguen haciendo sus peticiones al CAU, Y desde ahí ya ... las mando al equipo de cloud, o el CAU ya tiene acceso al cloud y puede autoprovisionar las máquinas virtuales para los usuarios.
    ES UN PRIMER PASO.
    La gracia FINAL es cuando el usuario puede autoprovisionarse las máquinas virtuales, y el proceso de provisión y configuración de las máquinas virtuales está automatizado, por lo que el usuario puede tener la máquina virtual lista para usar en minutos u horas.

Virtualización será una parte importante del cloud, pero el cloud es mucho más que virtualización. Es más... a veces quiero una máquina física.
A veces quiero almacenamiento... y ahí no entra tampoco lo de la virtualización.