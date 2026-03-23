
Usuario:                              LABs
    Nombre:     alumnoX
    Dominio:    dominio-alumnoX
    Proyecto:   proyecto-alumnoX
    Role:       admin

---

Proyecto Keystone
    1 dominio          Lo creamos con el único usuario que tenemos con capacidad de crear dominios : alumnoX
        Nombre:        dominio-alumnoX-cliente
    3 usuarios         El primero de esos usuarios también lo creamos con el usuario alumnoX
        Nombre:         alumnoX-manager
        Dominio:        dominio-alumnoX-cliente
        Role:           manager                      Asignado a nivel de dominio

        Nombre:         alumnoX-operator
        Dominio:        dominio-alumnoX-cliente
        Role:           member                       Asignado a nivel de proyecto: proyecto-alumnoX-cliente
        Nombre:         alumnoX-monitoring
        Dominio:        dominio-alumnoX-cliente
        Role:           reader                       Asignado a nivel de proyecto: proyecto-alumnoX-cliente
    
    1 proyecto          Lo creamos con el usuario alumnoX-manager
        Nombre:         proyecto-alumnoX-cliente
        Dominio:        dominio-alumnoX-cliente
        Role:           manager

Proyecto Glance

    Subir un par de imágenes a glance en vuestro proyecto:
    - CirrOS    PUSH
    - Ubuntu    PULL
    La subida la hicimos con el usuario alumnoX-operator, que es el que tiene permisos de member en el proyecto-alumnoX-cliente
    Vimos que el usuario alumnoX-monitoring no tiene permisos para subir imágenes, pero si podía verlas.

Proyecto Swift

    Crear un contenedor de objetos con el usuario alumnoX-operator
    Subir un par de objetos al contenedor con el usuario alumnoX-operator
    Ver los objetos con el usuario alumnoX-monitoring, que tiene permisos de reader en el proyecto-alumnoX-cliente

---

# Neutron

Es el componente que gestiona las redes.

Keystone: Identidades y servicios
Almacenamiento:
    - Cinder: Volúmenes
    - Swift: Objetos
    - Glance: Imágenes
    - Manila: NFS
Computo: 
    VMs:
      - Nova: Compute        <<<<<<
        Dependencias:
            - Glance: Imágenes de las VMs
            - Cinder: Volúmenes para las VMs (persistencia)
            - Neutron: Red para las VMs
    Hierros:
      - Ironic: Baremetal 
    Contenedores:
      - Zun: Contenedores (IaaS)
      - Magnum: Orquestación de contenedores (PaaS) . Kubernetes

Las redes dentro de un cloud no son redes físicas. Son redes virtuales, que se crean y gestionan con software. Neutron no es el componente que se encarga de crear y gestionar esas redes virtuales. Necesitaremos en el cluster un backend de redes, que es el que realmente crea y gestiona las redes virtuales. Neutron me da una capa por encima del backend de redes: Autoservicio, automatización... La capa cloud.

Como backends tenemos varias opciones:
- Linux Bridge        <- Esto es muy básico, A veces en labs lo usamos para no complicar mucho la instalación.
- Open vSwitch (OVS)
- OVN
- SR-IOV
- Vendor specific (Cisco, Juniper...)

Esas redes virtuales que alguno de esos programas gestionará, son redes que se apoyan sobre red física.

Vosotros tenéis RHOSO.
Estos proyectos des despliegue de Openstach (RHOSO, openstack-helm, kolla-ansible...) nos ofrecen por un lado procedimientos de instalación, pero también una serie de decisiones de diseño ya tomadas. Qué backend se usa para redes, almacenamiento, computo... En el caso de RHOSO, el backend de redes que se usa es OVN.
Aunque OVN a su vez se apoya sobre OVS, que es el programa que realmente crea y gestiona las redes virtuales.

    RHOSO:      Neutron -> OVN -> OVS -> Redes virtuales
    En el lab:  Neutron -> OVS -> Redes virtuales

# OVS: Open vSwitch (NO HABLAMOS TODAVIA DE OPEN V SWHITCH)

Toda máquina tiene varios interfaces de red. Y tiene una o varias NICs.

NIC: Network Interface Card (físico). Es la tarjeta de red física que tiene la máquina. Es el hardware que se encarga de enviar y recibir paquetes por la red física.

Interfaz de red: (lógico) Es lo que el SO usa para conectarse a la red y mandar y recibir paquetes. Puede ser un interfaz físico, que se apoya sobre una NIC, o puede ser un interfaz virtual, que se apoya sobre un programa de software.
En el caso de virtuales, ese programa es el que crea y opera con esos interfaces virtuales. 

En toda máquina encontramos al menos 2 interfaces de red:
- El interfaz de red físico, que se apoya sobre la NIC. Es el que se conecta a la red física. ETH, ENP0S3, etc
- El interfaz de red de loopback (127.0.0.0), que es un interfaz virtual que se apoya sobre el software del sistema operativo. Es el que se usa para la comunicación interna de la máquina consigo misma. Aquñi tenemos el famoso nombre de host localhost -> 127.0.0.1

En este caso, la red virtual de loopback es una red que no se apoya sobre una red física. De hecho es su propósito, poder conectar programas DENTRO DE MI COMPUTADORA entre si por "red", sin necesidad de salir/tener a la red física.

A nivel de servidores luego hacemos cosas raras:

    NIC -> Presentada varias veces al switch físico con distintas mac address.
            Toda tarjeta de red admite virtualización a nivel de hardware, lo que permite presentar esa tarjeta de red física varias veces al switch físico, con distintas mac address. 
            Con eso obtengo varias IPs en la red de fuera.
            Por ejemplo puedo usar cada una de esas en una VM. O asociarlas a distintos procesos que corren en la máquina física.
    
    Puedo hace lo contrario. Presentar varias tarjetas de red físicas al switch físico con la misma mac address. Eso se llama bonding, y se hace para:
        - obtener redundancia: Si una tarjeta falla, hay otra que sigue funcionando
        - obtener más ancho de banda: Si tengo 2 tarjetas de 1Gbps, puedo hacer bonding y obtener 2Gbps (requiere configuración en el switch físico)

La iterfaz de loopback es un interfaz virtual que no se apoya sobre una red física. Por tanto, podré conectar a ella programas DENTRO DE MI COMPUTADORA. Peri y si quiero conectar programas que están en otras máquinas?  Opciones:
- Conectarlas a mi red física (interfaz eth0)
- Montar una red virtual que se apoye sobre mi red física.
  Ya no estoy virtualizando la NIC, sino que estoy virtualizando la red física.
  Hago que por un cable de red físico puedan ir paquetes de varias redes virtuales distintas, y que cada una de esas redes virtuales pueda conectar a programas distintos.
  Hay muchas formas de implementarlo, por ejemplo con etiquetas VLAN.. esto es algo que el switch físico tiene que entender y gestionar. Claro.. si en caso que quiera que esa virtualización la gestione el switch físico que tengo. 
  Pero hay otras opciones, como tener programas en las distintas máquinas que tengo enchufadas sobre la red física, y que esos programas creen y gestionen esas redes virtuales. Hagan una especie de túneles virtuales sobre la red física, y hagan que por esos túneles virtuales puedan ir paquetes de varias redes virtuales distintas, y que cada una de esas redes virtuales pueda conectar a programas distintos. Esto es lo que hace OVS.

                                    Red física
                    -----------------------------------------------------------
Máquina 1 ->                                                                          <- Máquina 2
           OVS                                                                   OVS
                    -----------|       |------------------|          |---------
                                    ^                           ^
                                 Máquina 3                   Switch


Dentro de una red (arquitectura de red)... hay varias capas: Modelo OSI
- Capa 2 (L2) es quién gestiona las direcciones MAC y el envío de paquetes dentro de una misma red. Es la capa que gestiona OVS.
- Capa 3 (L3) es quién gestiona las direcciones IP y el envío de paquetes entre redes distintas. 

# OVS

Open Virtual Switch es un programa que se encarga de crear y gestionar redes virtuales a nivel de capa 2 (L2). Es decir, es el programa que crea y gestiona las direcciones MAC y el envío de paquetes dentro de una misma red virtual.
Cuando en nuestro cloud creemos una SUBNET (red a la que pinchar máquinas), esa SUBNET se apoyará sobre una red virtual que habrá creado OVS. Y esa red virtual se apoyará sobre la red física que tenemos en el cluster.
Es decir, no vale con una der virtual tipo la red de loopback, que no se apoya sobre una red física.

    Nodo1 Compute               Nodo2 Compute               Nodo3 Compute
     VM1                           VM2                              VM3
      |                             |                                |
      +-----------------------------+--------------------------------+

Nuestro cluster de nodos físicos ya estará comunicado entre si por una red física. Aquñi pasa algo curioso.
Cuando trabajo con kubernetes (y es la mayoría de las instalaciones hoy en día de OpenStack), los nodos del cluster están conectados entre si mediante una red física... pero kubernets crea una red virtual que se apoya sobre esa red física, y es la que realmente usan los programas de kubernetes para comunicarse... Esa red virtual me asegura que el trafico entre los nodos del cluster se mantenga aislado dentro de la red física.


    +------------ Red de mi empresa (192.168.0.0/16)
    |
    ++=Nodo1        Aunque comparten HW (Red física), los nodos hablan entre si por una red virtual que se apoya sobre esa red física.
    ||              En un canal de comunicación aislado dentro de la red física.
    ++-Nodo2
    ||
    ++-Nodo3

En este caso, al montar la red virtual de openstack haremos virtualización sobre la virtualización que ya hace kubernetes. Es decir, tendremos una red virtual de kubernetes que se apoya sobre la red física, y sobre esa red virtual de kubernetes montaremos otra red virtual de openstack que se apoya sobre la red virtual de kubernetes.


Similes:
    Swift: Almacenamiento de objetos
    Swift es el componente que se encarga de crear y gestionar el almacenamiento de objetos.
    La pregunta es.. quien realmente (en última instancia) crea y gestiona el almacenamiento de objetos? CEPH
    Swift me da una capa por encima de ceph: Autoservicio, automatización... La capa cloud.

    Nova: Eso de las máquinas virtuales
    Nova es quien crea y gestiona VMs? NO
    Quien las gestiona es un hipervisor: KVM, Xen, HyperV... Nova me da una capa por encima del hipervisor: Autoservicio, automatización... La capa cloud.


Dentreo del Openstack, Usermos OpenVSwitch para:
- Montar switch virtuales dentro de cada nodo compute: br-int
- Montar switch virtuales dentro de cada nodo compute para conectar los br-int entre si (esos se apoyan sobre la red física): br-tun


    Dentro de un nodo, tengo un switch virtual... con sus puertos (agujeros donde enchufo cables de MVs): br-int
    Tenemos además otro switch virtual que se apoya sobre la red física (tiene un cable conectado a la red física), y que se encarga de conectar los br-int de los distintos nodos entre si: br-tun

Esto es una fase 1. Cuando implemento esto, lo que consigo es tener MVs conectadas entre si. Que puedan hablar entre ellas.
Una fase 2 es que esas máquinas tengan conexión a una red de fuera del cluster (para conectar con otros servidores que no tenga en openstack... o para poder salir a internet). 

Lo primero que necesito poder conectar esos switch virtuales con la red física. Eso lo hace también el OVS. Monta lo que se llama un puente (bridge) entre el switch virtual y la red física. Es decir, hace que el switch virtual se comporte como si fuera un puerto más de la red física. Se llaman br-ext.


Dentro de un nodo

            Nodo 1                                                      Nodo 2
    ------------------------------                        ------------------------------
                                   Esta comunicación se 
                                   apoya en red física
                                   Mediante un túnel virtual 
                                   que hace OVS
        Switch virtual br-tun ------------------------------- Switch virtual br-tun
               |                                               |
        Switch virtual br-int                               Switch virtual br-int ------+
        |   |   |   |   |                                   |   |   |   |   |           |                           
        VM1 VM2 VM3 VM4 VM5                                 VM6 VM7 VM8 VM9 VM10        |
                                                            |                           |
        Switch virtual br-ext                               |  Switch virtual br-ext ---+
                                                            |           |
        -+-------------------------+------------------------+------------------------------ red de mi empresa 
         |                         |                                                        (puede ser la misma red física que 
         Otros servicios        router                                                       conecta los nodos entre si
                                   |                                                         o puede ser otra red física distinta)
                                Acceso a internet


Resumiendo: OVS es un programa que instalaré en cada nodo del cluster que vaya a ser nodo compute, y que se encargará de crear y gestionar las redes virtuales a las que se conectarán las VMs. Esas redes virtuales se apoyarán sobre la red física que conecta los nodos entre si, y OVS se encargará de hacer esa conexión entre la red virtual y la red física. Además, OVS también se encargará de conectar esas redes virtuales con la red de fuera del cluster, para que las VMs puedan salir a internet o conectar con otros servidores que no estén en openstack.

La cosa... es que OVS tiene comandos de muy bajo nivel... Son comandos complejos.

Neutron tiene capacidad de hablar con OVS. Pero en ese caso, quien mete los conceptos de Red Virtual, Subnet, Router... es Neutron. OVS solo se encarga de crear y gestionar las redes virtuales a nivel de capa 2 (L2) que se apoyan sobre la red física, y de conectar esas redes virtuales con la red física y con la red de fuera del cluster. Neutron me da una capa por encima de OVS: Autoservicio, automatización... La capa cloud.

Una forma adicional de montar esto es usar OVN.

# OVN: Open Virtual Network

Es una capa por encima de OVS. Es decir, es un programa que se apoya sobre OVS para crear y gestionar redes virtuales a nivel de capa 2 (L2). 

Este programa define conceptos de más alto nivel que OVS, como red virtual, subnet, router... y se encarga de traducir esos conceptos a comandos de OVS para crear y gestionar las redes virtuales a nivel de capa 2 (L2) que se apoyan sobre la red física, y de conectar esas redes virtuales con la red física y con la red de fuera del cluster.

OVN es un programa con una base de usuarios mucho mayor que Openstack. Es muy estable, con una comunidad muy grande, y con un desarrollo muy activo. 

Neutron tiene por asi decirlo su propia implementación de algo muy similar a OVN. Este programa trabaja con el concepto de Agente de red. Eso es la forma más simple de montarlo (lo que tengo yo en el cluster del lab)

Otra forma de montarlo es quitar de neutron esos agentes y que ese trabajo lo delegue a OVN. Esto es lo que hace RHOSO, y es la forma más común de montarlo en producción. La gestión de todo ese entramado es compleja. Y crear un programa que haga eso es complicado (es montar algo así como OVN). Neutron tiene un programa como OVN dentro (el agente de red), pero no es tan bueno como el OVN real.

OVN es un proyecto muy ampli, muy usado, muy probado, con mucha funcionalidad. Los agentes de red de neutron son una implementación propia de algo muy similar a OVN, pero no es tan bueno como el OVN real. En instalaciones más fuertes, más de entornos de producción se suele montar OVN, y se delega en OVN la gestión de las redes virtuales a nivel de capa 2 (L2) que se apoyan sobre la red física, y de conectar esas redes virtuales con la red física y con la red de fuera del cluster. 

Neutron se queda con la capa cloud, con el autoservicio, la automatización... pero la parte de crear y gestionar las redes virtuales a nivel de capa 2 (L2) se delega en OVN, que es un programa mucho mejor para eso que los agentes de red de neutron.

    NEUTRON (+agentes) -> OVS -> Quién crea/gestiona los bridges virtuales, los puertos virtuales, las conexiones entre los nodos...
    NEUTRON -> OVN -> OVS <- RHOSO

---

Dicho esto. OVN y OVS no son las únicas alternativas. Ni el optar por esto implica que no pueda optar en para otras cosas. Por ejemplo:
- SR-IOV: Es una tecnología de virtualización de red a nivel de hardware. Permite que una tarjeta de red física se presente varias veces al switch físico con distintas mac address, y que cada una de esas presentaciones se asocie a una VM distinta. 
  Esto quita de en medio programas. Es más complejo... Pero para casos donde necesito un rendimiento muy alto, es una opción a tener en cuenta.
- Vendor specific: Cisco, Juniper... Tienen sus propias soluciones de virtualización de red

---

# Desde el punto de vista de neutron.

CLOUD(Basado en virtualización)                                   ENTORNO TRADICIONAL
Nuestra comunicación con neutron se basa en 4 conceptos:
- Red virtual                                                     -> Red física (CABLES)
- Subnet                                                          -> Subred que monto sobre la red física (VLAN, VXLAN...)
  - Aquí es donde tengo CIDR, DHCP, DNS...                           Aquí es donde tengo el CIRD, DHCP, el DNS... para esa subred   
    para las máquinas virtuales.
    Tiene un switch virtual asociado
- Router
    Conectar a una red externa (con o sin internet)
    Conectar varias subnets entre si
- Puertos (entradas RJ45 a los switches virtuales)
- Grupos de seguridad
  Reglas de firewall... Pero no firewall a nivel de máquina virtual.
  Firewall a nivel de RED. 
- Floating IPs
  IPs que puedo asociar a las máquinas virtuales para que conectarlas con la red de fuera del cluster. 

    NAT 1:1
    NAT/Port forwarding

---
Cuando se instala un cluster, el administrador que hace la instalación crea ya algunas redes en neutron.
- Provider
- External. Las redes external son a su vez redes provider.

Las redes provider son redes que existen fuera de Openstack y que las registro en neutron. No es que use la red física como capa de transporte... sino es la red física registrada en neutron.
Esto es lo que me permite conectar máquinas a la red física directamente!

Cuidado aquí con "red física" . Realmente no tiene porque ser red física.. es una red que existe fuera del cluster. No está gestionada por neutron.
Lo que hacemos es conectarnos a ella (NIC).

Nos sirven para comunicarnos con máquinas/servicios que no estén en openstack. O para salir a internet.
Si una red provider tiene acceso a internet, la puedo registrar como red external, y así usarla para conectar mis máquinas virtuales a internet.

Cuando luego veamos cómo conectar una red interna a internet, veremos que tenemos que configurar un router. Y ese router tiene que tener una puerta de enlace (gateway) que apunte a una red marcada como "external". Y esa red external tiene que ser una red provider, porque el router tiene que poder salir a la red física para conectar con internet.


---

SR-IOV

Conectar las máquinas a la red external directamente pero por ovs. No usais FIPs. 
Pero manteneis la flexibilidad del OVS.


---

Cloud <- Toda la infra viva en el cloud. Y todo lo gestiono desde el cloud.
Si trabajo con SR-IOV... conectando a una red de fuera... hay muchas piezas de la infra que ya no estoy gestionando en el cloud.

Por SR-IOV... empiezop a perder algunas capacidades que me da el cloud. Una es los Security groups... pero no la única!

Instalación de la máquina virtual y su SO.
    Uso la NIC directamente con SR-IOV.. más vale que tenga drivers para esa tarjeta! Y 2 máquinas pueden requerir distintos drivers.

Migraciones
    Aquí no hay nada virtual! Aquí es físico!

    Necesito desconectar la tarjeta de red física de la máquina virtual donde la tengo. Que suelte IP y libere la mac-address.
    Y luego arrancar la nueva (en otro sitio) y que se conecte a la red física. Que coja la IP, la mac-address... Y que todo eso funcione.
    Eso no es 1 segundo. La máquina debe arrancar (la nueva) con el entorno preparado, que ya el SO se encuentre todo listo para trabajar.

    Si trabajo con OVS, La máquina B la puedo ir levantando.. y solo cambio el puerto lógico en el virtual switch. Eso es algo que hace OVS, y es algo que hace OVN. 
    Podría ser que en ese impás de unswitch / switch con ovs tenga un microcorte.... mínimo.

    Pero con el SR-IOV, el corte es mucho mayor. Porque tengo que apagar la máquina A, desconectar la tarjeta de red física, arrancar la máquina B, conectar la tarjeta de red física... y eso no es nada rápido.


        VM1 (IP en la interna) 
        |
    ------------------------- internal network en neutron ------------------------------------------------------------- VIRTUAL OVS
        |
        br-int
        |
        br-ext  
        |
        router  +  FIP (al puerto: NAT)                                             VM2 (IP externa dentro)
        |                                                                            |
    ------------------------- provider network registrado en neutron ----------------+-------------------------------------------- VIRTUAL OVS
                    |                                                                |
                    |                                                                |
                    | - NIC BR-ext (Switch de ovs)  DHCP                             | En el puerto (modo: direct) SR-IOV
                    |                                                                |
                    |                                                                |
    ------------------------- provider network (nos referimos a una red preexistente fuera de openstack) ------------------------- REAL


Lo que cambia es la NIC
    En SR-IOV, la NIC de la máquina virtual es una NIC física que se presenta varias veces al switch físico con distintas mac address, y que cada una de esas presentaciones se asocia a una VM distinta.

    En OVS, la NIC de la máquina virtual es una NIC virtual que se apoya sobre el software del nodo compute, y que se conecta a un switch virtual (br-int) que se apoya sobre la red física mediante otro switch virtual (br-ext) y un router virtual.

El concepto del SR-IOV es como que siempre existe.
El tema es quién lo gestiona!

Le puedo dejar a la VM que lo gestione ella, es decir, le doy a la VM acceso directo a la tarjeta de red física virtualizada (usando virtualización propia de hardware, con macaddress propio), y que la VM se encargue de coger IP, mac address... y de gestionar esa conexión con la red física. Eso es lo que se llama modo direct. 

O, puedo dejar a OVS que gestione esa conexión con la red física (que aplique el el SR-IOV), y que la VM se conecte a OVS mediante una NIC virtual, y que OVS se encargue de conectar esa NIC virtual con la red física mediante una NIC física virtualizada (usando virtualización propia de hardware, con macaddress propio). Eso es lo que se llama modo switch.


                                            NIC física en el "NODO"
                                                Esa NIC la puedo presentar a la red externa con multiples mac address (SR-IOV)
                                                Y engaño al switch externo para que me entregue varias IPs en la red de fuera, cada una con su mac address distinta.

    Si trabajo con modo direct  en las máquinas virtuales, a ellas lo que les llega es la NIC física virtualizada (con un mac-address distinto - SR-IOV), y ellas mismas se encargan de la comunicación con el switch externo.

    La otra opción es que OVS gestione el SR-IOV. 

    VMs                        Switch OVS            Bridge OVS            Switch externo
     NIC virtual OVS  <->             <------------>  SR-IOV
       Le asigna una IP del pool          El brigde presenta la tarjeta de red física al switch externo con varias mac 
                                            address distintas, y obtiene un pool de IPs.

    Si mañana muevo la máquina, o creo otra máquina, le puedo poner el mismo puerto del OVS, y esa máquina se conecta a la red de fuera con la misma IP, la misma mac address... aunque esté en otro nodo físico distinto. Eso es algo que hace OVS, y es algo que hace OVN.


---

Si quiero varias IPs en la red de fuera, necesito varias "tarjetas de red PRESENTADAS, con sus respectivas mac address, al switch 'físico', el de fuera". 


---
Dominio cliente con proyecto cliente.
Usuario: manager, operator, monitoring

    Red internal: red-alumnoX
    subnets: 
        red-alumnoX-1   switch1                <- VM NGINX                      DCHP
        red-alumnoX-2   switch2                <- VM MARIADB                    SIN DHCP     PUERTO EN LA RED PARA ASIGNAR IP FIJA

            openstack port create -- network red-alumnoX --fixed-ip subnet=red-alumnoX-2,ip-address=<DEPENDE DEL CIDR DE LA SUBNET>  puerto-alumnoX-mariadb

            Si quisiera trabajar con SR-IOV también tengo que crear el puerto previamente, pero con el flag --binding:vnic-type direct
                OJO: Esto requiere configuración especial en nova... que en lab no tenemos.
    security group:
        Nginx : 80 433
        Mariadb: 3306
    el nginx debe ser accesible desde fuera: FIP
    Ambos deben tener salida a internet: Router + red "external" (provider)
        Las 2 las pinchamos.. pero tenemos solo un router.

En todo lo posible trabajamos con el usuario operator.

Lo ideal sería tener luego un DNS (Designate)