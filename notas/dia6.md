
# Devops

Dijimos que es una cultura en pro de la automatización.
Automatización de todo lo que hay entre el DEV y el OPS, es decir, todo lo que hay en el ciclo de vida del software.

Y hay muchas cosas a automatizar.
Y salen los conceptos de CI/CD.

Integración continua y despliegue continuo: Jenkins/Azure devops

CI es tener CONTINUAmente en un entorno de pruebas (INTEGRACION) la última versión del código generada, sometida a pruebas automatizadas.
CD:
- Entrega continua (Continuous delivery): Poner mi artefacto en manos de mi cliente de forma automática, sin intervención humana.
- Despliegue continuo (Continuous deployment): Poner mi artefacto en producción de forma automática, sin intervención humana.


Esto es lo que se hace hoy en día en desarrollo.
Hace 60 años / 40 años / 20 años desarrollaba un sistema, lo instalaba en un entorno de pruebas y alguién lo probaba.
Cuando ese alguien daba el ok, se pasaba a producción.

Me puedo plantear el automatizar un pase a producción, sin intervención humana?
Es decir, que desarrollo dice, "ah... ya tengo una nueva versión de mi programa" (COMMIT a GIT con un tag de versión), y automáticamente se pase a producción? sin revisión manual? ESTO LO QUE HACEMOS HOY EN DIA!

Claro... para hacer esto hay 2 opciones:
1. Estoy muy volao!
2. Tengo una confianza enorme en lo que estoy haciendo <<<

Quien me da esa confianza: PRUEBAS AUTOAMTIZADAS! que es de lo que va CI.


---

En el futuro querré que un sysadmin, para desplegar una red, lo único que haga es abrir un puñetero VSCODE, escribir un puñetero YAML, y hacer commit en un repo de git! Y HA TERMINADO SU TRABAJO!

Y habrá un pipeline que tomara ese yaml, abrirá un opencloud de pre-producción, le pedirá a heat que lo despliegue allí,
Se ejecutarán 4 pruebas automatizadas, para ver si la red funciona... Pings, nslookup, curl, etc... Y si todo va bien, se pasará a producción! Sin intervención humana!
Eso significa que heat volverá a aplicar este yaml en el openstack de producción, y se desplegará la red en producción!
Y como parte de ese proceso, ejecutaré unos smoke test automatizados, para ver si la red funciona en producción... Pings, nslookup, curl, etc... Y si todo va bien, se quedará en producción! Sin intervención humana!

Y tendré desplegada la V1 de mi red, sin intervención humana, con pruebas automatizadas, y con un pipeline que me lo ha hecho todo!
Y dentro de un mes, me pediran un cambio. Necesitamos una máquina adicional para un rabbit.. y necesito un puerto con ip fija.
Y yo abriré el mismo fichero yaml, le meteré el puerto (la descripción del puerto)... y hago commit! Y he acabado!

Y heat desplegará de nuevo el yaml en el entorno de pruebas.
Y atención! Confiemos que el yaml / script sea idempotente... es decir, que no falle si la red existe... porque existirá !
Necesito que heat se de cuenta que todo está ya creado igual... salvo el puerto nuevo... y solo cree el puerto nuevo! Y no me toque nada más!

Por eso no hago un script imperativo (.sh, .bat) sería infumable! Usamos un lenguaje declarativo que es idempotente, y heat se encarga de hacer lo que hay que hacer, sin tocar lo que no hay que tocar!

Y acabaré con la V2 de la infra desplegada, sin intervención humana, con pruebas automatizadas, y con un pipeline que me lo ha hecho todo!
Y quizás esto tendrá un encaje aún mucho más amplio de lo que a día de hoy podemos ni imaginar!

Porque lo ideal es que tenga un equipo de trabajo montando una app / servicio.
Y les he dado un usuario de openstack.
Y ellos montan su app (código) y ellos definen la infra que necesitan (no que me hbran un puñetero ticket).
Y como parte del despliegue de su app, se despliega la infra que necesitan, sin intervención humana, con pruebas automatizadas, y con un pipeline que me lo ha hecho todo!
Y cada versión de su app, irá asociada a una versión de la infra.

Y sistemas queda descentralizado.
Ya no hay un departamento de redes.
Hay un equipo que está desarrollando una app/sistema... y dentro tienen un tio experto en redes / clouds (seguramente un sysdamin reciclado) que se encarga de definir la infra que necesitan, y de mantenerla, y de hacerla evolucionar, sin intervención humana, con pruebas automatizadas, y con un pipeline que me lo ha hecho todo!

ESTE EL MUNDO DE HOY!

terraform -> Clouds (AWS, Azure, GCP, Openstack, etc...)
HEAT es el terraform de openstack!

Y Openstack me permite montar mi propio AWS, mi propio Azure, mi propio GCP.

---

Keystone, swift, glance, neutron, cinder?, heat?

- NOVA

Un servicio dentro de openstack para cómputo basado en máquinas virtuales.
Ironic es un servicio dentro de openstack para cómputo basado en máquinas físicas (bare metal).
Zun es un servicio dentro de openstack para cómputo basado en contenedores.

# Dependencias con otros servicios

- Keystone: para autenticación, autorización y descubrimiento de servicios.
- Glance: para almacenar imágenes de máquinas virtuales.
- Neutrón: para gestionar redes, subnets, puertos, security groups, etc...
- Cinder?: para gestionar volúmenes de almacenamiento en bloque.
  Puedo tener VM efímeras, sin almacenamiento persistente... o puedo tener VM con almacenamiento persistente, y ese almacenamiento lo gestiona cinder. Muchas veces quiero ambas!
  - Máquina virtual donde ponga una BBDD -> Quiero persistencia -> Cinder
  - Una máquina virtual para un escritorio remoto -> No necesito persistencia -> No necesito cinder
                                                  -> En esa máquina si acaso le monto una unidad de almacenamiento en red (NFS) para guardar los datos, pero no necesito cinder.
- Placement: para decidir en qué nodo físico se va a ejecutar cada máquina virtual. Podremos dar indicaciones, sugerencias, restricciones, etc... para que placement tome la decisión de dónde ejecutar cada máquina virtual.
  Tiene en cuenta las capacidades de cada nodo físico, y las necesidades de cada máquina virtual. El estado real de cada nodo físico, y otro tipo de restricciones, para decidir dónde ejecutar cada máquina virtual.


HEAT es como un cliente, como horizon, o como openstack cli... 
Realmete heat lo podemos invocar mediante el cli de openstack, o mediante el dashboard de horizon, o mediante la API REST de heat. Incluso ofrece un api compatible con cloud formation.

# Conceptos que manejamos en nova

En neutron hemos visto que manejamos muchos conceptos: red, subnet, puerto, security group, router, floating ip, etc...
En nova también manejamos muchos conceptos: instancias, flavor, keypair, etc

## Flavor

Es un perfil lógico de recursos para la creación de máquinas virtuales.
Es decir, es un perfil que define la cantidad de recursos que va a tener una máquina virtual: vCPU, RAM, disco, etc...
Cuando creo una máquina virtual, tengo que decirle qué flavor quiero usar, es decir, qué perfil de recursos quiero para esa máquina virtual.

La idea es tenerlos estandardizados, para que los usuarios no tengan que estar pensando en cuántas vCPU, cuánta RAM, etc... necesitan para cada máquina virtual.

## Keypair

Keystone gestiona autenticación a nivel del cloud. Cuando alguien quier entrar en openstack o alguno de sus servicios, tiene que autenticarse en keystone.
Cuando quiero conectarme con una máquina virtual, tengo que autenticame en la máquina virtual.
Si estoy con windows, me conecto con RDP o por terminal con un usuario y contraseña.
Si estoy con linux:
    - me conecto por terminal con un usuario y contraseña...  ESTA ESTA CONSIDERADA MAS INSEGURA
    - conectarme con clave ssh.                               ESTA ESTA CONSIDERADA MAS SEGURA

Cuando me conecto con claves, yo habré generado un par de claves: una clave pública y una clave privada.
- En el servidor está la pública: se guarda en la tura ~/.ssh/authorized_keys
- En el cliente desde el que me conecto tengo la privada: se guarda en la ruta ~/.ssh/id_rsa  (o en otro sitio y luego ssh -i /ruta/a/mi/clave_privada)

Pero esas claves se generan juntas. Hay varios algoritmos: RSA, ECDSA, ED25519, etc... y cada uno de ellos tiene su propia forma de generar el par de claves.

En Openstack (o en AWS), puedo ir guardando bajo el apartado keyPairs? la clave pública de cada par de claves que voy generando.

Para generar esas claves.. Tu mismo:
 - ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_mi_clave
 - openstack keypair create mi-clave > ~/.ssh/id_rsa_mi_clave.pem

Nova lo que guarda es solamente la clave pública, y la clave privada la guardo yo en mi máquina.

Como cortesía o funcionalidad extendida de Nova, cuando creo una máquina virtual, puedo decirle que quiero usar un "par de claves" concreto (realmente lo que le doy es solo la clave pública), y Nova se encargará de meter la clave pública en la máquina virtual que está creando, dentro de ~/.ssh/authorized_keys, para que yo pueda conectarme con la clave privada.

# Con respecto a la red

En nova lo que voy a definir es a qué red quiero conectar mi máquina virtual.... lo hago en forma de puerto... es decir, le digo a nova "quiero conectar mi máquina virtual a este puerto de neutron", y ese puerto de neutron ya estará conectado a una red concreta, y esa red concreta ya tendrá una subnet concreta, etc...

    PUERTO de neutron?
        - Agujero para que meta cable en el switch de OVS. 
        - IP fija? -> regla en el switch ... del tipo a este MAC ADDRESS le asignas esta IP
        - Mac address -> Dirección física de tarjeta de red.
          Dicho de otra forma, en el puerto no doy solo información de lo que ocurre a nivel del switch, sino que también doy información de lo que ocurre a nivel de la máquina virtual. Es decir, qué tarjeta de red monto en la MV.
        - Dijimos que a nivel de puerto, puedo configurar modo direct (en este caso, la tarjeta de red de la máquina virtual es la tarjeta física del nodo físico, virtaulizada con SR-IOV), o modo normal (en este caso, la tarjeta de red de la máquina virtual es una tarjeta virtual que se monta en el nodo físico, y esa tarjeta virtual se conecta a un puerto de OVS).

      El concepto de puerto es más bien información del ENLACE entre la MV y el switch.


        SWITCH 
        +-----+-----+-------+
        | P1  | P2  | P3    |
        |     |     |       |
        +-----+-----+-------+
         Puerto RJ45                                            -----+
            |                                                        | PUERTO DE NEUTRON
         Puerto RJ45 (de la NIC de la máquina virtual)          -----+
        +-------------------+
        | P1  |             |
        +-------------------+
        |                   |
        +-------------------+
        VM1