# Repaso breve

- Intro al concepto de cloud vs virtualización.
    Cloud agrupa muchos servicios (de muchos tipos diferenetes):
        - IaaS: Infraestructura como servicio (máquinas virtuales, redes, almacenamiento).
        - PaaS: Plataforma como servicio (entornos de ejecución, bases de datos gestionadas).
        - SaaS: Software como servicio (aplicaciones completas accesibles por web). En OS esta parte no la encontramos.
    Virtualización es solo una tecnología que se usa en algunos servicios de cloud (IaaS).
    Openstack usa Ceph... que es otra tecnología, en este caso también usada para algunos servicios de almacenamiento (IaaS).

    Cloud se basa mucho Automatización y Autoservicio.

        Modelo tradicional organizativo:

                                       Manual
            Usuario -> Ticket -> Equipo de Infraestructura -> Respuesta demorada
                 
        Modelo cloud:

            Usuario -> Solicita operación -> OpenStack -> Respuesta inmediata
                                           Automatización

- Componentes de Openstack:
  Openstack no es un programa, sino un huevo de programas, que se comunican entre si... o no!
  Además, yo elijo:
    - qué componentes quiero usar
    - cómo configuro esos componentes:
      - qué tecnología de virtualización quiero usar
      - qué tecnología de almacenamiento quiero usar
      - keystone: qué backend de identidad quiero usar (LDAP, SQL, etc)
      - etc
  Instalamos los servicios/componentes que necesito en mi organización.

  Algunos de ellos:
  - Keystone: gestión de identidad, usuarios, proyectos, roles, catalogo de servicios, etc.
  - Almacenamiento:
    - Bloques: Cinder   \
    - Objetos: Swift     > Ceph (que es un sistema de almacenamiento distribuido y de alto rendimiento que puede usarse para ambos casos)
    - Files:   Manila   /
    - Imágenes de las VM (iso): Glance (a su vez se apoya en Cinder o en Swift)
  - Cómputo: 
    - Máquinas virtuales: Nova
    - Máquinas físicas:   Ironic
    - Contenedores:       Zun
  - Redes: 
    - Red virtuales:        Neutron
    - DNS:                  Designate
    - Balanceadores:        Octavia
  - Plataforma: 
    - Kubernetes:         Magnum
    - Bases de datos gestionadas: Trove
    - Colas de mensajes:   Masakari       (Kafka, RabbitMQ, etc)
  - Orquestación:   Heat
  - Telemetría:     Ceilometer
  - Horizon:        Interfaz web de OpenStack

- Instalar clientes de OpenStack:
  - CLI: línea de comandos (python-openstackclient)
    - Necesita cierta configuración:
      - Variables de entorno (OS_USERNAME, OS_PASSWORD, etc)
      - Archivo de configuración (clouds.yaml)
        - Ese archivo lo coloco en una ruta concreta (C:\Users\miusuario\.config\openstack\clouds.yaml)

---

Plan de trabajo para hoy:

- Charlar acerca de la instalación de Openstack -> Contenedores / Kubernetes
- Charlar Keystone (funcionaldiad, arquiectura, etc)
- Prácticas:
  - Configurar el cliente de OpenStack (openrc.cmd o clouds.yaml)
  - Aprender los comandos más básicos para conectarnos y movernos por un OpenStack
  - Vamos a ir a fondo con keystone (crear usuarios, proyectos, roles, etc)

---

# Contenedores

Un contenedor es un entorno aislado dentro de una máquina con Linux donde ejecutar procesos.

## Formatos típicos de Instalación

            App 1 + App 2 + App 3               Problemas:
        -----------------------------------         - Residuos
            Sistema Operativo                       - Incompatibilidades entre apps / dependencias / configuración a nivel de SO
        -----------------------------------         - Qué pasa si App 1 tiene un bug -> CPU 100% --> App1 --> OFFLINE
                    Hierro                                                                           App2 y App3 --> OFFLINE
                                                    - Seguridad

## Máquinas virtuales

            App1     |     App2 + App3          Nuevos problemas:
        ------------------------------------        - Licencias de SO
            SO 1     |     SO 2                     - Administración / configuración / mantenimiento más compleja
        ------------------------------------        - Desperdicio de recursos (cada SO consume recursos aunque no se estén usando las apps)
            MV 1     |     MV 2                     - Merma en el rendimiento de las apps
        ------------------------------------
            Hipervisor:
            esXI, KVM, Hyper-V, Xen, etc
        ------------------------------------
                Sistema Operativo
        ------------------------------------
                    Hierro

    Las máquinas virtuales me sirven para crear entornos aislados donde ir ejecutando procesos.

## Zonas de Solaris (Se parecen mucho al concepto de contenedor)

## Contenedores

Un contenedor es un entorno aislado dentro de una máquina con Linux donde ejecutar procesos:
- Tienen su propia configuración de red (su propia IP)
- Puedo limitar acceso a recursos: CPU, RAM, almacenamiento
- Tiene su propio sistema de archivos
- Tiene sus propias variables de entorno, como entorno aislado que es.

Formalmente y a nivel de la industria se establecen en 2013 con Docker, aunque la tecnología de contenedores ya existía antes (LXC, OpenVZ, etc).
Al año firma acuerdos con:
- Microsoft
- RedHat
- AWS

            App1     |     App2 + App3
        ------------------------------------
            C 1      |     C 2             
        ------------------------------------
            Gestor de contenedores:
            Docker, Podman, Crio, ContainerD
            NO KUBERNETES
        -------------------------------------
            Sistema operativo (Linux)
        -------------------------------------
            Hierro


Los contenedores los creamos desde Imágenes de contenedor (similar a una ISO para una VM).
Una imagen de contenedor es un triste archivo comprimido (tar) que tiene dentro:
- sistema de archivos compatible con POSIX = Encontramos las 4 carpetas típicas de Linux/Unix:
   / 
    bin/   -> binarios ejecutables
    etc/   -> archivos de configuración
    home/  -> directorios personales de los usuarios
    lib/   -> librerías compartidas
    tmp/   -> archivos temporales
    usr/   -> programas y librerías de usuario
    ...
- Programa que me interesa, ya instalado dentro de esas carpetas... y configurado (al menos con una configuración mínima) 
- Además vienen programas de utilidad: ls, cat, bash, sh, etc
- Algunos metadatos, como por ejemplo:
  - Qué comando es el que hay que ejecutar para poner en marcha el programa PRINCIPAL que viene dentro


## Filesystem del host

    /
    bin/   -> binarios ejecutables
        ls
    etc/   -> archivos de configuración
    home/  -> directorios personales de los usuarios
    lib/   -> librerías compartidas
    tmp/   -> archivos temporales
    usr/   -> programas y librerías de usuario
    var/   -> archivos variables (logs, bases de datos, etc)
      lib/
        docker/
            images/
                nginx/
                    1.23.3/ <--- Desde el contenedor engaño para que crean que esta carpeta es la raíz del sistema de archivos
                                    Esta estructura es inmutable (NO HAY PERMISOS DE ESCRITURA)
                                    Ese engaño lo llevamos haciendo más de 40 años... chroot
                            bin/   -> binarios ejecutables
                                ls
                            etc/   -> archivos de configuración
                                nginx/nginx.conf
                            home/  -> directorios personales de los usuarios
                            lib/   -> librerías compartidas
                            tmp/   -> archivos temporales
                            usr/   -> programas y librerías de usuario
                            var/
                                nginx/   -> archivos variables (logs, bases de datos, etc)
                                    access.log
                            opt/
                                nginx/nginx
            containers/
                miginx/
                    vars/logs/access.log
                
El sistema de archivos de un contenedor es la superposición de la imagen del contenedor (que es de solo lectura) y un sistema de archivos temporal (tmpfs) que es de lectura/escritura, y que se monta por encima de la imagen del contenedor, a nivel del contenedor.
Esto tiene una ventaja... puedo usar la misma estructura (carpetas/archivos) de la imagen en 17 contenedores.


Para evitar que al borrar un contenedor, los datos se pierdan, usamos un volumen:
- Punto de montaje en el filesystem del contendor que apunta a un recursos de almacenamiento que vive fuera del contendor:
   mount -t nfs nfs-server:/export/volumen1 /var/lib/mysql 


# Kubernetes 

    Kubernetes, se encarga de ir hablando con los crio/conteinerd(equivalentes de docker) en los hosts que tengo disponibles para 
    ir desplegando las apps en un entorno de HA/Escalabilidad.

    Maquina 1
        crio
    Maquina 2
        crio
            Nova
    Maquina N
        crio
            Nova

    Kubernetes no es un gestor de contenedores.
    Es una herramienta que definir/opera un entorno de producción según mis especificaciones... Donde los programas corren no sobre los hierros, ni sobre VMs, sino sobre contenedores.
    En lenguaje declarativo:
        Quiero tener en el cluster operativo un KeyStone... con 4Gbs de Ram y 2 cores.
        Si va apretado, ve escalando hasta un máximo de 4 instancias de KeyStone, y si va sobrado, ve desescalando hasta un mínimo de 2 instancia de KeyStone.
        Te has enterado? Pues es tu puñetera responsabilidad FELIPE!

# Instalación

Las instalaciones más potentes hoy en día de Openstack se basan en kubernetes.
Hay procedimientos más antiguos (todavia se ve algo) donde se trabaja con instalaciones con contenedores pero sin kubernetes... pero es algo que se va a ir dejando de usar.

Canonical -> kubernetes
Redhat    -> kubernetes


    Algo curioso es que puedo tener una granja de máquinas, con los programas de openstack corriendo en ella como contenedores (siendo gobernados por un kubernetes). Y puedo pedirle a los programas del openstack que me generen un nuevo cluster de kubernetes para otras apps que quiero.


                GRANJA HARDWARE
        -----------------------------------
                ^
            Kubernetes              ^
                v
            Openstack     -----> Kubernetes 


Hay varias formas de instalar este cotarro. La instalación de un cluster de openstack ES COMPLEJA! a rabiar!

Por un lado tenemos los componentes de OS, que se instalan 1 a 1... y se configuran 1 a 1.
Por otro lado, la infra/dependencias de OS, que también hay que instalar y configurar 1 a 1 (base de datos, servicios de mensajería, etc).
 ^^^ Aquí tomo desisiones

Distintos proyectos de instalación de OS, toman más o menos decisiones al respecto de sobre todo la parte de infra/dependencias, y también sobre la parte de instalación/configuración de los componentes de OS.

Proyectos para instalar un OpenStack:
- DevStack: Instalación de OS para desarrollo, con todo en una máquina (no recomendado para producción)
  Esto come...
- Kolla-Ansible (Opensource y libre): Trabaja con contenedores, pero sin kubernetes. 
                                      La orquestacion de la instalación se realiza mediante Ansible
- OpenStack-Helm (Opensource y libre. OFICIAL DE OPENSTACK):  Más moderno.
                                      Trabaja con contenedores, pero requiere de un cluster de kubernetes ya montado. 
                                      La orquestacion de la instalación se realiza mediante Charts de Helm
- Canonical: 
  - Sunbeam:                          Trabaja con contenedores y kubernetes. 
                                      Las orquestación se hace con un producto de Canonical llamado Juju
- Rhoso:                              Trabaja con contenedores y kubernetes. 
                                      La instalación se hace mediante uin operador de kubernetes. A ese operador luego le pedimos que instale componentes de OS, y el operador se encarga de ir hablando con el cluster de kubernetes para ir creando los contenedores necesarios, con la configuración necesaria, etc.

En muchas de estas instalaciones ya hay tomadas decisiones de antemano:
- Backend de almacenamiento:
  - Kolla-Ansible  -> Tengo libertad: LVM, iSCSI, Ceph, etc
  - Openstack-helm -> Se recomienda Ceph... pero puede ser otro. Tengo libertad.. pero la instalación viene preparada para Ceph
  - RHOSO          -> Se usa Redhat Ceph Storage
  - Canonical      -> Se usa Ceph
- BBDD
  - Kolla-Ansible  -> Tu sabrás: MariaDB, MySQL y cómo los configuras
  - Openstack-helm -> Se recomienda MariaDB... y la instalación viene preparada para MariaDB. Tengo libertad.. pero la instalación viene preparada para MariaDB
  - RHOSO          -> MariaDB Galera
  - Canonical      -> MySQL InnoDB Cluster

En muchas instalaciones puedo montar (y debo) una herramienta para centralizar los logs de los componentes de OS, y así no tener que ir a cada máquina a ver los logs de cada componente -> ElasticSearch Kibana <- Beats, FluentD

En toda instalación quiero tener monitorización de los componentes de OS -> Prometheus + Grafana
En mi caso, yo en mi cluster de kubernetes ya tenía instalado Prometheus y Grafana, así que lo que hice fue instalar un Exporter de Prometheus para cada componente de OS, y así ya tengo monitorizados los componentes de OS en mi cluster de kubernetes.

Si monto esto con RHOSO, también se usa Prometheus y Grafana, pero me viene todo. Me montan en autom: Prometheus, Grafana, Exporters, Dashboards, etc.

En el caso del curso, yo tengo el lab (un openstack completo) en un cluster de kubernetes:
- Con kubernetes
- Con prometheus y grafana ya instalados
- IngressController ya instalado (para acceder a los servicios de OS desde fuera del cluster)
- DNS wildcard ya configurado (para que cualquier subdominio de ivanosuna.com apunte a la IP del IngressController)
- CertManager que genera certificados SSL con una CA de confianza (Let's Encrypt) para los servicios de OS a través del IngressController

En mi caso, la instalación del cluster de kubernetes la tengo totalmente automatizada: Playbooks de Ansible.

- MariaDB standalone
- Memcached
- RabbitMQ
- CEPH                                      YA LO TENIA: 12 Gbs de RAM
- Prometheus + Grafana                      YA LOS TENIA INSTALADOS
- No he montado ES + Kibana ...             No capturo logs.
Lo que he hecho es unos playbooks nuevos (1) para instalar Openstack-helm


5 mac mini (i7 4x2 cores, 16Gbs ) -> vcps = 40 ; Ram total = 80 Gbs
2 Tbs de SSD a nivel de cluster en almacenamiento CEPH
4 Tbs en NFS



---

Openshft es una distro de kubernetes que hace redhat=
    Kubernetes + productos de reedhat encima + conficguciones ya establecidas por redhat:
        Prometheus + Grafana + Alertmanager + NodeExporter + KubeStateMetrics + dashboard propio.

Openshift se puede instalar:
- On prem en bare metal
- En la nube (AWS, Azure, IBM)


Openshift maneja los programas de Openstack... y va montado en ciertos nodos (máquinas)
Openstack maneja luego más máquinas para provisionar los servicios: BBDD, VM, etc

Openshift:
 - Plano de control: 3 máquinas
 - Infraestructura: variable > 2 máquinas
   - Otros programas que monta Openshift
 - Openstack: Máquinas solo a nivel de Openstack (control-plane = componentes). En vuestro caso, éste está junto con el plano de control del openshift
 - Maquinas de computo

En openshift puedes definir: MachineSet, Machine, MachineAutoscaler
                                            v playbooks (lo gestiona OS internamente)
                                           Node  
---


# Helm

Es el gestor de paquetes de kubernetes.
Me permite hacer despliegues en kubernetes mediante plantillas de despliegue: Charts.

                                    En estos docuentos se habla de conceptos básicos de kubernetes:
                                        - Pods (conjuntos de cotenedores)
                                        - Service (balanceadores de carga)
                                        - Ingress (regla de proxy reverso)

        Cluster de kubernetes <--- documentos de manifiesto YAML <--- Los puedo crear yo a mano
                                                                 <--- Helm puede crear esos YAML en base a Charts (plantillas de despliegue)
                              
                              <--- Puedo instalar un Operador dentro del cluster
                                    Básicamente es como si pongo una persona que sepa un huevo de una herramienta a vivir dentro del cluster, y esa persona se encarga de ir haciendo las tareas de instalación/configuración/operación de un programa concreto (en este caso, OpenStack, MariaDB,...)
                                    Muchas empresas fabrican Operadores para kubernetes de s sus programas.

                                    Una vez instalado esto (cuya instalación puede hacerse por ejemplo mediante un chart de helm)
                                    le doy inststurcciones al operador. Esas instrucciones son nuevos ficheros YAML.

                    Cluster <- documentos de manifiesto YAML <- Operador experto <- YAML de instrucciones
                                                                                         ^          ^
                                                                                         A mano     Las creo con un chart helm


# Ansible:

Es una herramienta para crear scripts de instalación/configuración/automatización de tareas.
Básicamente lo que antes hacíamos con scritps de la bash o powershell, ahora lo hacemos con Ansible, que es más potente y más fácil de mantener.

Hay varias herramienats de este tipo: Puppet, Chef, SaltStack, Ansible, etc.

La última del grupito y que lo peta es Ansible.

Es una herramienta donde los scripts (PLAYBOOKS) los definimos en lenguaje declarativo. Detrás de ansible está Redhat.

    - Script Bash:
      - Crea un usuario llamado "felipe" con contraseña "1234" <<< Imperativo

    - Playbook Ansible:
      - Quiero tener un usuario llamado "felipe" con contraseña "1234" <<< Declarativo

---

# Qué era Unix?

Un SO que hacían los Lab. Bell de la americana de telecomunicaciones AT&T en los años 70, con el objetivo de crear un sistema operativo para sus equipos de telecomunicaciones.

Unix empezó a licenciarse a otras empresas y organizaciones. Pero de forma diferente a como se hace hoy en día: EULA (End User License Agreement).
Esas empresas reempaquetaban el SO con sus drivers.. y sus cosas y lo daban a usuarios finales -> EULA

Qué pasó? Más de 400 versiones de Unix, que empezaron a generar incompatibilidades entre ellas.

Salieron 2 estandares por separado que regulaban la forma de evolucionar esos sistemas operativos:
- POSIX (IEEE): Portable Operating System Interface for Unix
- SUS (The Open Group): Single Unix Specification

Unix dejó de hacerse a principios de los 2000.

# Qué es Unix?

Es esos 2 estandares, que regulan la evolución de los sistemas operativos que cumplen con ellos.

Hay empresas hoy en día que montan SO que cumplen con esos estandares, y por lo tanto se les puede llamar Unix®:

IBM:        AIX (Unix®)
Oracle:     Solaris (Unix®)
HP:         HP-UX (Unix®)
Apple:      macOS (Unix®)

Hay gente que montó SO (o lo intentaron) cumpliendo co esos entandares... pero que no certificaron (€€€):
- Universidad de Berkeley: 386BSD (Berkeley Software Distribution)
  La cagaron: Dijeron: "Tenemos un sistema operativo que cumple con Unix®" -> AT&T Demanda al canto!
    Años de litigios con el código parado sin poder usarse. Al final, ganó la Universidad de Berkeley, pero ya ni se usaba la arquitectura de microprocesadores 80386, y el código se había quedado obsoleto.
    Ese código no obstante se uso como base para otros so que si usamos a día de hoy: FreeBSD, OpenBSD, NetBSD, MacOS.
- GNU : Montaron todo lo necesario para un SO:
  - Compiladores: GCC
  - Shell: Bash
  - Librerías: glibc
  - interfaces gráficas: X11, Gnome
  - Juegos: chess
   No valieron para montar una cosa: KERNEL.
- Linus torvalds.. hasta los huevos de que no hubiera una altiernativa libre a Unix®... se puso a montar un kernel desde 0, y lo llamó Linux.
- GNU/Linux: El sistema operativo completo que usamos hoy en día, con el kernel de Linux y el resto de componentes de GNU.
- Hoy en día, Linux lleva una evolución totalmente independiente a la evolución de Unix®... 

# POSIX

- FS de un Sistema operativo UNIX:
   / 
    bin/   -> binarios ejecutables
    etc/   -> archivos de configuración
    home/  -> directorios personales de los usuarios
    lib/   -> librerías compartidas
    tmp/   -> archivos temporales
    usr/   -> programas y librerías de usuario

- Modelo de permisos : 
    - Usuario propietario
    - Grupo propietario
    - Otros usuarios

    Permisos:
    - Lectura (r)
    - Escritura (w)
    - Ejecución (x) 



Usuario: alumno1
Dominio: dominio-alumno1                admin
    ^
    Proyecto: proyecto-alumno1          admin



---

Niveles de agrupamiento lógico dentro de un clsuetr de Openstack:

- Dominio: Agrupamiento lógico de usuarios y proyectos. Es un ámbito de administración de identidades. Un usuario pertenece a un dominio, y un proyecto pertenece a un dominio. Un usuario puede tener acceso a varios proyectos, pero siempre dentro del mismo dominio.
- Proyecto: Agrupamiento lógico de recursos. Es un ámbito de administración de recursos. Un proyecto puede tener recursos de cómputo, redes, almacenamiento, etc. Un proyecto puede tener usuarios asociados con diferentes roles.