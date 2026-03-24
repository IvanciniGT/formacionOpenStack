# DIA 2

# Red, computo y capacidad en OpenStack

## 1. Enfoque del dia

Este bloque se centra en tres piezas que se entienden mejor juntas que por separado:

- Neutron, para conectividad y topologia
- Nova, para ciclo de vida de instancias
- Placement, para inventario y candidatos de recursos

La idea importante es esta: una instancia util no depende solo de arrancar. Depende de identidad, imagen, red, seguridad, capacidad disponible y, cuando aplica, almacenamiento persistente.

---

## 2. Neutron en profundidad

### 2.1 Por que la red en cloud no es solo "tener red"

En un entorno tradicional se suele pensar en switches, VLANs, routers e IPs. En cloud, ademas de eso, la red debe comportarse como un recurso de plataforma.

Eso implica que debe poder:

- crearse y gestionarse por proyecto
- aislar espacios de forma limpia
- automatizar aprovisionamiento
- convivir con multiples cargas y contextos
- exponer servicios de forma controlada

Por eso, en OpenStack no basta con conectar maquinas. Hace falta un modelo logico de conectividad gobernable.

### 2.2 Que es Neutron

Neutron es el servicio de red de OpenStack. Su funcion es modelar conectividad, direccionamiento y exposicion como recursos cloud gestionables.

Neutron no es un accesorio. Es una pieza estructural porque define como se conectan, se aislan y se publican las cargas.

### 2.3 Problemas que resuelve

Neutron cubre necesidades clave:

- conectividad entre instancias
- segmentacion por dominios logicos
- aislamiento entre proyectos
- construccion de topologias virtuales
- control de trafico y visibilidad externa

Sin esto, el computo existe, pero no hay servicio utilizable de extremo a extremo.

### 2.4 Conceptos nucleares

#### Red

Entidad logica de conectividad. Es un contenedor funcional, no un rango IP por si mismo.

#### Subred

Introduce direccionamiento IP dentro de una red. Aqui aparecen CIDR, gateway, DHCP y pools.

#### Puerto

Punto logico de union entre instancia y red. La conectividad real se materializa en puertos, no en una union abstracta.

#### Router

Entidad logica para interconectar redes/subredes y, segun diseno, habilitar salida externa.

#### Red externa

Espacio de salida/entrada fuera del ambito privado del proyecto. Puede ser red publica, provider o corporativa.

#### Floating IP

Mecanismo de exposicion flexible para publicar una carga privada sin cambiar su arquitectura interna.

#### Security groups

Reglas de trafico de entrada y salida. Una topologia correcta no garantiza conectividad util si las reglas no acompanan.

### 2.5 Modelo mental minimo

Una secuencia tipica de diseno:

1. Crear red
2. Definir subred
3. Asociar instancia por puerto
4. Interconectar mediante router
5. Enlazar con red externa cuando haga falta
6. Asociar floating IP si se requiere exposicion
7. Ajustar security groups

Este orden ayuda a detectar fallos de forma mas rapida.

### 2.6 Fallos de comprension frecuentes

- Confundir red con subred
- Asumir que instancia activa implica acceso valido
- Suponer que IP privada habilita acceso externo
- Suponer que floating IP resuelve todo por si sola
- Minusvalorar reglas de seguridad

### 2.7 Relacion con otros clouds

Hay paralelos utiles con AWS, Azure y GCP a nivel de conceptos. Sirven para orientarse, pero no deben forzarse equivalencias exactas 1:1.

---

## 3. Nova en profundidad

### 3.1 Que es Nova

Nova es el servicio de computo de OpenStack. Gestiona el ciclo de vida de instancias desde su creacion hasta su eliminacion.

Operaciones habituales:

- create
- start
- stop
- reboot
- suspend/pause
- resize
- delete

### 3.2 Nova no opera en aislamiento

Para producir una instancia util, Nova coopera con:

- Keystone, para identidad, ambito y permisos
- Glance, para imagen base
- Neutron, para red y conectividad
- Cinder, cuando se requiere persistencia desacoplada
- Placement, para validar capacidad y candidatos

Esta cooperacion explica por que muchos fallos aparentes de computo terminan estando en red, permisos o capacidad.

### 3.3 Que representa una instancia en OpenStack

No es solo una VM aislada. Normalmente integra:

- contexto de proyecto
- imagen o volumen de arranque
- flavor
- interfaces de red
- reglas de seguridad
- claves de acceso
- cuotas y politicas

Pensarlo asi evita diagnosticos simplistas.

### 3.4 Requisitos de nacimiento

Antes de crear una instancia conviene validar:

1. contexto de identidad valido
2. imagen disponible o boot-from-volume
3. flavor acorde al caso de uso
4. red y reglas coherentes
5. metodo de acceso operativo

Si uno de estos puntos falla, la instancia puede quedar creada pero inutilizable.

### 3.5 Flavor como abstraccion

Flavor define perfil logico de recursos: vCPU, RAM y disco segun catalogo de plataforma.

No describe hardware fisico concreto. Describe capacidad ofertada de forma estandarizada.

### 3.6 Keypairs y acceso

El keypair habilita autenticacion (tipicamente SSH en Linux), pero no garantiza acceso por si solo. Tambien deben estar correctos:

- rutas
- reglas de seguridad
- direccionamiento
- estado de servicios en la instancia

### 3.7 Ciclo de vida y estado real

Una instancia puede aparecer activa y aun asi no estar utilizable. Conviene distinguir:

- estado de provision
- estado de conectividad
- estado de seguridad
- estado de aplicacion

Esta separacion reduce mucho el tiempo de troubleshooting.

### 3.8 Errores frecuentes alrededor de Nova

- Ver el lanzamiento como operacion trivial
- Suponer que si Nova responde todo esta correcto
- Tratar flavor como sinonimo de hardware
- Dar por hecha la persistencia de datos sin revisar diseno

### 3.9 Comandos base de referencia

openstack flavor list
openstack keypair list
openstack server list
openstack server show <instancia>
openstack server create ...
openstack server stop <instancia>
openstack server start <instancia>
openstack server reboot <instancia>
openstack server resize <instancia> --flavor <nuevo_flavor>

---

## 4. Placement en profundidad

### 4.1 Para que existe Placement

Placement aporta un modelo formal para inventario, consumo y asignaciones de recursos.

Su rol no es crear instancias, sino responder preguntas como:

- que capacidad existe
- cuanto esta consumido
- que candidatos cumplen requisitos

### 4.2 Conceptos clave

#### Resource provider

Entidad que ofrece recursos (por ejemplo, nodo de computo o pool compartido).

#### Inventory

Capacidad total declarada por un provider.

#### Usage

Capacidad ya usada.

#### Allocations

Recursos comprometidos por consumidores concretos.

#### Resource classes

Tipos de recurso cuantificables, por ejemplo VCPU, MEMORY_MB y DISK_GB.

#### Traits

Atributos cualitativos no consumibles, por ejemplo SSD.

### 4.3 Relacion con Nova Scheduler

Flujo simplificado:

1. llega solicitud
2. scheduler consulta requisitos
3. Placement devuelve candidatos viables
4. scheduler filtra, pesa y decide destino

Resumen practico:

- Placement responde quien puede
- Scheduler decide quien sera

### 4.4 Casos conceptuales utiles

- carga pequena: muchos candidatos
- carga grande: candidatos mas limitados
- requisito cualitativo: traits reducen candidatos
- recursos distribuidos: computo, disco e IP pueden venir de providers distintos

### 4.5 Malentendidos habituales

- "Placement es el scheduler"
- "Placement toma siempre la decision final"
- "Placement solo cuenta CPU y RAM"

Placement es mas amplio: modela inventario, consumo, clases y cualidades.

---

## 5. Integracion de extremo a extremo

Lanzar una instancia util en OpenStack es una operacion compuesta:

- Keystone valida identidad y alcance
- Glance aporta base de sistema
- Neutron define conectividad y exposicion
- Nova gestiona ciclo de vida
- Placement valida candidatos de capacidad
- Cinder aporta persistencia cuando aplica

Cuando esta integracion es correcta, la instancia deja de ser "una VM encendida" y pasa a ser un recurso cloud utilizable en operacion real.

---

## 6. Checklist rapido de diagnostico

Si una instancia no funciona como se espera, revisar en este orden:

1. estado de instancia en Nova
2. red/subred/puerto asociados
3. rutas y router hacia red externa
4. security groups y reglas efectivas
5. floating IP y asociacion correcta
6. imagen, cloud-init y servicio interno
7. cuotas, capacidad y candidatos en Placement

Este orden evita saltos de contexto y reduce falsos diagnosticos.

---

## 7. Cierre del dia

La idea final no es memorizar listas, sino fijar un modelo mental robusto:

- OpenStack funciona por cooperacion entre servicios
- red, computo y capacidad deben leerse como un sistema
- el valor operativo aparece cuando todas las piezas encajan

Con este marco, la parte practica del siguiente bloque resulta mucho mas directa: ya existe criterio para interpretar por que algo funciona, por que falla y como corregirlo con metodo.
