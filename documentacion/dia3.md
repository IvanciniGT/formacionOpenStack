Perfecto. Aquí tienes el **Día 2 unificado**, con estilo homogéneo, tono técnico-documental y estructura continua, listo para copiar y pegar.

---

# DÍA 2

# Red, cómputo y asignación de capacidad en OpenStack

## 1. Introducción

La segunda jornada del curso se dedica a tres piezas fundamentales de la arquitectura de OpenStack:

* **Neutron**, como servicio de red
* **Nova**, como servicio de cómputo
* **Placement**, como componente de inventario, capacidad y asignación de recursos

El orden de estos bloques responde a una lógica arquitectónica. Antes de estudiar el ciclo de vida de una instancia, conviene entender el entorno lógico en el que dicha instancia va a existir: su red, su conectividad, su visibilidad, su aislamiento y su contexto de seguridad. Del mismo modo, para comprender cómo una plataforma cloud sostiene realmente la ejecución de instancias, es necesario introducir cómo modela la capacidad disponible y cómo razona sobre los recursos que puede asignar.

Desde este enfoque, OpenStack no debe interpretarse como una colección de módulos inconexos, sino como una **plataforma compuesta**, en la que identidad, imágenes, red, cómputo, almacenamiento y capacidad cooperan para ofrecer recursos cloud utilizables.

---

## 2. Neutron: red como servicio en OpenStack

### 2.1 La red en una plataforma cloud

En entornos tradicionales, la red suele entenderse principalmente como una combinación de elementos físicos y lógicos clásicos:

* switches
* VLANs
* routers
* direccionamiento IP
* gateways
* conectividad entre sistemas

Ese enfoque sigue siendo conceptualmente útil, pero en una plataforma cloud la red adquiere una dimensión adicional: deja de ser únicamente un soporte de conectividad y pasa a formar parte del modelo de servicio.

En un entorno cloud, la red debe poder:

* consumirse como un recurso de plataforma
* definirse y gestionarse por proyectos o tenants
* automatizarse
* aislarse lógicamente
* aprovisionarse sin reconfiguración física directa
* convivir con múltiples cargas y contextos de uso

Por tanto, en cloud no basta con “tener red”; es necesario **virtualizar la conectividad y gobernarla como servicio**.

### 2.2 Qué es Neutron

Neutron es el servicio de red de OpenStack. Su función es proporcionar conectividad de red como servicio entre recursos gestionados por la plataforma y permitir la definición y gestión de topologías de red virtual.

En términos conceptuales, Neutron convierte la conectividad en un recurso cloud gestionable. No es simplemente un módulo accesorio de red, sino el componente que permite modelar y controlar aspectos como:

* redes virtuales
* subredes
* puertos
* routers
* direccionamiento
* salida hacia redes externas
* exposición controlada de recursos
* políticas de conectividad y seguridad

### 2.3 Qué problema resuelve Neutron

Una plataforma cloud que solo dispusiera de cómputo, pero careciera de un modelo de red gestionable, presentaría limitaciones críticas. Podría crear instancias, pero no ofrecer una topología útil desde el punto de vista operativo.

Neutron resuelve, entre otros, los siguientes problemas:

#### Conectividad

Permite conectar instancias a redes virtuales definidas dentro de la plataforma.

#### Segmentación

Permite separar lógicamente distintos espacios de red.

#### Aislamiento

Hace posible que distintos proyectos operen con sus propias redes sin interferencias mutuas.

#### Topología

Permite construir redes internas, subredes, routers y salidas al exterior.

#### Control

Permite definir cómo se exponen los recursos y qué tráfico puede circular.

### 2.4 Relación entre Nova y Neutron

Una formulación especialmente útil para entender la arquitectura es la siguiente:

> Nova crea la instancia.
> Neutron la hace conectable.

Esta idea evita una interpretación excesivamente centrada en Nova. Una instancia que existe, pero que no puede comunicarse adecuadamente con otras redes, servicios o consumidores, sigue siendo un recurso incompleto.

Sin conectividad adecuada, una instancia puede:

* no integrarse con otras cargas
* no resultar accesible para administración
* no ofrecer servicio hacia el exterior
* no poder participar en una topología de aplicación real

La red no es, por tanto, una característica opcional añadida después del cómputo, sino una dimensión esencial del propio recurso cloud.

### 2.5 Red cloud frente a red clásica

La experiencia previa en direccionamiento IP, subredes, routing, VLANs o switching resulta útil para abordar Neutron, pero también puede inducir a una simplificación inadecuada: asumir que OpenStack reproduce la red clásica sin cambios conceptuales relevantes.

OpenStack reutiliza conceptos clásicos de red, pero los modela como **recursos lógicos cloud**. Esto implica que la conversación deja de girar únicamente en torno a infraestructura física y pasa a centrarse en entidades consumibles desde la plataforma.

Por ejemplo:

* no se trabaja solo con switches físicos, sino con redes virtuales consumibles
* no se trabaja solo con gateways físicos, sino con routers virtuales gestionados por la plataforma
* no se trabaja solo con direcciones IP, sino con direccionamiento y exposición dentro de un contexto multi-tenant

Esto exige un cambio de mentalidad: de la red como infraestructura física o puramente técnica a la red como **modelo lógico gobernado y consumible como servicio**.

---

## 3. Conceptos fundamentales de Neutron

### 3.1 Red

Una red en OpenStack es una entidad lógica que representa un dominio de conectividad.

No debe entenderse como un simple cable virtual ni como una VLAN sin más. Se trata de un recurso cloud con ciclo de vida propio, que puede:

* crearse
* listarse
* describirse
* borrarse
* asociarse a un proyecto
* servir de punto de conexión para instancias

La red representa una estructura lógica de conectividad, pero no define por sí sola el direccionamiento IP.

### 3.2 Subred

La subred introduce el **direccionamiento IP** dentro de una red.

En OpenStack, red y subred no son equivalentes:

* la red define el dominio lógico de conectividad
* la subred define aspectos de direccionamiento como:

  * CIDR
  * gateway
  * DHCP
  * versión IP
  * pools de asignación, según configuración

Esta separación es importante porque rompe una simplificación habitual: en OpenStack, una red no equivale automáticamente a un rango IP.

### 3.3 Puerto

El puerto representa un punto lógico de conexión a una red gestionada por Neutron.

Una instancia no se conecta a la red de forma abstracta, sino a través de uno o varios puertos. Esos puertos pueden contener propiedades como:

* dirección MAC
* direcciones IP
* asociación a políticas
* relación con interfaces de instancia

El puerto es clave para entender la conectividad real de las instancias y para interpretar correctamente aspectos como floating IPs, seguridad o troubleshooting.

### 3.4 Router

Un router en OpenStack es una entidad lógica que conecta redes o subredes y que, según el diseño, puede proporcionar salida hacia una red externa.

Su función conceptual es similar a la de un router tradicional: interconectar dominios de red y canalizar tránsito. En OpenStack se presenta como una abstracción gestionada por la plataforma.

Gracias a él es posible:

* comunicar distintas redes entre sí
* establecer salida desde redes privadas
* modelar gateways lógicos
* controlar la exposición de recursos

### 3.5 Red externa

La red externa representa el espacio de conectividad mediante el cual la nube puede relacionarse con redes externas al proyecto o al dominio privado de la instancia.

No debe explicarse únicamente como “Internet”, ya que en la práctica puede corresponder a:

* una red pública
* una red perimetral
* una red provider
* una red corporativa externa al tenant

Su función es servir como punto de enlace hacia fuera del espacio privado del proyecto.

### 3.6 Floating IP

La floating IP permite exponer de forma flexible una instancia que reside en una red privada interna.

Conceptualmente, una floating IP es una dirección expuesta o pública asignable dinámicamente, que permite desacoplar la red interna del mecanismo de visibilidad externa.

Esto aporta varias ventajas:

* no obliga a que la instancia nazca directamente expuesta
* permite mantener redes privadas internas
* facilita una exposición más flexible y controlada
* desacopla topología interna y acceso externo

No debe interpretarse simplemente como “otra IP”, sino como parte del modelo de **exposición controlada de recursos** dentro de la nube.

### 3.7 Security groups

Los security groups representan conjuntos de reglas que controlan el tráfico permitido, normalmente de entrada y salida, asociado a instancias o puertos.

Este punto es fundamental porque la existencia de topología de red no garantiza por sí sola conectividad útil. Puede existir:

* red
* subred
* router
* floating IP

y, aun así, no ser posible acceder a la instancia.

Los security groups introducen una capa de control basada en:

* reglas de ingress
* reglas de egress
* protocolos
* puertos
* orígenes o destinos autorizados

Por tanto:

> Una topología bien construida no garantiza por sí sola conectividad útil si las reglas de seguridad no la acompañan.

---

## 4. Esquema mental mínimo de Neutron

Una forma útil de sintetizar el funcionamiento conceptual de Neutron es la siguiente:

* se crea una **red**
* dentro de ella se crea una **subred**
* una instancia se conecta mediante un **puerto**
* varias redes pueden interconectarse mediante un **router**
* el router puede enlazar con una **red externa**
* las instancias pueden exponerse mediante **floating IPs**
* el tráfico queda condicionado además por **security groups**

Este esquema constituye la base mínima necesaria para interpretar correctamente el diseño de topologías de red en OpenStack.

---

## 5. Errores conceptuales frecuentes en Neutron

### Error 1

Pensar que red y subred son lo mismo.

No lo son. La red define conectividad lógica; la subred define direccionamiento.

### Error 2

Pensar que si la instancia arranca, la red ya está correctamente resuelta.

No. Una instancia puede existir sin estar integrada adecuadamente en una topología útil.

### Error 3

Pensar que una IP privada permite acceso directo desde fuera.

No. Para ello pueden ser necesarios router, red externa, floating IP y reglas adecuadas.

### Error 4

Pensar que asignar una floating IP garantiza automáticamente funcionamiento.

No necesariamente. También deben ser correctas la topología, la asociación, la ruta y las reglas de seguridad.

### Error 5

Pensar que los security groups son un detalle secundario.

No. Con frecuencia son la causa de que una conectividad aparentemente correcta no funcione.

---

## 6. Comparación conceptual de Neutron con otros entornos

Muchos conceptos de Neutron resultan familiares a quienes hayan trabajado con redes cloud en otros entornos.

### AWS

* VPC
* subnets
* route tables
* internet gateway
* security groups
* elastic IPs

### Azure

* virtual networks
* subnets
* NSGs
* public IPs
* routing

### GCP

* VPC
* subnets
* firewall rules
* external IPs
* routes

Estas comparaciones son útiles para orientarse, pero no deben forzarse como equivalencias exactas. Son **conceptos comparables**, no correspondencias estrictamente idénticas.

---

## 7. Nova: cómputo, instancias y ciclo de vida

### 7.1 Qué es Nova

Nova es el servicio de cómputo de OpenStack. Su responsabilidad principal es gestionar el **ciclo de vida de las instancias**.

Esto incluye operaciones como:

* creación
* arranque
* parada
* reinicio
* suspensión o pausa, según entorno
* resize
* eliminación
* ubicación sobre recursos de cómputo disponibles

Nova no debe reducirse a la idea de “módulo que crea VMs”. Es el componente que transforma la capacidad de cómputo de la plataforma en **instancias cloud utilizables**.

Además, Nova no actúa de forma aislada. Su funcionamiento depende de la cooperación con otros servicios, entre ellos:

* **Keystone**, para identidad, permisos y contexto
* **Glance**, para imágenes
* **Neutron**, para red y conectividad
* **Cinder**, para almacenamiento persistente cuando aplica
* **Placement**, para modelado y consulta de capacidad

### 7.2 Qué es una instancia

Una instancia en OpenStack no debe interpretarse únicamente como una máquina virtual aislada. Se trata de un recurso cloud que normalmente está asociado a:

* un proyecto
* una identidad y permisos
* una imagen o un volumen de arranque
* una o varias redes
* una o varias interfaces
* grupos de seguridad
* un flavor
* volúmenes adicionales, cuando procede
* claves de acceso
* cuotas y políticas

Esto muestra que una instancia no es solo un guest ejecutándose sobre un hipervisor. Es una entidad de plataforma que resulta de la cooperación entre distintos servicios.

### 7.3 Qué necesita una instancia para existir

#### Identidad y contexto

Antes de aprovisionar una instancia es necesario conocer:

* quién realiza la operación
* sobre qué proyecto actúa
* con qué permisos
* con qué cuota disponible

#### Imagen o volumen de arranque

Normalmente, una instancia necesita una base de arranque, que puede ser:

* una imagen gestionada por **Glance**
* un volumen inicializado, en escenarios de **boot-from-volume**

#### Flavor

La plataforma necesita un perfil lógico de capacidad para la instancia. Ese papel lo desempeña el **flavor**.

#### Red

La instancia debe integrarse en una topología concreta, lo que implica:

* red
* subred
* puerto
* posible router
* posible floating IP
* security groups

#### Acceso

Para utilizar y administrar la instancia suelen intervenir elementos como:

* keypairs
* reglas de seguridad
* direccionamiento y visibilidad de red

---

## 8. Flavor, keypairs y seguridad

### 8.1 Flavor

El flavor define el tamaño lógico de una instancia.

Suele incluir, entre otros aspectos:

* vCPU
* RAM
* disco raíz o efímero, según diseño
* propiedades adicionales, según entorno

El flavor expresa una idea central del cloud:

> No se consume un fragmento físico concreto de host, sino un perfil abstracto de capacidad ofrecido por la plataforma.

Por ello, el flavor no debe describirse como “el hardware de la máquina virtual”, sino como una **abstracción de capacidad** que permite:

* estandarizar despliegues
* simplificar el consumo
* gobernar tamaños
* ordenar el uso de recursos

### 8.2 Keypairs

En muchos escenarios, especialmente en sistemas Linux, el acceso administrativo inicial a la instancia se realiza mediante **SSH**, lo que introduce el concepto de **keypair**.

Un keypair es un par de claves que permite asociar una clave pública al arranque de la instancia para facilitar posteriormente la autenticación.

Conviene recordar que:

* la clave pública se inyecta o se utiliza para permitir acceso
* la clave privada debe protegerse adecuadamente

El keypair no garantiza por sí solo acceso efectivo. Para que la instancia sea administrable también deben cumplirse otras condiciones:

* conectividad de red válida
* reglas de seguridad adecuadas
* dirección alcanzable
* sistema invitado preparado para aceptar ese método de autenticación

### 8.3 Security groups desde el punto de vista de la instancia

Desde el punto de vista operativo, los security groups representan la diferencia entre:

* una instancia que simplemente existe
* una instancia accesible y realmente utilizable

Uno de los patrones más frecuentes consiste en:

* lanzar una instancia
* asignarle una floating IP
* intentar acceder
* no conseguir conectividad
* atribuir erróneamente el problema a Nova

En muchos casos, el fallo real está en:

* la topología de red
* la asociación de la floating IP
* el router
* el security group

Esto refuerza una idea importante:

> El cómputo no basta por sí solo. La utilidad real de una instancia depende de su integración con red y seguridad.

---

## 9. Ciclo de vida de una instancia

Una instancia no debe entenderse como un objeto estático. Tiene un ciclo de vida.

### 9.1 Creación

Se aprovisiona a partir de:

* identidad válida
* imagen o volumen de arranque
* flavor
* red
* seguridad
* contexto de proyecto

### 9.2 Arranque

La instancia pasa a estado operativo, lo que implica:

* proceso de boot
* inicialización
* disponibilidad lógica
* potencial acceso posterior

### 9.3 Parada

La instancia puede detenerse sin necesidad de ser destruida.

### 9.4 Reinicio

Puede reiniciarse manteniendo su identidad lógica dentro de la plataforma.

### 9.5 Suspensión o pausa

Según entorno y capacidades del despliegue, puede haber estados intermedios de ejecución.

### 9.6 Resize

La plataforma puede cambiar el perfil lógico de capacidad de la instancia.

Este punto ilustra un valor típico del cloud:

> La capacidad no tiene por qué ser estática.

### 9.7 Eliminación

La instancia puede ser destruida. En ese momento resulta especialmente importante distinguir entre:

* recursos efímeros ligados a su ciclo de vida
* recursos persistentes desacoplados, como volúmenes de Cinder

---

## 10. Estado operativo de una instancia

Desde el punto de vista de la plataforma, una instancia no debe evaluarse únicamente en términos binarios de “funciona” o “no funciona”.

Puede encontrarse, por ejemplo, en estados como:

* construyéndose
* arrancada
* parada
* en error
* redimensionándose
* existente pero no accesible

Esto obliga a pensar con mayor precisión y a evitar la identificación simplista entre “aparece en una pantalla” y “está operativamente disponible”.

---

## 11. Relación de Nova con el resto de servicios

### 11.1 Nova y la infraestructura física

Nova no crea capacidad de la nada. Opera sobre recursos físicos y virtuales reales, como:

* hosts
* hipervisores
* CPU
* memoria
* almacenamiento
* conectividad

Lo que presenta al usuario no es el detalle del sustrato físico, sino una abstracción cloud basada en:

* instancias
* flavors
* recursos disponibles
* asignación de capacidad

### 11.2 Nova y Neutron

Nova necesita de Neutron para que las instancias sean utilizables dentro de una topología cloud.

Cuando se lanza una instancia útil, normalmente necesita:

* conectarse a una red
* obtener dirección IP
* asociarse a un puerto
* quedar sujeta a reglas de seguridad
* eventualmente salir mediante un router
* potencialmente exponerse mediante floating IP

### 11.3 Nova y Glance

Muchas instancias nacen a partir de una imagen.

Esto muestra que Nova no define por sí solo el sistema operativo ni el estado inicial del recurso. Ese punto de partida proviene de:

* Glance
* o de un volumen preparado para arranque

Por ello:

> Nova no instala sistemas operativos; aprovisiona instancias a partir de artefactos base gestionados por la plataforma.

### 11.4 Nova y Cinder

Nova aporta cómputo, pero no agota por sí mismo el problema de la persistencia.

Cuando se requiere:

* persistencia independiente
* discos de datos
* boot-from-volume
* snapshots de volúmenes

entra en juego **Cinder**.

Esto refuerza una idea central de OpenStack:

> Cada servicio resuelve un problema distinto y coopera con los demás.

---

## 12. Errores conceptuales frecuentes en Nova

### Error 1

Pensar que lanzar una instancia es una operación conceptualmente simple.

No lo es. Aunque pueda parecerlo en una interfaz gráfica, implica varios servicios y decisiones.

### Error 2

Pensar que si Nova funciona, todo lo demás funcionará automáticamente.

No. Pueden fallar imagen, red, acceso, almacenamiento o permisos.

### Error 3

Pensar que el flavor equivale a la máquina física.

No. Es una abstracción de capacidad.

### Error 4

Pensar que toda instancia es persistente por definición.

No necesariamente. Depende del modelo de almacenamiento utilizado.

### Error 5

Pensar que una floating IP garantiza acceso efectivo.

No necesariamente. También importan topología, reglas de seguridad y estado real de la instancia.

---

## 13. Comandos representativos de Nova

```bash
openstack flavor list
openstack keypair list
openstack server list
openstack server show <instancia>
openstack server create ...
openstack server stop <instancia>
openstack server start <instancia>
openstack server reboot <instancia>
openstack server resize <instancia> --flavor <nuevo_flavor>
```

---

## 14. Placement: inventario, capacidad y asignación de recursos

### 14.1 Qué problema introduce Placement

Tras analizar red y cómputo, aparece una cuestión arquitectónica natural: cómo sabe la plataforma si realmente dispone de capacidad para alojar una nueva instancia y qué candidatos podrían satisfacer una petición determinada.

En una plataforma cloud madura no basta con “tener nodos” o con asumir que algún host será capaz de sostener la carga. Es necesario disponer de un modelo explícito que represente:

* qué capacidad existe
* quién la ofrece
* cuánto está disponible
* cuánto está consumido
* qué recursos se han asignado
* qué propiedades cualitativas tiene cada proveedor

Ese es el papel de **Placement**.

### 14.2 Qué es Placement

Placement es el componente de OpenStack centrado en modelar y exponer información sobre inventario, consumo, asignación y capacidad disponible de recursos.

No es Nova y no gestiona directamente el ciclo de vida de las instancias. Tampoco debe interpretarse como una simple pantalla de capacidad.

Su función es proporcionar un modelo formal de:

* **resource providers**
* inventario
* uso
* asignaciones
* clases de recurso
* traits

Esto permite razonar sobre la capacidad disponible con mayor precisión.

### 14.3 Por qué existe Placement

#### La capacidad no es infinita

Una plataforma cloud opera sobre recursos limitados:

* CPU
* memoria
* disco
* pools de almacenamiento
* otros proveedores de capacidad

Además, no todos los nodos o proveedores ofrecen lo mismo.

#### Las peticiones no son abstractas

Cuando se solicita una instancia, en realidad se está pidiendo una combinación concreta de recursos, por ejemplo:

* un número determinado de vCPU
* una cantidad determinada de memoria
* cierto perfil de capacidad
* determinadas propiedades adicionales, en algunos casos

#### El scheduler necesita información fiable

Si el sistema de scheduling operara sin un modelo serio de inventario, las decisiones serían más imprecisas. Placement permite determinar qué **providers** podrían satisfacer una petición concreta.

#### Separación de responsabilidades

Placement evita concentrar en Nova toda la semántica de inventario, asignaciones y cualidades de capacidad.

En términos arquitectónicos:

* Nova gestiona instancias y ciclo de vida
* Placement modela capacidad, inventario y consumo

---

## 15. Comparación pedagógica de Placement con Kubernetes

Una comparación útil consiste en observar el paralelismo conceptual con Kubernetes.

Placement se parece a la parte del ecosistema que mantiene el inventario de capacidad y ayuda a determinar qué nodos podrían satisfacer una carga. Sin embargo, no equivale por sí solo al scheduler.

Una formulación útil es la siguiente:

> Placement sabe qué proveedores pueden satisfacer una petición.
> Nova scheduler decide finalmente cuál será el candidato elegido.

Así, el equivalente conceptual más próximo al scheduling de Kubernetes no es Placement aislado, sino la combinación de:

* **Placement**
* **Nova scheduler**

---

## 16. Conceptos fundamentales de Placement

### 16.1 Resource Provider

Un **resource provider** es una entidad que ofrece capacidad utilizable por consumidores.

Puede corresponder, por ejemplo, a:

* un nodo de cómputo
* un pool de almacenamiento compartido
* otro proveedor lógico de recursos

Placement no modela únicamente hosts de cómputo, sino proveedores de capacidad en sentido amplio.

### 16.2 Inventory

El inventario describe qué capacidad ofrece un provider.

Por ejemplo:

* CPU
* memoria
* disco
* clases de recursos disponibles

Responde a la pregunta:

> ¿Qué puede ofrecer este proveedor?

### 16.3 Usage

El uso representa la parte de esa capacidad que ya está consumida.

Responde a la pregunta:

> ¿Qué parte de la capacidad de este proveedor ya se está utilizando?

### 16.4 Allocations

Las allocations representan asignaciones efectivas de recursos a consumidores concretos.

Placement no solo sabe qué recursos existen y qué capacidad ofrecen, sino también qué parte de ellos ya ha sido formalmente reclamada.

### 16.5 Resource Classes

Las resource classes permiten modelar tipos de recursos de forma explícita, por ejemplo:

* CPU virtual
* memoria
* disco

Esto evita una visión centrada únicamente en hosts y permite tratar los recursos como clases consumibles y comparables.

### 16.6 Traits

Los traits describen cualidades del resource provider que no se consumen como cantidad, pero que pueden resultar relevantes para decidir si una carga es compatible con él.

En términos simples:

* las **resource classes** indican qué tipo de recurso existe
* los **traits** indican qué cualidades especiales tiene el proveedor

---

## 17. Ejemplos conceptuales de Placement

### Ejemplo 1: instancia pequeña

Se solicita una instancia que requiere:

* 2 vCPU
* 4 GB de RAM

Placement permite determinar qué providers disponen realmente de esa capacidad.

### Ejemplo 2: instancia de mayor tamaño

Se solicita una instancia con:

* 8 vCPU
* 16 GB de RAM

Ya no todos los providers serán válidos. Placement evita decisiones vagas del tipo “algún host debería poder sostenerla”.

### Ejemplo 3: capacidad con rasgo especial

Dos providers pueden tener recursos cuantitativos semejantes, pero solo uno puede disponer de una cualidad determinada expresada mediante un trait.

Esto muestra que la colocación no depende solo de cantidades, sino también de propiedades cualitativas.

### Ejemplo 4: consumo distribuido

Una carga puede consumir distintos recursos desde diferentes providers. Esto eleva el modelo desde una visión simplista basada en “todo vive en un solo host” hacia una arquitectura más rica y formalizada.

---

## 18. Qué problemas evita Placement

Placement contribuye a evitar varios problemas importantes:

### 18.1 Lanzamientos imposibles

Evita intentar colocar cargas en providers que no pueden satisfacerlas.

### 18.2 Decisiones a ciegas

Evita que el scheduler opere con una visión pobre o informal de la capacidad disponible.

### 18.3 Sobrecarga conceptual en Nova

Permite separar inventario, asignaciones y cualidades de capacidad del ciclo de vida de las instancias.

### 18.4 Dificultad para expresar diferencias cualitativas

Traits y resource classes permiten representar mejor diferencias entre proveedores.

### 18.5 Falta de trazabilidad

Aporta una representación más precisa de qué recursos están asignados y a qué consumidores.

---

## 19. Relación entre Placement y Nova scheduler

Placement y Nova scheduler no son lo mismo, pero están profundamente relacionados.

Un flujo simplificado puede expresarse así:

1. llega una petición de instancia
2. Nova scheduler recibe los requisitos
3. Nova scheduler consulta a Placement
4. Placement devuelve candidatos posibles
5. Nova scheduler filtra, pondera y decide

La idea clave es la siguiente:

> Placement no reemplaza al scheduler.
> Placement alimenta al scheduler con un modelo formal de capacidad y candidatos viables.

---

## 20. Errores conceptuales frecuentes en Placement

### Error 1

Pensar que Placement es el scheduler.

No exactamente. Placement aporta candidatos e inventario; el scheduler decide.

### Error 2

Pensar que Placement decide por sí solo el host final.

No. Su papel es previo y complementario.

### Error 3

Pensar que Placement solo cuenta CPU y memoria.

No. También modela inventario, uso, asignaciones, clases de recurso y traits.

### Error 4

Pensar que se trata de un detalle interno sin relevancia.

No. Entender Placement ayuda a comprender cómo la plataforma razona sobre capacidad real.

---

## 21. Conclusión del Día 2

A lo largo de esta jornada se ha profundizado en tres componentes clave de la arquitectura de OpenStack:

* **Neutron**, para comprender la red como servicio
* **Nova**, para comprender el cómputo y el ciclo de vida de las instancias
* **Placement**, para comprender cómo la plataforma modela y razona sobre su capacidad disponible

Con ello, la creación de una instancia deja de entenderse como la simple generación de una máquina virtual y pasa a interpretarse como una operación compuesta en la que intervienen varias piezas coordinadas:

* **Keystone** aporta identidad, contexto y permisos
* **Glance** proporciona la imagen base
* **Neutron** ofrece red, conectividad, direccionamiento y exposición
* **Nova** gestiona la instancia y su ciclo de vida
* **Placement** modela capacidad disponible y candidatos viables
* **Cinder**, cuando interviene, proporciona persistencia desacoplada

La idea de cierre puede expresarse así:

> Una instancia útil en OpenStack no nace exclusivamente de Nova, sino de la colaboración entre identidad, imagen, red, cómputo, capacidad y, en muchos casos, almacenamiento.

Si quieres, ahora te dejo el **Día 3 con el mismo estilo exacto**, para que todo el manual quede uniforme.


---

Tenemos varios Scopes en Opensstack:
  Global/Sistema
  Dominio
  Proyecto
Las variables de entorno con las que configuro el contexto son:
 - Global
        OS_SYSTEM_SCOPE=all
 - Dominio
        OS_DOMAIN_NAME=<MI-DOMINIO>
 - Proyecto
        OS_PROJECT_NAME=<MI-PROYECTO>
        OS_PROJECT_DOMAIN_NAME=<MI-DOMINIO>
Importante que cuando elijo un contexto, el resto de variables estén NO ASIGNADAS.

Cuando nos conectamos, mi usuario puede tener distintos roles en base al contexto:

  - Role: Admin       Contexto: Dominio
  - Role: Admin       Contexto: Proyecto

  Esto justo es un sinsentido. El role admin SOLO TIENE SENTIDO tenerlo asignado a nivel de SISTEMA.
  Porque realmente Keystone no verifica el contexto a la hora de aplicar el ROLE.

  Llevaroslo a un caso con más sentido:
  - Soy Menchu... y me ponen como "member" en el proyecto A
                    me ponen como "reader" en el proyecto B


  Cuando entro, que role tengo? En el token irá una lista de roles... condicionada al conexto con el me conecte:
    - Si me conecto con el contexto de proyecto A, en el token aparecerá el role "member" y no aparecerá el role "reader"
    - Si me conecto con el contexto de proyecto B, en el token aparecerá el role "reader" y no aparecerá el role "member"

  Eso determina lo que podrá hacer, en base a los permisos (politicas)

Luego a este se suma otra cosa... Más espinosa...
Soy otra vez el usuario "profesor" 
  - me asignan el role "admin" a nivel de proyecto... 
  - el role "admin" a nivel de dominio... 

  Puedo crear un dominio?
  - En contexto dominio tengo role Admin, con lo que podría hacerlo (a priori)
      Pero al limitar el contexto a un dominio, algunas operaciones Keystone solo me las deja hacer a nivel de ese dominio. 
  - En contexto proyecto tengo role Admin, con lo que también podría hacerlo (a priori)
      Al conectarme a nivel de proyecto, no tengo establecido un dominio... aunque el proyecto pertenece a un dominio. Y Aqui si me deja hacer operaciones a nivel los dominios que quiera... porque no hay reglas que o impidan.
  - En contexto sistema no tengo role admin y no me dejará

Lo normal es que el usuario admin solo tenga el role admin a nivel de sistema.
Y me conecto con contexto de sistema.
Gestiono los dominios que quiero. YYa que no tengo un contexto a nivel de dominio.

