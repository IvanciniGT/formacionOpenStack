# Prácticas de Neutron — Redes virtuales en OpenStack

## Objetivo

En estas prácticas vas a:

- entender el modelo de red de OpenStack (provider vs tenant)
- crear una red privada y su subred
- crear un router y conectarlo a la red exterior
- gestionar security groups y sus reglas
- crear una floating IP lista para asignar a una VM
- inspeccionar la topología de red que has creado

## ¿Qué es Neutron?

Neutron es el servicio de **red virtual** de OpenStack.
Se encarga de crear y gestionar toda la infraestructura de red: redes, subredes, routers,
puertos, security groups y floating IPs.

Sin Neutron, las VMs de Nova no tienen conectividad.

## Conceptos clave

| Concepto | Descripción |
|---|---|
| **Red provider** | Red física del datacenter, gestionada por el administrador. Los alumnos la ven pero no la modifican. |
| **Red tenant** (privada) | Red virtual aislada que crea cada proyecto. Solo existe dentro de tu proyecto. |
| **Subred** | Rango de IPs dentro de una red. Define el espacio de direccionamiento. |
| **Router** | Elemento virtual que conecta tu red privada con la red exterior (provider). |
| **Port** | Punto de conexión de una VM (o router) a una red. Tiene una IP fija. |
| **Security group** | Firewall virtual por instancia. Filtra tráfico entrante y saliente. |
| **Floating IP** | IP pública tomada de la red provider. Se asocia a un port para dar acceso externo. |

## Tu contexto en este laboratorio

Cada alumno tiene:
- acceso de lectura a la red provider llamada `external`
- permisos para crear redes privadas, routers y security groups **dentro de su proyecto**
- sin acceso a las redes ni routers de otros proyectos

---

# 1. Preparación del entorno

> **Nota importante para Windows:** en `cmd.exe` los comandos multilínea con `\` no funcionan.
> Escribe siempre los comandos en una sola línea o cópialos directamente desde aquí.

## 1.1 Activar entorno y cargar credenciales

```bat
rem Activa el entorno virtual donde instalaste python-openstackclient.
%USERPROFILE%\openstack-client\Scripts\activate

rem Configura tus credenciales. Sustituye <tu_password> por tu contraseña.
set OS_AUTH_URL=https://keystone.ivanosuna.com/v3
set OS_IDENTITY_API_VERSION=3
set OS_USERNAME=alumno1
set OS_PASSWORD=<tu_password>
set OS_PROJECT_NAME=proyecto-alumno1
set OS_USER_DOMAIN_NAME=dominio-alumno1
set OS_PROJECT_DOMAIN_NAME=dominio-alumno1

rem Verifica que tienes token válido y que estás en el proyecto correcto.
openstack token issue
```

## 1.3 Verificar que Neutron está disponible

```bat
rem Busca el servicio de red en el catálogo de servicios.
rem Debe aparecer un servicio de tipo "network".
openstack catalog show network
```

---

# 2. Explorar la red existente

Antes de crear nada, vamos a explorar lo que hay.

## 2.1 Listar todas las redes visibles

```bat
rem Lista todas las redes que puedes ver: las tuyas (si tienes alguna) y la red provider.
rem Columnas clave: Name, Status, Subnets, Router Type.
rem "External=True" indica que es la red provider hacia Internet.
openstack network list
```

## 2.2 Ver detalles de la red externa

```bat
rem Muestra los detalles de la red provider del entorno.
rem Fíjate en: provider:network_type, router:external=True, shared...
rem Esta red la gestiona el administrador — tú solo puedes usarla para floating IPs.
openstack network show external
```

## 2.3 Ver la subred de la red externa

```bat
rem Lista las subredes asociadas a la red external.
rem Te dirá el rango de IPs públicas disponibles para floating IPs.
openstack subnet list --network external
```

### Qué debes observar

- La red `external` tiene `router:external=True`
- Su subred define el rango de IPs flotantes que se pueden asignar
- Tú no eres el dueño de esa red

---

# 3. Práctica 1 — Crear la red privada

## Objetivo

Crear la red tenant privada de tu proyecto.

## 3.1 Crear la red

```bat
rem Crea una red privada llamada "red-alumno1".
rem Al crearla sin opciones extra queda como red interna (no externa, no compartida).
rem El campo "admin_state_up=True" significa que está activa de inmediato.
openstack network create red-alumno1
```

## 3.2 Comprobar que se ha creado

```bat
rem Muestra los detalles de tu nueva red.
rem Fíjate: "router:external=False" confirma que es una red privada de tenant.
rem El campo "subnets" estará vacío — todavía no tiene subred.
openstack network show red-alumno1
```

## 3.3 Ver la lista de redes ahora

```bat
rem Deberías ver ahora dos redes: "external" (del admin) y "red-alumno1" (tuya).
openstack network list
```

### Preguntas

1. ¿En qué se diferencia `red-alumno1` de `external` en el listado?
2. ¿Puedes ver redes de otros compañeros?

---

# 4. Práctica 2 — Crear la subred

## Objetivo

Definir el espacio de direccionamiento dentro de tu red privada.

## 4.1 Crear la subred

```bat
rem Crea la subred "subnet-alumno1" dentro de tu red privada.
rem --subnet-range: rango CIDR de IPs que usarán las VMs.
rem --gateway: la IP del router dentro de esa red (la primera usable del rango).
rem --dns-nameserver: servidor DNS que recibirán las VMs por DHCP.
openstack subnet create subnet-alumno1 --network red-alumno1 --subnet-range 10.0.0.0/24 --gateway 10.0.0.1 --dns-nameserver 8.8.8.8
```

## 4.2 Ver los detalles de la subred

```bat
rem Muestra los detalles de la subred recién creada.
rem Campos clave: cidr, gateway_ip, dns_nameservers, allocation_pools.
rem allocation_pools es el rango que el DHCP usará para asignar IPs a las VMs.
openstack subnet show subnet-alumno1
```

## 4.3 Ver la red ahora

```bat
rem Ahora la red debería mostrar la subred en el campo "subnets".
openstack network show red-alumno1
```

## 4.4 Listar todas las subredes de tu proyecto

```bat
rem Lista las subredes que tienes en tu proyecto.
openstack subnet list
```

### Preguntas

1. ¿Qué rango de IPs asignará el DHCP a las VMs? (mira `allocation_pools`)
2. ¿Para qué sirve especificar `--gateway`?
3. ¿Qué pasaría si dos alumnos crean ambos la subred `10.0.0.0/24`? ¿Hay conflicto?

---

# 5. Práctica 3 — Crear el router

## Objetivo

Crear un router virtual que conecte tu red privada con la red `external`.
Sin router, tus VMs estarán aisladas y no podrán salir a Internet ni recibir floating IPs.

## 5.1 Crear el router

```bat
rem Crea el router "router-alumno1".
rem Por ahora está vacío: no tiene gateway ni interfaces internas.
openstack router create router-alumno1
```

## 5.2 Conectar el router a la red externa (gateway)

```bat
rem Establece la red "external" como gateway del router.
rem Esto le da al router una IP en la red provider y acceso a Internet.
rem Es el equivalente a "enchufar el router a la fibra".
openstack router set router-alumno1 --external-gateway external
```

## 5.3 Añadir tu subred al router

```bat
rem Conecta la subred privada al router.
rem Neutron crea automáticamente un port con la IP del gateway (10.0.0.1).
rem Las VMs en esa subred podrán enrutar tráfico a través del router.
openstack router add subnet router-alumno1 subnet-alumno1
```

## 5.4 Ver los detalles del router

```bat
rem Muestra el estado del router.
rem "external_gateway_info" confirma que tiene salida a "external".
rem "interfaces_info" mostrará la interfaz interna conectada a tu subred.
openstack router show router-alumno1
```

## 5.5 Ver los ports del router

```bat
rem Lista todos los ports (interfaces) que tiene el router.
rem "--router" filtra solo los ports que pertenecen a ese router.
rem Verás un port con IP 10.0.0.1: la interfaz interna conectada a tu subred.
rem Si el router tiene HA activo, también verás ports con IPs 169.254.x.x — son internos de OpenStack.
openstack port list --router router-alumno1
```

### Preguntas

1. ¿Cuántos ports aparecen con `--router`? ¿Qué IP tiene?
2. ¿Qué pasaría si no conectas el gateway a `external`? ¿Podrían las VMs recibir floating IPs?
3. ¿El router ocupa una IP de tu subred privada? ¿Cuál?

---

# 6. Práctica 4 — Inspeccionar ports de la red

## Objetivo

Entender qué es un port y ver cómo Neutron los crea automáticamente.

## 6.1 Listar ports de tu red privada

```bat
rem Lista todos los ports que existen en tu red privada.
rem Neutron crea ports automáticamente: uno para el agente DHCP y otro para el router.
rem Cuando lances VMs, cada una tendrá también su propio port aquí.
openstack port list --network red-alumno1
```

## 6.2 Ver detalles de un port

```bat
rem Copia el ID de uno de los ports del listado anterior y sustitúyelo aquí.
rem Campos interesantes: device_owner (quién lo usa), fixed_ips (IP asignada), mac_address.
rem Valores posibles de device_owner:
rem   network:dhcp              → port del agente DHCP (asigna IPs a las VMs)
rem   network:router_interface  → port del router (la interfaz interna)
rem   compute:nova              → port de una VM (aparecerá cuando lances instancias)
openstack port show <ID-del-port>
```

### Qué debes observar

- Hay un port con `device_owner=network:dhcp` — es el agente DHCP de Neutron
- Hay un port con `device_owner=network:ha_router_replicated_interface` e IP `10.0.0.1` — es la interfaz interna del router
- Cuando lances una VM, aparecerá aquí un nuevo port con `device_owner=compute:nova`

---

# 7. Práctica 5 — Security groups

## Objetivo

Crear un security group con reglas que permitan tráfico ICMP (ping) y SSH.
Sin estas reglas, aunque una VM tenga floating IP, no podrás conectarte a ella.

> **Por defecto**, un security group en OpenStack:
> - bloquea **todo el tráfico entrante** (ingress)
> - permite **todo el tráfico saliente** (egress)

## 7.1 Ver el security group por defecto

```bat
rem Cada proyecto tiene un security group "default" creado automáticamente.
rem Las VMs se asignan a él si no especificas otro.
rem La regla de ingress del default permite todo el tráfico DESDE otras VMs del mismo sg.
openstack security group list
openstack security group show default
```

## 7.2 Crear un security group

```bat
rem Crea un security group personalizado llamado "sg-alumno1".
rem Al crearlo, hereda las reglas de egress por defecto (todo el tráfico saliente permitido).
openstack security group create sg-alumno1 --description "SSH e ICMP para el lab de Neutron"
```

## 7.3 Añadir regla para ICMP (ping)

```bat
rem Permite tráfico ICMP entrante desde cualquier origen (0.0.0.0/0).
rem Sin esta regla, el ping a la floating IP no responderá.
openstack security group rule create sg-alumno1 --protocol icmp --ingress
```

## 7.4 Añadir regla para SSH

```bat
rem Permite TCP al puerto 22 (SSH) entrante desde cualquier origen.
rem Sin esta regla, el cliente SSH se colgará intentando conectar.
openstack security group rule create sg-alumno1 --protocol tcp --dst-port 22 --ingress
```

## 7.5 Ver las reglas del security group

```bat
rem Lista las reglas del security group mostrando solo las columnas clave.
rem Sin --column la tabla es muy ancha. Con estas columnas es legible.
rem Debes ver: icmp ingress, tcp/22 ingress y las reglas egress por defecto.
openstack security group rule list sg-alumno1 --column Direction --column "IP Protocol" --column "Port Range" --column "IP Range"
```

### Preguntas

1. ¿Cuántas reglas tiene el security group por defecto? ¿Qué permiten?
2. ¿Qué dirección tiene la regla de ICMP que has creado? (`ingress` o `egress`)
3. ¿Qué pasaría si solo añades la regla de ping pero no la de SSH?

---

# 8. Práctica 6 — Crear una floating IP

## Objetivo

Reservar una IP pública del pool de `external` para poder asignarla a una VM.

> Las floating IPs se reservan en tu proyecto aunque aún no estén asignadas a ninguna VM.
> En el lab de Nova las asignarás a tus instancias.

## 8.1 Crear la floating IP

```bat
rem Reserva una IP del pool de la red "external".
rem Neutron elige automáticamente qué IP libre asignarte del rango disponible.
rem La IP queda en tu proyecto hasta que la liberes o la borres.
openstack floating ip create external
```

## 8.2 Ver tus floating IPs

```bat
rem Lista todas las floating IPs de tu proyecto.
rem "Fixed IP Address" estará vacío -- todavía no está asignada a ninguna VM.
rem "Port" también estará vacío por el mismo motivo.
openstack floating ip list
```

## 8.3 Ver detalles de la floating IP

```bat
rem Copia el ID de tu floating IP del listado anterior.
rem Campos clave: floating_ip_address (la IP pública), status, port_id (vacío aún).
openstack floating ip show <ID-de-la-floating-ip>
```

### Qué debes observar

- La floating IP tiene `status=DOWN` mientras no esté asignada a una VM
- La IP pública que te han dado forma parte del rango de `external`
- Esta IP la usarás en el lab de Nova para conectarte a tu VM por SSH

---

# 9. Resumen — Verificación de la topología

Antes de terminar, comprueba que lo has creado todo correctamente.

## 9.1 Ver el resumen de redes

```bat
rem Lista redes: debes ver "external" (del admin) y "red-alumno1" (tuya).
rem Puede aparecer también una red llamada "HA network tenant..." — es interna de OpenStack para alta disponibilidad, puedes ignorarla.
openstack network list
```

## 9.2 Ver el resumen de subredes

```bat
rem Lista subredes: debes ver "subnet-alumno1" con cidr 10.0.0.0/24.
rem Puede aparecer también una subred "HA subnet tenant..." (169.254.x.x) — es interna, ignorála.
openstack subnet list
```

## 9.3 Ver el resumen de routers

```bat
rem Lista routers: debes ver "router-alumno1".
openstack router list
```

## 9.4 Ver el security group

```bat
rem Lista security groups: debes ver "default" y "sg-alumno1".
rem Puede aparecer "default" varias veces — es un SG por proyecto visible. El tuyo es el último de la lista.
openstack security group list
```

## 9.5 Ver las floating IPs

```bat
rem Lista floating IPs: debes ver la que reservaste en la práctica anterior.
openstack floating ip list
```

### Topología resultante

```
Internet
    │
[ red external ]  (red provider — del admin)
    │
[ router-alumno1 ]  (gateway hacia external + interfaz en tu subred)
    │
[ red-alumno1 / subnet-alumno1 ]  10.0.0.0/24
    │
  (aquí irán tus VMs en el lab de Nova)
```

---

# 10. Limpieza

> Ejecuta estos comandos al finalizar el laboratorio para liberar recursos.
> **El orden importa:** hay que desconectar antes de borrar.

```bat
rem 1. Liberar la floating IP (antes de borrar el router).
rem    Sustituye <ID-floating-ip> por el id que obtienes con: openstack floating ip list
openstack floating ip delete <ID-floating-ip>

rem 2. Desconectar la subred del router.
openstack router remove subnet router-alumno1 subnet-alumno1

rem 3. Quitar el gateway externo del router.
openstack router unset --external-gateway router-alumno1

rem 4. Borrar el router (ya sin conexiones).
openstack router delete router-alumno1

rem 5. Borrar la red privada (borra también la subred automáticamente).
openstack network delete red-alumno1

rem 6. Borrar el security group.
openstack security group delete sg-alumno1
```

## Verificar que has limpiado todo

```bat
rem Estas listas deben haber vuelto a su estado inicial (solo "external" y "default").
openstack network list
openstack router list
openstack security group list
openstack floating ip list
```
