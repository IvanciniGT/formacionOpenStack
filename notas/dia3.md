
Weblogic
Websphere

tomcat

Antiguamente se montaban megaaplicaciones: MONOLITO.

Arquitecturas de micrsoservicios

En lugar de una app gigante, tengo un sistema compuesto por 100 microservicios

App: Mandar emails
App: Gestionar usuarios v1 -> v2
                        99%   1% 
                        95.   5
                        50    50
                        0.   100.   

App: Gestionar expedientes
App: Gestionar facturas

Antes tenía 4 weblogics

Ahora tengo 100 tomcats x replicas variable = 400 tomcats.


Tomcat 1            ->          Tomcat2 
                    https
Clave pub/priv                  Clave pub/priv
Certificado pub                 Certificado pub

       CA

       Y renovar esto cada mes? 2 meses?
       En 400 sevricores? Y Además 400... quiero decir. Hoy a las 12:00 puede haber 400.. en 10 minutos : 800
       A los 15 minutos: 30

ISTIO / Linkerd      envoy    netfilter (Iptables)

App1 - HA - Escalabilidad

    Cluster:
        Maquina 1       Maquina 2           Maquina 3       Maquina 4
           25%

Estoy tirando a la basura 3 máquinas el 98% del tiempo

App2, App3, App4 .. multiplica máquinas sin hacer nada = LOCURA!

Con un cluster de kubernetes:
    Cluster: 200 máquinas : 10 máquinas en reserva
                                  ^^^^
                                  Estan on spare, pero compatidas entre todos los servicios que tengo en el cluster.

Docker/Podman -> Kubernetes/Openshift


---

Keystone:
    Gestión de identidades (Usuarios, roles, dominios, proyectos)
    > Catalogo de servicios del cluster.
    Cualquier componente que instalo, lo registro en el catalogo de servicios de keystone, y así los demás componentes pueden descubrirlo.

Componentes que elijo:

IaaS:

    - Almacenamiento:   Cinder, Swift, Manila
    - Red:              Neutron, Octavia, Designate
    - Computo:          Nova, Zun

PaaS:
    - Orquestación:     Heat
    - Contenedores:     Magnum
    - Funciones:        Qinling

---

El cliente de openstack lo unico que hace son peticiones HTTP REST a los servicios de openstack, y cada servicio de openstack tiene su propia API REST.

Openstack, por cierto, sigue lo que llamamos una arquitectura de microservicios, cada servicio es independiente, con su propia base de datos, y se comunican entre ellos a través de APIs REST.

Hasta ahora las 4 cositas que hemos hablado con Openstack ha sido por cli: $ openstack

Luego tenemos Horizon, que es la interfaz web de Openstack, y también hace peticiones HTTP REST a los servicios de Openstack.

Los propios programas hablan entre si de la misma forma: a través de APIs REST.

Y lo guay al final es usar todo esto desde:
- Heat: Orquestación de recursos, plantillas para desplegar infraestructuras completas.
- Terraform: Herramienta de infraestructura como código, que también puede interactuar con Openstack a través de sus APIs REST.

---
Openstack es un proyecto de código abierto, y es una plataforma de computación en la nube que nos permite crear y gestionar infraestructuras de nube pública o privada.

---

# Keystone.
    
    Grupos                      Nos permite simplificar la gestión de roles a usuarios.
    Roles                       Un role no es un conjunto de permisos emn OpenStack.. Y esto de entrada es raro...
                                Un role es solo un nombre que puedo asignar a un usuario o grupo. 
                                Además lo puedo asignar a nivel de sistema, proyecto o dominio.
                                Ese tag/etiqueta, se incluye en el token de autenticación del usuario.
                                Yo puedo crear los roles que quiera, y asignarlos a los usuarios o grupos que quiera, pero eso no me da ningún permiso en Openstack.
                                "monitoring", "operations"
                                Aquí hay otra cosa rara: Puedo con el api, y con el cli crear roles... pero inicialmente inutiles.
                                Esos roles no aparecerán en las pocilies de ningún servicio de Openstack, porque no los conoce.
                                Por tanto, no me van a dar ningún permiso, porque no los conoce ningún servicio de Openstack.
    Usuarios                    Representa a una persona o un programa que puede conectarse a Openstack para hacer cosas.
    Autenticación / Token
        SCOPE
    Dominios                    Agrupación lógica de usuarios, grupos y proyectos.
    Proyectos                   Agrupación lógica de recursos, como máquinas virtuales, redes, etc. 
                                Un proyecto es como un contenedor para los recursos que se crean en Openstack.

    La definición de permisos está totalmente descentralizada. Cada servicio de Openstack define sus propios permisos.
        Politicas: policies

        openstack <tipo_objeto> <verbo>
            openstack user list
            openstack user create
            openstack token issue
            openstack project delete

            La combinación de tipo_objeto y verbo es una acción.
            Esa acción es procesada por un servicio de Openstack.

            La operación listar usuarios es una acción procesada por keystone.
            La operación crear una máquina virtual es una acción procesada por nova.

            Keystone, Nova, y el resto de componentes definen sus propias acciones y las reglas de validación de permisos para esas acciones.
            Eso se define archivos de políticas, que son archivos de texto con formato JSON o YAML, donde se definen las reglas de acceso para cada acción.

        No es solo que el cliente de openstack use esa sintaxis: Tipo_Objeto + Verbo...
        Es que las APIs REST HTTP de cada servicio de Openstack también siguen esa lógica.

        El cliente de openstack lo único que hace es traducir los comandos que le damos a peticiones HTTP REST a las APIs de cada servicio de Openstack, y esas APIs también siguen la lógica de Tipo_Objeto + Verbo.

        Keystone, para listar los usuarios, llamamos a :
            GET      https://keystone.example.com/v3/users              <- user list
        Si quiero ver los detalles de un usuario específico:
            GET      https://keystone.example.com/v3/users/{user_id}    <- user show <user_id>

        En cualquier de esas peticiones, la política simplemente determina una cosa: 
        Si el usuario tiene permitida esta acción o no.

        Más claro: Si la llamada HTTP a esa URL devuelve un código éxito http (2XX) o si devuelve un código de error http (403 Forbidden, 401 Unauthorized, etc).

        Es decir, la política NO FILTRA! No me dice a qué tengo acceso. Me dice si puedo realizar o no una operación.


    Catalogo de servicios

---

    Role: Etiqueta que se asocia a usuario
    Token: Certificación de que el usuario es quién dice ser.
           Y en ese token se incluyen mis roles... Como información anexa... A quién le interese: Este tio tiene role: "operaciones".

    Con mi token intento hacer una operación. Y el servicio de Openstack que recibe esa operación:
     1. Mira que sea un token válido. 
        Ese token va firmado por Keystone, así que el servicio de Openstack puede verificar su validez.
     2. Habla con keystone y le pregunta: Ese token sigue siendo válido?
     3. Si cuela, mira los roles que tiene el token, y mira en su archivo de políticas si alguno de esos roles le da permiso para realizar esa operación. SI / NO
     4. Si le da permiso, ejecuta la operación... y devolverá datos.
        Qué datos.. depende de cómo esté implementado el servicio de Openstack. 

        En el caso de keystone, si la operación es listar proyectos, devolverá la lista de proyectos de todo el sistema.
        A keystone le importa mierda si el role "admin" está asignado a nivel de sistema, proyecto o dominio.

    5. Otra cosa es cómo puedo influir yo en los datos que recibo. 
       Lo primero es si puedo influir o no? No siempre puedo influir... depende de la implementación del servicio de Openstack.

       Por ejemplo, en el caso de keystone, si tengo el role "admin" a nivel de sistema:
       - Si limito mi scope a un dominio, keystone me devolverá solo los proyectos de ese dominio.
       - Si no limito mi scope, keystone me devolverá todos proyectos.

        Pero eso es lo que veo en un momento dado.
        Eso no significa que. keystone no me deje crear proyectos nuevos... incluso en otro dominio .
        Keystone ME PERMITIRA CREAR PROYECTO NUEVOS EN OTRO DOMINIO, por tener role admin.

        Quizás no es lo que quiero... y encontes me tengo que ir a otro role: "manager", que solo me da permiso para gestionar proyectos dentro de un dominio concreto.

---

Identificación      Decir quién soy
Autenticación       Verificar que eres quien dices ser (Password...)
Autorización        Sabiendo que eres quien dices ser, decir qué puedes hacer y qué no puedes hacer.


---

Dominio: dominio-alumno1-cliente
Usuario: Manager: alumno1-manager
    Role: manager en el dominio-alumno1-cliente
Con ese usuario crear un proyecto
        proyecto-alumno1-cliente

Usuario: Operador: alumno1-operador
    Role: member en el proyecto creado por el manager

Conectarnos con ese usuario operador, y listar los proyectos a los que tiene acceso.

Al acabar, borrar todo.
