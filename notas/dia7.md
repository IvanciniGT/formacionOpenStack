
Clouds <

Keystone Usuarios, proyectos, dominios, role, permisos, descubrimiento de servicios.
Glance
Swift
Cinder
Neutron!
Nova
Heat < IaC

---

# Nova

Cómputo: Máquinas virtuales
Ironic:  Bare metal
Zun:     Contenedores

---

Conceptos que salen al trabajar con nova:
- Flavor: Es la "talla" de la máquina virtual. Define la cantidad de CPU, RAM y disco que tendrá la máquina virtual.
  Esto no lo puedo crear a nivel de proyecto, es decir, es global para toda la nube.
- Claves (KeyPair): Es la clave pública, de un par de claves pública/privada, que usamos para acceder por SSH a las máquinas virtuales LINUX. Se pueden crear a nivel de proyecto, es decir, cada proyecto puede tener sus propias claves.
- Placement: Es un componente, al mismo nivel que NOVA o NEUTRON, que se encarga de planificar dónde se van a ejecutar las máquinas virtuales.   
Para eso, mira:
    - La capacidad nominal de los nodos de computo (cuántas CPU, RAM y disco tienen).
    - La capacidad disponible de los nodos de computo (cuántas CPU, RAM y disco tienen disponibles).
    - Las reglas de afinidad/anti-afinidad que hayamos definido (por ejemplo, que dos máquinas virtuales no se ejecuten en el mismo nodo de computo).
    - Las políticas de planificación que hayamos definido (por ejemplo, que se ejecuten en el nodo de computo con más capacidad disponible).
- Máquinas Virtuales efímeras.
  - Para una BBDD no quiero una máquina virtual que se borre al apagarla, sino que quiero una máquina virtual persistente. Para eso, tengo que crear un volumen con CINDER y arrancar la máquina virtual desde ese volumen.
  - Para un escritorio remoto, no me importa que la máquina virtual se borre al apagarla, por lo que puedo arrancar la máquina virtual desde una imagen de GLANCE. Si acaso, le puedo poner un nfs a una carpeta en red con sus documentos.

# Backend de nova.

    En Neutron, neutron aporta la capa de autoservicio, automatización... capa cloud.. pero el tinglao de redes, quién lo gestiona realmente?
        OVS. En el caso de ir por RHOSO:
            NEUTRON -> OVS
            NEUTRON -> OVN -> OVS

            OVS = Open vSwitch, es un software que implementa un switch virtual. 
                  En cada máquina necsito montar varios switches virtuales.
                  Pero es máquina a máquina, hay que irlo configurando.
                  Dicho de otra forma, si trabajasemos con OVS, tendriamos que ejecutar 500 comandos para configurar los switches virtuales en cada nodo de computo.
            OVN = Open Virtual Network, es un software que implementa una red virtual. 
                  En cada máquina necsito montar un agente de OVN, que se encarga de configurar los switches virtuales en cada nodo de computo. 
                  Dicho de otra forma, si trabajasemos con OVN, tendriamos que ejecutar 1 comando para configurar el agente de OVN en cada nodo de computo, y el agente de OVN se encargaría de configurar los switches virtuales en cada nodo de computo.

            NEUTRON -> OVS. En este caso, Neutron hace uso de algunos "agentes" que se encargan de configurar
                            los switches virtuales en cada nodo de computo. 
                    -> OVN -> OVS. En este caso, Neutron no usa sus agentes, usa OVN para la gestión del OVS.
                                   Y OVN es un producto muy estable, muy probado, muy maduro, que se encarga de gestionar el OVS.
    
    En Cinder, Swift, Glance, el backend es CEPH. Es decir, Cinder, Swift y Glance hacen uso de CEPH para el almacenamiento de los datos.
    Nos dan la capa cloud (autoservicio, automatización...) pero el tinglao de almacenamiento, quién lo gestiona realmente?
        CEPH.

    En nova pasa lo mismo!
    Nova no es quien crea la VMs. Nova aporta la capa de cloud (autoservicio, automatización...) pero el tinglao de la gestión de las VMs, quién lo gestiona realmente?

        Hay una cadena de componentes (similar a lo que ocurre en neutron):

            - La ejecución de las máquinas virtuales.                                                   QEMU/KVM
              - Aceleración de la ejecución de las máquinas virtuales por hardware (VT-x, AMD-V).       KVM
            - La gestión de las máquinas virtuales.                                                     Libvirt

        Nova  -> Libvirt     -> QEMU [+KVM]
        [Zun  -> ContainerD  -> runc]

        Pero... aquí hay más.
        Porque una VM no es solo correr programas, también es tener un cacho del HDD donde poder hacer el despliegue al menos de la ISO.
            Ojo aquí! Esto es distinto del concepto de persistencia de las máquinas virtuales.
            Siempre necesito un cacho de HDD para desplegar la máquina virtual, aunque esa máquina virtual sea efímera.
            Si quiero que esa máquina pueda sobrevivir a un apagado, entonces necesito un volumen de CINDER para que esa máquina virtual pueda arrancar desde ese volumen.
        
        Esto implica una cosa. 
        No necesito solo un backend para la ejecución de las máquinas virtuales, sino que también necesito un backend para el almacenamiento de las máquinas virtuales.
          - Ese backend puede ser múltiple:
            - El propio HDD de los nodos de computo. En este caso, cada nodo de computo tiene un cacho de HDD donde se despliegan las máquinas virtuales que se ejecutan en ese nodo de computo. <<<
              En este caso tenemos migración en vivo? 
                Huele a que no! Pero si.
                Es un cabroncete el Nova... copia el archivo del HDD de una máquina a otra por ssh (scp).
            - Un backend de almacenamiento compartido, como puede ser CEPH. 
                Eso me permite hacer las migraciones en vivo sin tener que copiar el archivo del HDD de una máquina a otra por ssh (scp), porque el backend de almacenamiento compartido es accesible desde todos los nodos de computo.
            - Si luego quiero máquinas persistentes, entonces cinder es el backend de almacenamiento de las máquinas virtuales, y cinder hace uso de CEPH para el almacenamiento de los datos.


---

Pregunta: CEPH me puede dar más rendimiento que un HDD interno? 
          CEPH Esta usando también los HDD internos de los nodos de computo para almacenar los datos... y además hay trafico por red.
          Lo que pasa es que ceph distribuye los datos entre varios nodos, por lo que puede ofrecer un rendimiento superior al de un HDD interno, aunque también depende de la configuración de CEPH y del tipo de carga de trabajo que se esté ejecutando.

          Cuidado ! Lo limitante puede ser la red.

            HDD interno -> 150 MB/s
            SSD interno -> 500-600 MB/s
            NVME interno -> 2000-3000 MB/s

         Ahora... una red de 1Gb/s tiene un rendimiento máximo de 125 MB/s.
         Otra cosa es que tenga una red de 10Gb/s, que tiene un rendimiento máximo de 1250 MB/s.
         O que tenga una red de 40Gb/s, que tiene un rendimiento máximo de 5000 MB/s.

---

Al final, el modelo CLOUD lo que me permite es DESCENTRALIZAR la gestión de los recursos (Autoprovisionamiento)

Autoprovisionamiento/Autoservicio != Centralización de la gestión de los recursos.

Antes tenía departamentos enormimasticos de IT, con subdepartamentos:
    - Redes
    - Virtualización
    - Almacenamiento
    - Seguridad
    - BBDD
    - ...

Y eso es lo que queremos cambiar con el modelo CLOUD!
Lo que quiero es quitar de la emrpesa todos esos departamentos. Dejarlos en un mínimo.

No quiero tickets para pedir recursos, quiero que los usuarios* puedan autoprovisionarse los recursos que necesiten, sin tener que pasar por un departamento de IT.

* usuarios = usuarios de mi cloud = equipos que están desarrollando sistemas que tienen que poner en entornos de producción (con sus correspondientes entornos de preproducción, desarrollo, etc...).

Este modelo tiene ventajas e inconvenientes.

Ventajas:
- Reducción de personal CENTRAL/ automatización
- En uno público, me quito la infra. Y Además me quito de inversiones iniciales... los escalados serán más fáciles.
- Contabilidad de costes. En un modelo tradicional, es difícil saber cuánto cuesta cada proyecto. Tengo que repartir en el los costes de servicios centrales... y eso es complejo.
- Mucho más ágil.. yo me lo guiso  yo me lo como. Que necesito una VM... entro al cloud y en 10 minutos lista.
  En un entorno centralizado.. Me llevo más de 10 minutos abriendo el ticket.. Y con seruete en 3 días tengo algo. 
  
Inconvenientes:
- Pérdida de control. En un modelo tradicional, el departamento de IT tiene un control total sobre los recursos. En un modelo CLOUD, los usuarios pueden autoprovisionarse los recursos que necesiten, lo que puede llevar a un uso ineficiente de los recursos.
- Posible falta de estandarización en la gestión de los recursos. En un modelo tradicional, el departamento de IT puede establecer políticas y procedimientos para la gestión de los recursos. En un modelo CLOUD, cada proyecto es un reino de taifas, lo que puede llevar a una falta de estandarización en la gestión de los recursos.
    
    Aquí empieza a ponerse de manifiesto la importancia de HEAT! Plantillas... y esas plantillas me ayudan a estandarizar la gestión de los recursos. 

---
IaC = Infrastructure as Code

No solo es tener la infra en un fichero, como si fuera código, sino tratarlo como código:
- Control de versiones
- Pipelines de integración continua/despliegue continuo (CI/CD)
- Testing automatizado

---
    La decisión no ha sido cambiar VMWare por Openstack, como si fueran herramientas reemplables directamente.
    Eso sería reemplazar VMWare por Redhat Virtualization.

    La decisión es mucho más profunda. Es cambiar la forma de trabajo, la forma de gestionar los recursos.
    Ir hacia la descentralización de la gestión de los recursos, hacia el autoprovisionamiento, hacia la automatización, hacia la estandarización de la gestión de los recursos, hacia la contabilidad de costes, hacia la agilidad... y todo eso lo que me ha dado es un modelo CLOUD.


---

Red: alumnoX-red
Subnet1: alumnoX-subnet1
Subnet2: alumnoX-subnet2
Router: alumnoX-router (pinchando las 2 subnets al router y además poniéndole una puerta de enlace al router para que tenga acceso a internet)
FloatingIP para una VM (la llamamos nginx) que esté en la subnet1, para que tenga acceso a internet y pueda ser accedida desde internet.
Puerto: mariadb-port, para que la VM de mariadb pueda ser accedida desde la VM de nginx, aunque estén en subnets distintas. IP FIJA
        La boca del switch + NIC de la VM = Enlace
Security Group 1 para la mv del nginx!
Security Group 2 para la mv del mariadb!

---


Sease un puerto llamado puerto-nginx-alumnox, que esté conectado a la red alumnoX-red, con una IP fija en la subnet alumnoX-subnet1, y con el security group security-group-nginx-alumnox.

puerto-nginx-alumnox:
    nombre:     puerto-nginx-alumnox
    red:        alumnoX-red
    subnet:     alumnoX-subnet1
    seguridad:  security-group-nginx-alumnox

vm1: 
    nombre:     vm-nginx-alumnox
    sabor:      m1.tiny
    imagen:     ubuntu-2204
    red:        puerto-nginx-alumnox
    claves ssh: claves-alumnoX
---

    --> Comandos cli... o apretar botones en el dashboard... En cualquiera de estas 2 opciones estamos usando lenguaje IMPERATIVO.

    $ openstack port create puerto-nginx-alumnox --network alumnoX-red --fixed-ip subnet=alumnoX-subnet1 --security-group security-group-nginx-alumnox

    $ openstack server create vm-nginx-alumnox --flavor m1.tiny --image ubuntu-2204 --nic port-id=puerto-nginx-alumnox --key-name claves-alumnoX


    --> En lugar de lenguaje imperativo, podemos usar lenguaje declarativo... pero de hecho, no lo hemos hecho ya?
    
    ESTO YA ERA LENGUAJE DECLARATIVO:

        puerto-nginx-alumnox:
            nombre:     puerto-nginx-alumnox
            red:        alumnoX-red
            subnet:     alumnoX-subnet1
            seguridad:  security-group-nginx-alumnox

Eso es lo que va a ir a una plantilla de HEAT.
Lo único que necesitamos aprender es la sintaxis concreta de esas plantillas.

Teniendo esa plantilla:

- Pediré que se aplique esa plantilla a mi cloud, y el cloud se encargará de crear los recursos necesarios para que se cumpla lo que he declarado en la plantilla.
- O pediré que se actualice mi cloud para seguir cumpliendo con lo que he declarado en la plantilla, y el cloud se encargará de actualizar los recursos necesarios para que siga cumpliéndose lo que he declarado en la plantilla.
- O pediré que se borre esa plantilla de mi cloud, y el cloud se encargará de borrar los recursos necesarios para que deje de cumplirse lo que he declarado en la plantilla.

Eso es otro problema posterior. Mi primer problema es definir / declarar una infraestructura. Luego miramos que hago con eso.

---

Terraform es otra liga comparado con HEAT. Me da una potencia enorme a la hora de definir estas cosas... que heat ni sueña con ella!
La sintaxis de terraform es un poco más dura que la de heat, pero a cambio me da una cantidad de funcionalidades extra que heat no tiene.

Heat está pensado para hacer despliegues completos. Soltar un stack!
Una cosa que HEAT NO PUEDE HACER, y se echa un huevo de menos es la capacidad de preguntar al cloud sobre recursos que ya existen.

Es decir, en HEAT si quiero deslegar una MV, le tengo que pasar el ID de la imagen.
En terraform podría lanzar una búsqueda al cloud (openstack) para decirle que me encuentre la última imagen que se haya subido de Ubuntu server para arquitectura de microprocesador X y que admita tal sistema de virtualización ... y me de el ID.

En HEAT hay 3 conceptos:
- Parámetros de entrada al script.                          parameters:
- Datos de salida del script.                               outputs:
- Recursos que se van a crear, actualizar o borrar.         resources:

En terraform tenemos muchos más conceptos:
- Parámetros de entrada al script.
- Datos de salida del script.
- Recursos que se van a crear, actualizar o borrar.
- Variables locales, que me permiten definir variables dentro del script que no son parámetros de entrada ni datos de salida, sino que son variables que puedo usar dentro del script para facilitar la definición de los recursos.
- Módulos, que me permiten definir bloques de código reutilizables que puedo usar dentro de mi script para facilitar la definición de los recursos. < ESTO ES CLAVE de cara a unificar/estandrizar/reaprovechar desarrollos previos.
- Data, que me permite hacer consultas al cloud para obtener información sobre recursos que ya existen, y usar esa información para definir los recursos que quiero crear, actualizar o borrar. < ESTO ES CLAVE de cara a no tener que pasarle al script cosas como el ID de la imagen, sino que el script se encargue de buscar esa información en el cloud.

---


Os comenté, cuando hicimos la intro a yaml, que yaml solo nos da una sintaxis básica.
Y os dije que cada programa que usa yaml para sus datos define un ESQUEMA propio sobre esa sintaxis básica.
En el esquema es donde se define que marcas concretas debe tener el documento, que tipos de datos se deben escribir asociados a cada marca.
HEAT ha ido evolucionando con el tiempo. Y su esquema se ha ido modificando/ampliando.
Las palabras que puedo usar actualmente son más de las que habñia disponibles hace 5 años.
En el heat_template_version es donde se indica la versión del esquema de HEAT que estamos usando, para asegurarnos de que todas las funcionalidades que queremos usar estén disponibles.


A una máquina virtual le tengo que poner un flavor.
Con HEAT tengo obligación de saber el nombre del flavour que quiero usar, y pasárselo al script.
Y dios quiera que no cambie en el futuro... si cambia ese nombre, me toca cambiar los 700 templates que tengo con ese nombre de flavor... y eso es un horror.

Con Terraform, puedo hacer una consulta (data) para preguntar cual es el flavour mas pequeño que tiene al menos lo que necesito tener (al menos 1 vCPU, al menos 1GB de RAM, al menos 10GB de disco) y que me devuelva el nombre de ese flavor, y usar ese nombre para definir la máquina virtual que quiero crear.


El flavor es:
- Cpus: 4vcpus
- RAM:  16GB
- Disco: 100GB

Imagen... Es una ISO.. lo que tu quieras.. puede estar tuneada con un básico.


Esos scripts de HEAT en terraform se llaman provisioners, y son un bloque de código que se ejecuta después de que se hayan creado los recursos, y que me permite configurar esos recursos después de que se hayan creado.

En terrafom hace años habia distintos tipos de provisioners: Puppet, Chef, Salt... Y el ssh.
Han dejado solo el de ssh... y con un mensaje claro: NO USAR LOS PROVISIONERS a no ser que sea estrictamente necesario -> ACOPLAMIENTO!


MONOLITOS: Esto era una mega app que hacia de todo.. que se desplegaba en un megaservidor de apps -> Weblogic, Websphere -> CADUCO!
Hoy en día vamos a arquitecturas de componentes desacoplados: como por ejemplo las arquitecturas de microservicios, donde cada componente es una aplicación independiente que se comunica con las demás a través de APIs. ESTO FACILITA EL MANTENIMIENTO AL EXTREMO!

Llevad estos conceptos a estos programas!

Es más.. HEAT me obliga a usar scripts cutres sh!
Y precisamentye lo que quiero es dejar el puñetero lenguaje IMPERATIVO. No solo para la creación de los recursos, sino también para la configuración de esos recursos.

Hay herramientas cojonudas para Planchado de máquinas: ANSIBLE! (Redhat)

    Jenkins (orquestador)
     v ^          v ^                                   <- Esos datos, que mando y recibo es lo que llamamos un API 
    HEAT        Ansible         Mvn             ????
    infra       Planchado       Despliegue      ????

El api es lo que uso para comunicarme con un sistema/herramienta:
- Qué le paso           parameters
- Qué me devuelve       outputs

Y mi única comunicación con HEAT es mediante parameters y outputs. Con su API.
Y dedico HEAT a lo que le tengo que dedicar! Y no usar una herramienta para propósitos que no son los suyos!

Casos de uso legítimos de los scripts de HEAT
Voy a crear una infra con HEAT.. y la plancharé con ANSIBLE.
Pero mira que ansible tiene un requisito: python en la máquina que quiero planchar. 
Y mi imagen no estoy seguro de si trae python.. o de si lo trae actualizado.
Ejecuto con heat un script que me deje la máquina preparada para el siguiente paso, que es el planchado con ansible.
Es decir, me aseguro que salga con un python actualizado, con el puerto 22 abierto, con el usuario que quiero usar para el planchado creado... y cosas así.
Ese mínimo es lo que meteré en HEAT. Ni de coña meto el planchado en heat.
Ni es la herramienta, ni me da el lenguaje maás adecuado. Y aunque lo fuera y me lo diera, no quiero crear un programa que asuma más de una responsabilidad.

# Principios SOLID de desarrollo de software

Estos los los 12 mandamientos del desarrollo. Puedo incmplirlos... pero tendrá consecuencias.. que podré aceptar o no!

Son 5:
S   SRP: Single Responsibility Principle.
O   OCP: Open/Closed Principle.
L   LSP: Liskov Substitution Principle.
I   ISP: Interface Segregation Principle.
D   DIP: Dependency Inversion Principle.


S: Principio de Responsabilidad Única (Single Responsibility Principle) <- Uncle Bob (Robert C. Martin)
Que no dice: Un módulo/programa debe tener una única responsabilidad.

Eso existe también en software... salió hace más de 50 años. A principios de los 70... después de la crisis del software.
Legiones de tios flipaos escribiendo código, cada día más... sin organización ni control.. ni buenas prácticas -> Sistemas caóticos que era imposible meterles mano.
En este momento nace la ingeniería de software, con el objetivo de poner orden en el caos.

Y ahí se definen 2 conceptos clave: Cohesión y Acoplamiento.


Un programa NUNCA JAMAS debería tener funcionaldidades que dependan de 2 actores diferentes:
Entendiendo actor como perfiles/departamentos diferentes dentro de la empresa.

Quién decide la infra que se necesita es el mismo que define cómo debe configurarse esa infra? NI DE BROMA
ENTONCES, dice el tio BOB: NI DE COÑA METAS ESAS 2 cosas en el mismo programa! SERÁ INMANTENIBLE A FUTURO
Hoy quizás sea hasta más rápido. VAS A FLIPAR !!!!!

El problemas es que en sistemas/operaciones... pasa igual en testing, hoy en día nos hemos puesto a escribir programas...
Pero no estamos palicando las buenas ideas que han ido surgiendo en el mundo del desarrollo de software... y como no estemos avispaos... preparaos que viene la crisis del la infra... y de las pruebas... Espejo de la crisis del software de hace 50 años.



Que un desarrollador haga commit con una nueva versión de su código y arranca un pipeline de ci/cd: (JENKINS)

- Crear una infra o upgradearla... si hace falta... quizás no. Pero me da igual.. como el script es IDEMPOTENTE lo ejecuto y si hay que cambiar algo se cambiará y si no, pues no. PRE!
- La plancho
- Le descargo el repo del usuario
- Compilo el programa
- Le hago pruebas: Rendimiento, funcionales...
- Si va bien, subo aquello a un repo de artefactos: NEXUS, ARTIFACTORY
- De hay, genero otra infra o la upgradeo (la de pro)



    openstack security group rule create mi_regla --protocol tcp --dst-port 22 --ingress  --remote-ip "0.0.0.0/0"
