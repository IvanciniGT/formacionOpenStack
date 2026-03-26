NOVA
    PLACEMENT <<
HEAT
    Sintaxis YAML
    Lenguaje declarativo -> Idempotencia
    DEVOPS                      ^
    IaC -> Infraestructura como código
    Adopción de un modelo cloud -> Descentralización (autoservicio, automatización, etc)


---

VSCODE - Copilot (Microsoft)

ChatGPT, Gemini, Claude, Copilot 

Esas cosas son IAs? NO
Son chatbots que nos permiten hablar con una IA (modelo de lenguaje).

HERRAMIENTA QUE USO PARA HABLAR CON UNA IA y otra cosa es la IA en sí misma.

Cuando empieza este mundo (2022) -> ChatGPT (OpenAI) GPT 3.5 

IA: Cualquier programa que actua similar a un humano (reglas de razonamiento ... aplicadas a un dominio concreto)
Tradicionalmente hemos creado estos programas mediante código basado en reglas prefijadas (un huevo de IFs)
Otra forma es aplicar lo que llamamos machine learning.

Visión artificial: Leer una matrícula en una foto (entrar a un garaje).
Este programa es complejísimo... tanto que los humanos aún hoy nos costaría consegur desarrollarlo (y prepara billetes).
Lo que hacemos es pedirle a una computadora que genere ella el programa... y me entrega el programa = MACHINE LEARNING.

Esos programas son tan complejos, que a veces (la mayor parte.. siempre) que la computado me entrega el programa, soy (como especie) incapaz de entenderlo.

Hay varios algoritmos que usan las computadoras para crear esos programas. Lo que lo reventó todo fue el algoritmo de redes neuronales.

Además, todo camiba en el 2017 con la llegada de los transformers (Google) -> BERT -> Traductor

Ese modelo transformador (que es una arquitectura de red neuronal, es decir una forma de crear redes neuronales) es lo que se usa hoy en día para la creación de IAs.

Hay un huevo de modelos de lenguaje (que son las IAs):
- OpenAI = GPTs 3, 3.5, 4, 4.5, 5, 5.1, 5.2, 5.3, 5.4
           O1, O3 (modelos de razonamiento avanzado) 
- Google = Gemini (A su vez, el chatbot de google también se llama Gemini)
- Los mejors modelos con mucha diferencia a día de hoy. para tareas del mundo IT son los de Anthropic (Claude 1, 2, 3, 4)

No todos los modelos son iguales... una cosa muy importante es el tamaño del modelo (se mide en número de parámetros ~ tiene que ver conceptualmente con la cantidad de neuronas que tiene dentro).

Los modelos gordos hoy en día están en el orden de os 100 millardos de parámetros (lo que los americanos llamaría 100B)
    100.000.000.000

    Esos modelos tardan la vida en entrenarse... Se requieren millones de horas de cómputo (en GPUs) para entrenar un modelo de este tamaño.

    Gpt 3.5 .. costó 100M de $ en electricidad... y 3 meses para entrenarse.

    A veces, para tareas simples, me interesa usar modelos sencillos (10-20 B parámetros) . Sobre todo porque son más rápidos de ejecutar... y más baratos!

Cuando empieza este mundo , con chatGPT, nos volvimos locos... Pero una vez pasado el boom! los adoptamos como una herramientas más... 
Los chatbots los empezamos a usar como "tipos listos" a los que acudir cuando tenía una duda o un problema: ASK!

Eso está muy superado! Ya no usamos así los modelos.

Hoy en día, los modelos los usamos en modo AGENTE!

Herramientas como copilot (no el chat cutre de la web. que no es tan cutre) dentro de un VSCODE, lo que me permiten es :
- Dar instrucciones a uno de esos modelos
- Que el modelo me presente un plan de trabajo
- Y que se ponga a ejecutarlo... Interactuando con mi máquina:
  - Puede gestionar (CRUD) mis archivos         \
  - Puede ejecutar comandos en mi terminal      / Puedo hacer lo que quiera!

Aquñi hay que tener cuidado... que no se convierta en SKYNET (Terminator). Como le dé mucha libertad y no lo controle, puede hacer cosas que no quiero (borrar archivos, etc). 

---


MV:
- Efímera:
  - En cualquier caso, neecsito HDD para almacenar la imagen del sistema operativo, los logs, etc.
  - Puedo usar:
    - HDD local (en el mismo host donde se ejecuta la MV) <- No me come red... pero no me permite live migration
    - CEPH                                                   Me permite live migration... pero me come red (y es más lento que el local ¿? o no)
- Persistentes:
  - Volumen cinder -> CEPH

--- 

# Placement:

Es un componente de Openstack que se instala independiente, pero es una dependencia de NOVA.
No vemos placement directamente en HORIZON. Simplemente NOVA LO USA.

Es el componente que se encarga decidir en qué máquina física (nodo de cómputo) se va a ejecutar cada máquina virtual.

En muchas ocasiones nos interesa dar sugerencias adicionales a placement para que tome decisiones que a mi me puedan interesar.

Placement por si solo si que mira:
- Capacidad nominal de cada nodo de cómputo (cuántas máquinas virtuales puedo ejecutar en cada nodo)
    - Cuanta RAM y CPU y Disco tiene
- Recursos disponibles efectivos en cada nodo de cómputo (CPU, RAM, HDD, etc)
    - Cuanta RAM y CPU y Disco me queda sin uso en cada nodo de cómputo

En muchos casos, no es suficiente:
- Dependencia del hardware:
  - Necesito una determinada arquitectura de microprocesador (x86, ARM, etc) ... la ISO va a ser diferente para cada arquitectura
  - Quiero una CPU más rápida
  - Quiero un host con conexión de red por tal interfaz (CEPH) (VNis Escritorios Remotos)
  - Quiero una máquina con discos más rápidos (NVMe)

    Estos de aquí, en la mayor parte de los casos los gestionamos mediante lo flavours.

    Los flavours no son solo un listado de RAM, CPU y HDD... también pueden incluir otras cosas como el tipo de CPU, el tipo de disco, etc.

        $ openstack create flavour --id m1.micro-sdd --ram 512 --disk 1 --vcpus 1
        $ openstack flavor set m1.micro-sdd --property trait:STORAGE_SSD=required
        Esos properties los asocio a los nodos.

    Lo mismo lo podemos hacer a nivel de glance... con las imágenes:

        $ openstack image set cirros --property trait:HW_CPU_X86_64=required

    Este tipo de reglas es lo que en kubernetes se llama afinidad a nivel de nodo.

    Esto hace que las VMs que necesiten unos host especiales puedan encontralos.
    Pero... eso lo que no hace es otra cosa. (lo que en kubernetes llamos los tintes taints/tolerations)

    Resulta que tengo 3 máquinas físicas con unas características especiales.
    Y tengo unas VMs que requieren de esas características especiales... En ellas pongo este tipo de "reglas de AFINIDAD"
    Pero.. esto no hace que una VM que no requiera esas características especiales no pueda ejecutarse en esos hosts...


        NODO 1          NODO 2        NODO 3        NODO 4
        CPU RÁPIDA      CPU RÁPIDA    CPU NORMAL    CPU NORMAL

        VM1 -> Requiere CPU RÁPIDA -> Se ejecuta en NODO 1 o NODO 2             Regla de afinidad a nivel de nodo (en openstack con los traits a nivel de flavor o imagen)
        VM2 -> No requiere CPU RÁPIDA -> Dónde se puede ejecutar? En los 4. Y Quiero eso? Posiblemente no...
        Si gasto las máquinas 1 y 2 con VM que no requieren CPU rápida, luego no podré ejecutar VM3 (si requiere CPU rápida) porque no hay hueco.

            Hay un concepto más avanzado que son los hosts agregates (grupos de hosts aislados Isolated). Se marcan como que solo se desplieguen en ellos las VM que requieran el trait.


- Afinidad / Antiafinidad <- Grupos de servidores

    Este tipo de reglas es lo que en kubernetes se llama afinidad o antiafinidad a nivel de pod.
    Las hay de 2 tipos, cada una: Soft y Hard (obligatoria o no obligatoria)

    Que prefiero que 2 máquinas se ejecuten en el mismo nodo de cómputo (afinidad suave) aunque si no es posible (por capacidad del nodo) que se ejecuten en nodos diferentes.

    Que por narices 2 máquinas se ejecuten en el mismo nodo de cómputo (afinidad dura) y si no es posible, que se queden sin ejecutar / pendientes de ejecutar.

  Afinidad:
    - Reducir latencia en comunicaciones.
      Tengo un sistema que tiene un programa corriendo en MV1 y otro en una MV2.
      - BBDD                MV1
      - Servidor de apps    MV2
 
  Antiafinidad:  Evitar en entornos donde sea requerido HA activo / Activo que 2 VMs que ofrecen el mismo servicio se desplieguen el mismo nodo de cómputo (si ese nodo falla, se caen las 2 VMs y el servicio se cae)

    Monto un cluster activo / Activo de MariaDB/Galera... Y lleva 3 MVs. No quiero que estén en el mismo nodo... O bueno... si no hay más remedio... en un entorno degradado.

    Lo que hago es crear un grupo de servidores (server group) y le digo que quiero antiafinidad suave.

    $ openstack server group create --policy anti-affinity --description "Servidores de BBDD para el cluster de Galera" galera-sg
    # Cuando creamos las MVs, le decimos que las queremos en ese grupo de servidores:
    $ openstack server create ...
         --hint group=galera-sg


---

Keystone: Dominios, proyectos, usuarios, roles, servicios

Almacenamiento:
- Glance: Imágenes de máquinas virtuales
- Swift: Almacenamiento de objetos (tipo S3) (Container, Object)
- Cinder: Almacenamiento de bloques (volúmenes) (Volume, Snapshot, Backup, Volume Groups, Volume Group Snapshot)
    -> CEPH

Redes:
- Neutron: Redes virtuales (Red, Subred, Puerto, Router, Floating IP, etc)

Cómputo:
- Nova: Máquinas virtuales (Server, Flavor, Keypair, etc)
  - Placement: Decide en qué nodo de cómputo se ejecuta cada máquina virtual
  
Orquestación:
- Heat: Orquestación de recursos (Stack, Template, etc)

---

Nuestras MV siempre tiene almacenamiento.
- Efimero       ***
- Persistente    > CINDER

Cinder me permite la creación de volumenes.
Al usarlo, esos volumenes los podemos usar de 2 formas:
- Volumen raíz: El volumen que se crea para la MV es el volumen raíz, es decir, el que contiene el sistema operativo <- El volumen se crea desde una imagen de glance (o desde un snapshot de otro volumen)
- Volumen adicional: El volumen se crea vacío, y luego lo monto en la MV para usarlo como almacenamiento adicional (tipo un disco duro adicional).. en este caso, tendre que decirle en que dispositivo lo monto (/dev/vdb, etc) y luego formatearlo y montarlo dentro de la MV.

---

Volume: Un volumen de bloque que puedo usar (montar) en las MVs... puede ser raíz (imágen) o adicional.

Snapshot


, Backup, Volume Groups, Volume Group Snapshot


---

RED
- Subnets
- Floating IPs
- Security groups
- Router
- Ports
