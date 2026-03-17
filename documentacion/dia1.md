# OpenStack: arquitectura, servicios, acceso y almacenamiento

## 1. Introducción

OpenStack es una plataforma open source orientada a la construcción y operación de nubes, principalmente privadas o híbridas. Su arquitectura se basa en un conjunto de servicios especializados que cooperan entre sí para ofrecer capacidades de cómputo, red, almacenamiento, identidad y automatización.

Para comprender correctamente OpenStack no basta con conocer comandos, pantallas o procedimientos operativos. Es necesario entender primero el modelo que propone, el problema que resuelve y la forma en que se relacionan sus componentes.

Desde esta perspectiva, OpenStack no debe interpretarse como una herramienta aislada ni como un único producto monolítico, sino como una **plataforma cloud modular**, compuesta por servicios con responsabilidades diferenciadas y coordinados mediante APIs.

Este bloque introduce los conceptos fundamentales necesarios para situar OpenStack dentro del contexto de la computación en la nube y para entender la función de sus principales servicios.

---

## 2. El problema que resuelve el cloud

Toda organización que ejecuta aplicaciones y datos necesita una infraestructura técnica capaz de proporcionar, como mínimo:

* capacidad de cómputo
* almacenamiento
* conectividad de red
* mecanismos de seguridad
* aislamiento entre entornos
* escalabilidad
* trazabilidad operativa
* rapidez en el aprovisionamiento

En modelos tradicionales de infraestructura, la provisión de estos recursos suele depender de procesos manuales, solicitudes entre equipos y operaciones no estandarizadas. Este enfoque puede resultar suficiente en entornos reducidos, pero genera ineficiencias significativas cuando aumenta la escala, la complejidad o la necesidad de agilidad.

El modelo cloud responde a esta limitación transformando la infraestructura en un **servicio consumible**, accesible de manera más estandarizada, automatizable y gobernada.

Desde un punto de vista conceptual, el cloud implica:

* autoservicio
* automatización
* exposición mediante APIs
* control de acceso
* organización por proyectos, cuentas o tenants
* elasticidad
* abstracción respecto a la infraestructura física subyacente

Por tanto, el cloud no debe entenderse como una marca, una ubicación o un tipo concreto de servidor. Se trata, ante todo, de un **modelo operativo y de provisión**.

Ese modelo puede materializarse en:

* nube pública
* nube privada
* nube híbrida

OpenStack se sitúa precisamente en este ámbito: proporciona una base tecnológica para construir y operar nubes privadas o híbridas con una lógica similar a la de los grandes proveedores cloud, pero bajo control de la propia organización.

---

## 3. Diferencia entre virtualización y cloud

La virtualización y el cloud no son conceptos equivalentes.

La virtualización permite abstraer el hardware físico y ejecutar múltiples máquinas virtuales sobre una misma infraestructura. Entre sus capacidades habituales se encuentran:

* consolidación de cargas
* aislamiento entre máquinas
* mejor aprovechamiento del hardware
* snapshots
* movilidad de máquinas virtuales, según plataforma
* abstracción respecto al hardware

Sin embargo, una plataforma cloud añade otras capacidades que no derivan automáticamente de la mera virtualización:

* autoservicio
* APIs de acceso
* catálogo de recursos
* identidad multi-tenant
* organización por proyectos o tenants
* automatización programática o declarativa
* consumo estandarizado
* operación orientada a servicio

En consecuencia, disponer de hipervisores o de una plataforma de virtualización no implica disponer de una plataforma cloud.

La virtualización constituye una **base técnica**.
El cloud constituye un **modelo de explotación y consumo** más amplio.

OpenStack no sustituye el concepto de virtualización. Lo que hace es construir, sobre recursos de cómputo, red y almacenamiento, una capa de **plataforma cloud** que permite consumir infraestructura como servicio.

---

## 4. Modelos de servicio: IaaS, PaaS y SaaS

### 4.1 IaaS

**Infrastructure as a Service**.

En este modelo se entregan recursos básicos de infraestructura, tales como:

* instancias o máquinas virtuales
* redes
* subredes
* routers
* direcciones IP
* volúmenes
* imágenes
* determinados servicios complementarios de red o almacenamiento

La idea central es proporcionar **recursos de infraestructura** sobre los que posteriormente se despliegan sistemas y aplicaciones.

OpenStack se sitúa principalmente en este nivel.

### 4.2 PaaS

**Platform as a Service**.

En este modelo no se ofrece únicamente infraestructura base, sino una plataforma más preparada para el despliegue y ejecución de aplicaciones, por ejemplo:

* runtimes
* servicios gestionados
* clusters gestionados
* pipelines
* plataformas de despliegue

En PaaS, el foco se desplaza desde la máquina hacia la aplicación.

### 4.3 SaaS

**Software as a Service**.

En este nivel se consume directamente la aplicación final, sin gestionar ni la infraestructura ni la plataforma subyacente.

Ejemplos habituales:

* correo corporativo gestionado
* CRM en la nube
* aplicaciones ofimáticas online
* aplicaciones empresariales listas para usar

### 4.4 Posición de OpenStack

OpenStack se considera, fundamentalmente, una plataforma **IaaS**.

Aunque el ecosistema OpenStack incluye servicios que pueden aproximarse a niveles superiores, su núcleo conceptual y operativo sigue siendo el de una plataforma de infraestructura como servicio.

---

## 5. Qué es OpenStack

OpenStack es un ecosistema de servicios open source orientado a construir y operar infraestructuras cloud.

La forma correcta de entenderlo es la siguiente:

> OpenStack es un conjunto de servicios especializados que cooperan entre sí mediante APIs para ofrecer recursos cloud.

No debe interpretarse como:

* un único programa
* una simple interfaz gráfica
* una caja cerrada
* un producto monolítico

Cada servicio asume una responsabilidad concreta. Por ejemplo:

* identidad
* catálogo de imágenes
* cómputo
* red
* almacenamiento en bloque
* almacenamiento de objetos
* orquestación
* interfaz gráfica

Esta separación de responsabilidades es uno de los rasgos fundamentales de la arquitectura de OpenStack.

---

## 6. Características arquitectónicas de OpenStack

### 6.1 Modularidad

OpenStack está compuesto por servicios independientes. No todos los despliegues incorporan exactamente los mismos módulos, y el alcance funcional puede variar según la instalación.

No obstante, el patrón general se mantiene: servicios desacoplados, responsabilidades claras y comunicación mediante APIs.

### 6.2 Naturaleza API-driven

OpenStack es una plataforma diseñada alrededor de APIs. Tanto la interfaz gráfica como la línea de comandos son mecanismos de consumo de esas APIs.

Esto implica que:

* la automatización es natural
* la integración con herramientas externas es directa
* la operación no depende de una interfaz concreta
* el contrato real de la plataforma es la API

### 6.3 Multi-tenancy

OpenStack está diseñado para operar con:

* múltiples usuarios
* múltiples proyectos
* múltiples contextos de acceso
* aislamiento funcional y organizativo
* permisos diferenciados

La identidad, por tanto, no es un aspecto secundario, sino un elemento estructural de la plataforma.

### 6.4 Separación de responsabilidades

Cada servicio resuelve un ámbito concreto. Por ello, un problema observado en una operación determinada puede estar causado por componentes distintos.

Por ejemplo, un fallo al crear o arrancar una instancia puede deberse a:

* imagen
* permisos
* red
* volumen
* cuota
* flavor
* host subyacente

Esta separación obliga a comprender OpenStack como una plataforma compuesta, no como una herramienta única.

---

## 7. Comparativa conceptual con AWS, Azure y GCP

OpenStack comparte con los grandes proveedores cloud varios principios generales:

* recursos consumibles como servicio
* APIs
* identidad
* cómputo
* red
* almacenamiento
* automatización

También es posible establecer ciertos paralelismos conceptuales:

* Nova con servicios de cómputo
* Neutron con el plano de red virtual
* Cinder con el almacenamiento en bloque
* Swift con el almacenamiento de objetos
* Glance con el catálogo de imágenes
* Keystone con el plano de identidad

No obstante, la diferencia fundamental es la siguiente:

* AWS, Azure y GCP son **proveedores cloud**
* OpenStack es una **plataforma para construir cloud**

En los hyperscalers no se gestiona la arquitectura interna del plano de control, ni el despliegue de los servicios, ni su integración subyacente. En OpenStack, esos aspectos sí forman parte del ámbito de interés operativo y arquitectónico.

Por ello, OpenStack resulta especialmente valioso para comprender cómo se construye una plataforma cloud desde dentro.

---

## 8. Comparativa conceptual con VMware

VMware, especialmente en su ecosistema clásico, ha sido históricamente una referencia en virtualización empresarial.

Su centro de gravedad tradicional se sitúa en:

* gestión de hosts
* gestión de máquinas virtuales
* alta disponibilidad
* consolidación de cargas
* operación de infraestructuras virtuales

OpenStack, en cambio, nace con una orientación más directamente alineada con:

* APIs
* multi-tenancy
* autoservicio
* consumo de recursos por proyectos
* automatización abierta

Ambos mundos pueden compartir ciertos elementos técnicos, pero no responden exactamente al mismo modelo mental.

Por ello, no resulta adecuado reducir OpenStack a la idea de “VMware open source”. Esa comparación simplifica en exceso la naturaleza de OpenStack como plataforma cloud.

---

## 9. Comparativa conceptual con entornos hiperconvergentes

Las soluciones hiperconvergentes suelen priorizar:

* integración cerrada o muy empaquetada
* simplicidad operativa
* experiencia de administración unificada
* reducción de complejidad percibida

OpenStack, por el contrario, suele aportar:

* modularidad
* flexibilidad arquitectónica
* mayor capacidad de adaptación
* mayor visibilidad sobre la construcción de la plataforma

Esa flexibilidad suele ir acompañada de mayor complejidad y de una mayor exigencia de conocimiento técnico.

En términos generales:

> La hiperconvergencia tiende a simplificar la experiencia integrada.
> OpenStack tiende a ofrecer una plataforma cloud modular y abierta.

---

# Servicios principales de OpenStack

## 10. Keystone

Keystone es el servicio de identidad de OpenStack.

Sus funciones principales incluyen:

* autenticación
* autorización
* catálogo de servicios
* descubrimiento de endpoints
* gestión del contexto de acceso

Keystone no debe entenderse únicamente como un repositorio de usuarios. Es un componente transversal que condiciona el acceso a toda la plataforma.

---

## 11. Glance

Glance es el servicio de imágenes.

Su función principal es almacenar, catalogar y exponer imágenes y metadatos que luego pueden ser consumidos por otros servicios, especialmente Nova y, en determinados casos, Cinder.

Una imagen representa un artefacto base reutilizable para el aprovisionamiento de recursos.

---

## 12. Nova

Nova es el servicio de cómputo.

Gestiona el ciclo de vida de las instancias, incluyendo operaciones como:

* creación
* arranque
* parada
* reinicio
* resize
* eliminación

Nova coordina el aprovisionamiento de instancias sobre la infraestructura de cómputo disponible.

---

## 13. Neutron

Neutron es el servicio de red.

Gestiona recursos como:

* redes
* subredes
* routers
* conectividad
* grupos de seguridad
* floating IPs

Su finalidad es proporcionar el plano de red virtual necesario para los recursos cloud gestionados por la plataforma.

---

## 14. Cinder

Cinder es el servicio de almacenamiento en bloque.

Permite crear y gestionar volúmenes persistentes que pueden adjuntarse a instancias u otros consumidores, manteniendo independencia respecto al ciclo de vida del recurso de cómputo.

---

## 15. Swift

Swift es el servicio de almacenamiento de objetos.

Responde a un modelo distinto del almacenamiento en bloque. Se orienta a cuentas, contenedores y objetos, y resulta adecuado para grandes volúmenes de datos no estructurados o de tipo blob.

---

## 16. Heat

Heat es el servicio de orquestación.

Permite describir y desplegar conjuntos de recursos de infraestructura como una unidad lógica, facilitando automatización e Infraestructura como Código.

---

## 17. Horizon

Horizon es la interfaz gráfica web de OpenStack.

Facilita la exploración y operación de la plataforma, pero no constituye el núcleo de OpenStack ni sustituye al conocimiento de sus APIs y servicios.

---

# Acceso a la plataforma: Horizon, CLI y API

## 18. Modelo general de acceso

OpenStack puede consumirse mediante tres vías principales:

* interfaz gráfica
* línea de comandos
* APIs

Estas tres vías no representan plataformas distintas. La API constituye la base real, y Horizon y la CLI son mecanismos de consumo de esa base.

---

## 19. Horizon

Horizon proporciona una vista visual de la plataforma y facilita determinadas operaciones de administración y exploración.

Sus ventajas principales son:

* facilidad de uso
* visibilidad de los recursos
* utilidad formativa
* comodidad en determinadas tareas

No obstante, Horizon no debe confundirse con OpenStack como tal. Es una interfaz sobre la plataforma, no la plataforma en sí.

---

## 20. CLI

La línea de comandos permite consumir operaciones de OpenStack de forma precisa, reproducible y automatizable.

Su uso obliga a manejar con claridad conceptos como:

* identidad
* proyecto
* servicio
* endpoint
* recurso
* operación

La CLI resulta especialmente útil para:

* automatización
* scripting
* repetición de tareas
* comprensión estructurada del modelo de la plataforma

---

## 21. API

La API constituye el contrato real de OpenStack.

Todos los servicios principales exponen APIs REST. Esto implica que:

* Horizon consume APIs
* la CLI consume APIs
* las integraciones externas consumen APIs

La naturaleza API-driven de OpenStack permite:

* automatización
* integraciones
* autoservicio
* portales propios
* IaC
* administración programática

---

# Keystone como eje transversal

## 22. Keystone y el acceso a servicios

Keystone es una pieza transversal porque toda operación relevante en la plataforma depende, directa o indirectamente, de él.

Para consumir un servicio de OpenStack es necesario, en general:

* autenticarse
* obtener o validar un token
* disponer de un contexto
* conocer el endpoint adecuado
* contar con permisos suficientes

Esto aplica a servicios como:

* Glance
* Nova
* Neutron
* Cinder
* Swift
* Heat

Por tanto, Keystone no es un módulo lateral, sino la base del control de acceso de toda la plataforma.

---

## 23. Conceptos fundamentales de identidad

### 23.1 Usuario

Identidad que se autentica frente a OpenStack.

Puede representar una persona, una cuenta técnica o una cuenta de servicio.

### 23.2 Dominio

Contenedor organizativo de alto nivel para identidades y otros elementos relacionados, según configuración.

### 23.3 Proyecto

Contexto operativo habitual en el que se consumen recursos. Constituye una frontera funcional y organizativa.

### 23.4 Rol

Conjunto de privilegios asignables en un determinado contexto.

---

## 24. Autenticación y autorización

Conviene distinguir ambos conceptos:

* **autenticación**: determina quién realiza una operación
* **autorización**: determina qué puede hacer esa identidad

Una identidad puede autenticarse correctamente y, aun así, no disponer de permisos para determinadas acciones o recursos. Esto forma parte del comportamiento normal de una plataforma gobernada.

---

## 25. Tokens, catálogo y endpoints

### 25.1 Token

Credencial temporal que representa una autenticación válida y que permite acceder a otros servicios.

### 25.2 Catálogo de servicios

Descripción de los servicios disponibles y de sus endpoints.

### 25.3 Endpoint

Punto de acceso concreto a la API de un servicio.

Estos conceptos permiten entender el acceso a OpenStack de forma estructurada, más allá del uso de una interfaz gráfica o de comandos aislados.

---

## 26. Variables de entorno en la CLI

La CLI necesita un contexto explícito. Habitualmente este contexto se define mediante variables `OS_*`, como por ejemplo:

* `OS_AUTH_URL`
* `OS_USERNAME`
* `OS_PASSWORD`
* `OS_PROJECT_NAME`
* `OS_USER_DOMAIN_NAME`
* `OS_PROJECT_DOMAIN_NAME`
* `OS_IDENTITY_API_VERSION`

La CLI no deduce automáticamente quién realiza la operación ni contra qué entorno se trabaja. Requiere parámetros de autenticación y conexión.

---

# Tipos de almacenamiento en OpenStack

## 27. Introducción

OpenStack no ofrece un único modelo de almacenamiento. Ofrece varios, cada uno orientado a un problema distinto.

En una plataforma cloud no es equivalente:

* una imagen base
* el almacenamiento ligado a una instancia
* un volumen persistente
* un sistema de almacenamiento de objetos
* un filesystem compartido

La separación entre estos modelos responde a necesidades funcionales diferentes.

---

## 28. Imágenes: Glance

Las imágenes constituyen artefactos base utilizados para aprovisionar recursos, normalmente instancias o volúmenes inicializados.

No representan almacenamiento operativo habitual, sino **plantillas reutilizables** a partir de las cuales se despliegan otros recursos.

Glance proporciona:

* almacenamiento y catálogo de imágenes
* metadatos asociados
* capacidad de descubrimiento y reutilización

---

## 29. Almacenamiento efímero de instancia

El almacenamiento efímero está ligado al ciclo de vida de la instancia.

Se utiliza típicamente para:

* sistema de archivos raíz
* ejecución del sistema
* ficheros temporales
* datos que no requieren persistencia independiente

No debe confundirse con almacenamiento persistente desacoplado.

---

## 30. Almacenamiento en bloque: Cinder

Cinder proporciona almacenamiento en bloque gestionado.

Desde el punto de vista del consumidor, este almacenamiento se comporta como:

* un volumen
* un disco
* un dispositivo adjuntable

Su característica principal es la **persistencia independiente de la instancia**.

Permite, entre otras operaciones:

* crear volúmenes
* adjuntarlos y desadjuntarlos
* borrarlos
* generar snapshots
* trabajar con distintos volume types

---

## 31. Almacenamiento de objetos: Swift

Swift proporciona almacenamiento orientado a objetos.

No responde a la lógica de disco o volumen, sino a una semántica basada en:

* cuentas
* contenedores
* objetos

Resulta adecuado para:

* grandes volúmenes de datos no estructurados
* blobs
* artefactos
* backups
* contenido orientado a objeto

---

## 32. Shared filesystem: Manila

Manila proporciona un modelo de filesystem compartido.

Su semántica es distinta tanto del block storage como del object storage. Está orientado a escenarios donde se requieren shares o sistemas de ficheros compartidos.

---

## 33. Comparación conceptual de modelos de almacenamiento

### Imagen — Glance

* plantilla base
* catálogo
* origen de despliegues
* no es almacenamiento operativo

### Efímero — asociado a la instancia

* ligado al ciclo de vida de la instancia
* útil para ejecución y datos temporales
* no garantiza persistencia independiente

### Bloque — Cinder

* volumen persistente
* adjuntable
* independiente del cómputo
* adecuado para datos operativos duraderos

### Objeto — Swift

* modelo basado en objetos
* no se monta como un disco tradicional
* adecuado para datos no estructurados

### Shared filesystem — Manila

* filesystem compartido
* semántica propia
* distinto de bloque y de objeto

---

## 34. Errores conceptuales frecuentes

Conviene evitar las siguientes simplificaciones:

* asumir que todo el almacenamiento de OpenStack es equivalente
* considerar Glance como repositorio de datos operativos
* interpretar Swift como un disco remoto
* asumir que toda instancia implica persistencia duradera
* considerar Cinder, Swift y Glance como variantes del mismo concepto

Cada uno de estos servicios responde a una necesidad distinta.

---

## 35. Comandos representativos

```bash
openstack --version
openstack token issue
openstack service list
openstack endpoint list
openstack catalog list
openstack image list
openstack volume list
openstack volume type list
openstack container list
openstack object store account show
```

---

## 36. Conclusión

OpenStack es una plataforma cloud modular, orientada principalmente a IaaS, compuesta por servicios especializados que cooperan entre sí para ofrecer recursos de infraestructura consumibles, gobernados y automatizables.

Su correcta comprensión exige manejar con claridad:

* la diferencia entre virtualización y cloud
* el posicionamiento de OpenStack dentro de IaaS
* el papel de Keystone como eje transversal
* la relación entre Horizon, CLI y API
* la existencia de distintos modelos de almacenamiento con semánticas diferentes

Esa base conceptual es imprescindible para abordar posteriormente la operación práctica de los distintos servicios de la plataforma.
