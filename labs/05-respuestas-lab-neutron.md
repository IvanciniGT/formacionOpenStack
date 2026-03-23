# Respuestas del lab — Prácticas de Neutron

> Ejecutado con el usuario **alumno1** contra `https://neutron.ivanosuna.com`
> Fecha: 23 de marzo de 2026 — Cliente: openstack 9.0.0

---

## 1. Preparación del entorno

### Cargar credenciales y verificar token

```bat
set OS_AUTH_URL=https://keystone.ivanosuna.com/v3
set OS_IDENTITY_API_VERSION=3
set OS_USERNAME=alumno1
set OS_PASSWORD=<tu_password>
set OS_PROJECT_NAME=proyecto-alumno1
set OS_USER_DOMAIN_NAME=dominio-alumno1
set OS_PROJECT_DOMAIN_NAME=dominio-alumno1

openstack token issue
```

**Salida:**
```
+------------+------------------------------------------+
| Field      | Value                                    |
+------------+------------------------------------------+
| expires    | 2026-03-23T14:08:56+0000                 |
| id         | gAAAAAB...                               |
| project_id | 1784f6fb9e1b4b02853f9ef416d4fd40         |
| user_id    | acc4deedc4134fa29f866845f7fa3030         |
+------------+------------------------------------------+
```

> El token confirma que estás autenticado como `alumno1` en `proyecto-alumno1`.
> El `project_id` es importante: lo verás aparecer en todos los recursos que crees.

### Verificar que Neutron está disponible

```bat
openstack catalog show network
```

**Salida:**
```
+-----------+----------------------------------------------------------+
| Field     | Value                                                    |
+-----------+----------------------------------------------------------+
| endpoints | public: https://neutron.ivanosuna.com                    |
|           | admin: https://neutron.ivanosuna.com                     |
|           | internal: http://neutron-server.openstack.svc.cluster.   |
|           | local:9696                                               |
| name      | neutron                                                  |
| type      | network                                                  |
+-----------+----------------------------------------------------------+
```

> El catálogo confirma que el servicio de red `neutron` está disponible.
> El endpoint público usa HTTPS. El interno usa HTTP directamente al pod de Kubernetes.

---

## 2. Explorar la red existente

### 2.1 Listar todas las redes visibles

```bat
openstack network list
```

**Salida (estado inicial, antes de crear recursos):**
```
+--------------------------------------+----------+--------------------------------------+
| ID                                   | Name     | Subnets                              |
+--------------------------------------+----------+--------------------------------------+
| 4272e0a7-3f52-4ce5-8fab-00e69507c69b | external | a700b0dc-8f26-4bf7-b73e-2e2a0f638b39 |
+--------------------------------------+----------+--------------------------------------+
```

> Al principio solo hay una red: la red `external` que gestiona el administrador.
> Los alumnos la ven porque está marcada como `shared=True`.
> No ves redes de otros alumnos porque cada uno trabaja en su propio proyecto.

### 2.2 Ver detalles de la red externa

```bat
openstack network show external
```

**Salida (campos clave):**
```
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| id                        | 4272e0a7-3f52-4ce5-8fab-00e69507c69b |
| name                      | external                             |
| provider:network_type     | flat                                 |
| provider:physical_network | external                             |
| router:external           | External                             |
| shared                    | True                                 |
| project_id                | 6e1deb9087e547369227c551b3a0e814     |
| status                    | ACTIVE                               |
+---------------------------+--------------------------------------+
```

> `provider:network_type=flat` significa que esta red es un mapeado directo a una interfaz física
> del hipervisor — no usa encapsulación como VLANs o VXLAN.
>
> `router:external=External` confirma que es la red "hacia Internet" — solo el administrador puede
> crear redes con este flag. Tú solo puedes usarla para crear floating IPs y asignarlas a routers.
>
> `shared=True` explica por qué todos los alumnos pueden verla.
>
> Fíjate en `project_id`: es el proyecto `admin`, distinto al tuyo. Eso confirma que no eres
> el propietario de esta red.

### 2.3 Ver la subred de la red externa

```bat
openstack subnet list --network external
```

**Salida:**
```
+--------------------------------------+-----------------+--------------------------------------+----------------+
| ID                                   | Name            | Network                              | Subnet         |
+--------------------------------------+-----------------+--------------------------------------+----------------+
| a700b0dc-8f26-4bf7-b73e-2e2a0f638b39 | external-subnet | 4272e0a7-3f52-4ce5-8fab-00e69507c69b | 192.168.2.0/24 |
+--------------------------------------+-----------------+--------------------------------------+----------------+
```

> La red `external` usa el rango `192.168.2.0/24`. Las floating IPs que reserves saldrán
> de este rango. En nuestro caso obtuvimos la `192.168.2.200`.

---

## 3. Práctica 1 — Crear la red privada

### 3.1 Crear la red

```bat
openstack network create red-alumno1
```

**Salida:**
```
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| id                        | 0fc4ee07-d00c-4845-8f11-a37e9a0cb090 |
| name                      | red-alumno1                          |
| router:external           | Internal                             |
| shared                    | False                                |
| provider:network_type     | vxlan                                |
| provider:segmentation_id  | 591                                  |
| status                    | ACTIVE                               |
| subnets                   |                                      |
+---------------------------+--------------------------------------+
```

> A diferencia de `external`, esta red es `Internal` (`router:external=Internal`) y no es `shared`.
> Solo tú (tu proyecto) puedes verla.
>
> Neutron le asigna automáticamente `provider:network_type=vxlan` con un ID de segmentación
> único (591). VXLAN encapsula el tráfico y permite aislar redes de distintos proyectos aunque
> compartan la misma infraestructura física — por eso dos alumnos pueden tener `10.0.0.0/24`
> sin conflicto.
>
> El campo `subnets` está vacío: la red existe pero aún no tiene rango de IPs asignado.

### 3.2 Comprobar que se ha creado

```bat
openstack network show red-alumno1
```

**Salida:**
```
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| id                        | 0fc4ee07-d00c-4845-8f11-a37e9a0cb090 |
| name                      | red-alumno1                          |
| router:external           | Internal                             |
| shared                    | False                                |
| provider:network_type     | vxlan                                |
| provider:segmentation_id  | 591                                  |
| status                    | ACTIVE                               |
| subnets                   |                                      |
+---------------------------+--------------------------------------+
```

> Confirma que la red `red-alumno1` existe, está activa y es de tipo VXLAN.
> Todavía sin subred — se crea en la siguiente práctica.

### 3.3 Ver la lista de redes ahora

```bat
openstack network list
```

**Salida:**
```
+--------------------------------------+-------------+--------------------------------------+
| ID                                   | Name        | Subnets                              |
+--------------------------------------+-------------+--------------------------------------+
| 0fc4ee07-d00c-4845-8f11-a37e9a0cb090 | red-alumno1 |                                      |
| 4272e0a7-3f52-4ce5-8fab-00e69507c69b | external    | a700b0dc-8f26-4bf7-b73e-2e2a0f638b39 |
+--------------------------------------+-------------+--------------------------------------+
```

> Ahora aparecen tres redes: `red-alumno1` (tuya, sin subred aún) y `external` (del admin).
> No ves redes de otros alumnos: cada proyecto está aislado.

---

## 4. Práctica 2 — Crear la subred

### 4.1 Crear la subred

```bat
openstack subnet create subnet-alumno1 --network red-alumno1 --subnet-range 10.0.0.0/24 --gateway 10.0.0.1 --dns-nameserver 8.8.8.8
```

**Salida:**
```
+-------------------+--------------------------------------+
| Field             | Value                                |
+-------------------+--------------------------------------+
| id                | d385bd0f-5963-4d69-9ca8-0a82fa2909b7 |
| name              | subnet-alumno1                       |
| cidr              | 10.0.0.0/24                          |
| gateway_ip        | 10.0.0.1                             |
| dns_nameservers   | 8.8.8.8                              |
| allocation_pools  | 10.0.0.2 - 10.0.0.254                |
| network_id        | 0fc4ee07-d00c-4845-8f11-a37e9a0cb090 |
+-------------------+--------------------------------------+
```

> `allocation_pools: 10.0.0.2 - 10.0.0.254` — Neutron reserva el `.1` para el gateway y
> el resto lo usa para asignar a VMs por DHCP.
>
> `dns_nameservers: 8.8.8.8` — las VMs que arranquen en esta subred recibirán el DNS de Google
> automáticamente en su configuración de red.
>
> No hay conflicto con otros alumnos aunque definan el mismo rango `10.0.0.0/24`: cada red
> VXLAN está aislada por el `provider:segmentation_id`. Son redes privadas distintas aunque
> usen los mismos rangos de IPs.

### 4.2 Ver los detalles de la subred

```bat
openstack subnet show subnet-alumno1
```

**Salida:**
```
+-------------------+--------------------------------------+
| Field             | Value                                |
+-------------------+--------------------------------------+
| id                | d385bd0f-5963-4d69-9ca8-0a82fa2909b7 |
| name              | subnet-alumno1                       |
| cidr              | 10.0.0.0/24                          |
| gateway_ip        | 10.0.0.1                             |
| dns_nameservers   | 8.8.8.8                              |
| allocation_pools  | 10.0.0.2 - 10.0.0.254                |
| network_id        | 0fc4ee07-d00c-4845-8f11-a37e9a0cb090 |
| project_id        | 1784f6fb9e1b4b02853f9ef416d4fd40     |
+-------------------+--------------------------------------+
```

> El `project_id` confirma que esta subred pertenece a tu proyecto.

### 4.3 Ver la red ahora

```bat
openstack network show red-alumno1
```

**Salida (campo subnets):**
```
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| ...                       | ...                                  |
| subnets                   | d385bd0f-5963-4d69-9ca8-0a82fa2909b7 |
+---------------------------+--------------------------------------+
```

> Ahora `subnets` ya muestra el ID de `subnet-alumno1`. La red tiene su espacio de
> direccionamiento definido.

### 4.4 Listar todas las subredes

```bat
openstack subnet list
```

**Salida:**
```
+--------------------------------------+-----------------+--------------------------------------+----------------+
| ID                                   | Name            | Network                              | Subnet         |
+--------------------------------------+-----------------+--------------------------------------+----------------+
| a700b0dc-8f26-4bf7-b73e-2e2a0f638b39 | external-subnet | 4272e0a7-3f52-4ce5-8fab-00e69507c69b | 192.168.2.0/24 |
| d385bd0f-5963-4d69-9ca8-0a82fa2909b7 | subnet-alumno1  | 0fc4ee07-d00c-4845-8f11-a37e9a0cb090 | 10.0.0.0/24    |
+--------------------------------------+-----------------+--------------------------------------+----------------+
```

> Solo ves tus subredes (y `external-subnet` porque `external` es compartida).
> No ves las subredes de otros alumnos aunque tengan el mismo rango `10.0.0.0/24`.

---

## 5. Práctica 3 — Crear el router

### 5.1 Crear el router

```bat
openstack router create router-alumno1
```

**Salida:**
```
+-------------------------+--------------------------------------+
| Field                   | Value                                |
+-------------------------+--------------------------------------+
| id                      | 1291d6bc-6dc2-420f-b1f1-847e4a87436d |
| name                    | router-alumno1                       |
| ha                      | True                                 |
| status                  | ACTIVE                               |
| external_gateway_info   | null                                 |
+-------------------------+--------------------------------------+
```

> `ha=True` significa que este router tiene Alta Disponibilidad activada.
> Neutron lo implementa replicando el router en dos agentes de red distintos
> y usando IPs de heartbeat en el rango `169.254.192.0/18`.
>
> `external_gateway_info=null` — el router todavía no tiene salida a internet.
> Es como un router recién sacado de la caja, encendido pero sin cables.

### 5.2 Conectar el router a la red externa (gateway)

```bat
openstack router set router-alumno1 --external-gateway external
```

**Salida de `openstack router show router-alumno1` tras el comando:**
```
+----------------------+-----------------------------------------------------------+
| Field                | Value                                                     |
+----------------------+-----------------------------------------------------------+
| external_gateway_info| network_id='4272e0a7-...',                                |
|                      | external_fixed_ips=[ip_address='192.168.2.210', ...]     |
|                      | enable_snat=True                                          |
+----------------------+-----------------------------------------------------------+
```

> Neutron asigna automáticamente una IP del rango `external` al router: `192.168.2.210`.
> Esa será la IP desde la que las VMs saldrán a internet (NAT/SNAT).
>
> `enable_snat=True` significa que el router hace Source NAT: las VMs de la subred privada
> salen a internet con la IP `192.168.2.210` (no con su IP privada `10.0.0.x`).

### 5.3 Añadir la subred al router

```bat
openstack router add subnet router-alumno1 subnet-alumno1
```

> Este comando no produce salida si tiene éxito.
> Internamente crea un port en `red-alumno1` con IP `10.0.0.1` y lo conecta al router.

### 5.4 Ver los detalles del router

```bat
openstack router show router-alumno1
```

**Salida (campos clave):**
```
+----------------------+-----------------------------------------------------------+
| Field                | Value                                                     |
+----------------------+-----------------------------------------------------------+
| id                   | 1291d6bc-6dc2-420f-b1f1-847e4a87436d                      |
| name                 | router-alumno1                                            |
| ha                   | True                                                      |
| status               | ACTIVE                                                    |
| external_gateway_info| network_id='4272e0a7-...',                                |
|                      | external_fixed_ips=[ip_address='192.168.2.210', ...]     |
|                      | enable_snat=True                                          |
| interfaces_info      | [ip_address='169.254.193.104', ...] (HA port)            |
|                      | [ip_address='169.254.192.127', ...] (HA port)            |
|                      | [ip_address='10.0.0.1', subnet_id='d385bd0f-...']        |
+----------------------+-----------------------------------------------------------+
```

> Ahora el router tiene:
> - Gateway hacia `external` con IP `192.168.2.210`
> - Interfaz interna en `subnet-alumno1` con IP `10.0.0.1`
> - Dos IPs `169.254.x.x` — son los puertos internos de HA (heartbeat entre agentes)
>
> La topología `internet → external(192.168.2.210) → router → red-alumno1(10.0.0.x)` está completa.

### 5.5 Ver los ports del router

```bat
openstack port list --router router-alumno1
```

**Salida:**
```
+--------------------------------------+------+-------------------+-----------------------------------------------------+--------+
| ID                                   | Name | MAC Address       | Fixed IP Addresses                                  | Status |
+--------------------------------------+------+-------------------+-----------------------------------------------------+--------+
| 1e6c501d-...                         |      | fa:16:3e:xx:xx:xx | ip_address='169.254.193.104', subnet_id='...'       | ACTIVE |
| 4a9143ba-...                         |      | fa:16:3e:xx:xx:xx | ip_address='192.168.2.210', subnet_id='...'         | DOWN   |
| 4ff08aa0-...                         |      | fa:16:3e:xx:xx:xx | ip_address='169.254.192.127', subnet_id='...'       | ACTIVE |
| c145f97e-...                         |      | fa:16:3e:80:6b:87 | ip_address='10.0.0.1', subnet_id='d385bd0f-...'    | ACTIVE |
+--------------------------------------+------+-------------------+-----------------------------------------------------+--------+
```

> El router tiene 4 ports:
> - **`192.168.2.210`** — la interfaz de gateway hacia `external` (estado DOWN es normal cuando
>   no hay tráfico activo en ese momento)
> - **`10.0.0.1`** — la interfaz interna que da acceso a `subnet-alumno1`
> - **`169.254.193.104` y `169.254.192.127`** — ports internos de HA (alta disponibilidad),
>   los puedes ignorar; los gestiona Neutron automáticamente

---

## 6. Práctica 4 — Inspeccionar ports de la red

### 6.1 Listar ports de la red privada

```bat
openstack port list --network red-alumno1
```

**Salida:**
```
+--------------------------------------+------+-------------------+-----------------------------------------------+--------+
| ID                                   | Name | MAC Address       | Fixed IP Addresses                            | Status |
+--------------------------------------+------+-------------------+-----------------------------------------------+--------+
| 7ce8901b-...                         |      | fa:16:3e:14:84:fc | ip_address='10.0.0.2', subnet_id='d385bd0f-'  | ACTIVE |
| c145f97e-...                         |      | fa:16:3e:80:6b:87 | ip_address='10.0.0.1', subnet_id='d385bd0f-'  | ACTIVE |
+--------------------------------------+------+-------------------+-----------------------------------------------+--------+
```

> Hay dos ports creados automáticamente por Neutron, sin que tú los hayas pedido:
> - `10.0.0.2` — el agente DHCP (reserva la `.2` para sí mismo)
> - `10.0.0.1` — la interfaz interna del router
>
> Cuando lances VMs, cada una recibirá una IP del rango `10.0.0.3` en adelante y tendrá
> su propio port aquí con `device_owner=compute:nova`.

### 6.2 Ver detalles del port del agente DHCP

```bat
openstack port show 7ce8901b-...
```

**Salida (campos clave):**
```
+--------------+--------------------------------------+
| Field        | Value                                |
+--------------+--------------------------------------+
| id           | 7ce8901b-...                         |
| fixed_ips    | ip_address='10.0.0.2'                |
| mac_address  | fa:16:3e:14:84:fc                    |
| device_owner | network:dhcp                         |
| status       | ACTIVE                               |
+--------------+--------------------------------------+
```

> `device_owner=network:dhcp` — este port lo usa el agente DHCP de Neutron.
> Cuando una VM arranca y pide IP por DHCP, este agente responde asignándole
> una IP del `allocation_pool` (`10.0.0.3` en adelante).

### 6.3 Ver detalles del port del router

```bat
openstack port show c145f97e-...
```

**Salida (campos clave):**
```
+--------------+--------------------------------------+
| Field        | Value                                |
+--------------+--------------------------------------+
| id           | c145f97e-...                         |
| fixed_ips    | ip_address='10.0.0.1'                |
| mac_address  | fa:16:3e:80:6b:87                    |
| device_owner | network:ha_router_replicated_interface |
| status       | ACTIVE                               |
+--------------+--------------------------------------+
```

> `device_owner=network:ha_router_replicated_interface` — el tipo específico para routers con HA.
> En un router sin HA sería `network:router_interface`.
> Este port es la puerta de enlace de las VMs: todo el tráfico que salga de la subred
> pasa por aquí hacia el router y de ahí al exterior.

---

## 7. Práctica 5 — Security groups

### 7.1 Ver el security group por defecto

```bat
openstack security group list
```

**Salida:**
```
+--------------------------------------+------------+-----------------------+----------------------------------+------+--------+
| ID                                   | Name       | Description           | Project                          | Tags | Shared |
+--------------------------------------+------------+-----------------------+----------------------------------+------+--------+
| 3f12e9be-6cba-475e-91cb-29a3b571382f | default    | Default security group| 5405e74885034e1c87dc9c55149adb62 | []   | False  |
| 3f3e3ef6-98c4-460a-b418-1b6c117462a4 | default    | Default security group| 1784f6fb9e1b4b02853f9ef416d4fd40 | []   | False  |
| 5a879812-859a-419f-969e-a5da38a8308a | default    | Default security group| b8f18bc305e34503973916c65f60506e | []   | False  |
| 7eed2e2b-9db3-4f2e-877e-d21a5873aeec | default    | Default security group| 6e1deb9087e547369227c551b3a0e814 | []   | False  |
+--------------------------------------+------------+-----------------------+----------------------------------+------+--------+
```

> Aparecen 4 SGs con nombre `default` — uno por cada proyecto del entorno. El tuyo es el de
> `project_id` `1784f6fb9e1b4b02853f9ef416d4fd40` (ID: `3f3e3ef6-...`).
>
> **Importante:** `openstack security group show default` fallará si el cliente ve más de un
> SG con ese nombre (de distintos proyectos). Usa el ID en ese caso.

```bat
openstack security group show 3f3e3ef6-98c4-460a-b418-1b6c117462a4
```

**Salida:**
```
+-----------------+------------------------------------------------------------+
| Field           | Value                                                      |
+-----------------+------------------------------------------------------------+
| id              | 3f3e3ef6-98c4-460a-b418-1b6c117462a4                       |
| name            | default                                                    |
| description     | Default security group                                     |
| project_id      | 1784f6fb9e1b4b02853f9ef416d4fd40                           |
| rules           | direction='ingress', ethertype='IPv4',                     |
|                 |   remote_group_id='3f3e3ef6-...' (mismo SG)               |
|                 | direction='ingress', ethertype='IPv6',                     |
|                 |   remote_group_id='3f3e3ef6-...' (mismo SG)               |
|                 | direction='egress', ethertype='IPv4'                       |
|                 | direction='egress', ethertype='IPv6'                       |
+-----------------+------------------------------------------------------------+
```

> El SG `default` tiene 4 reglas:
> - **2 egress**: permite todo el tráfico saliente (IPv4 e IPv6) — sin restricciones
> - **2 ingress**: solo permite tráfico entrante desde otras VMs del **mismo** security group
>   (`remote_group_id` apunta a sí mismo)
>
> Esto significa que si lanzas dos VMs con el SG `default`, pueden comunicarse entre sí,
> pero no podrás hacer ping ni SSH desde fuera.

### 7.2 Crear un security group

```bat
openstack security group create sg-alumno1 --description "SSH e ICMP para el lab de Neutron"
```

**Salida:**
```
+-----------------+------------------------------------------------------------+
| Field           | Value                                                      |
+-----------------+------------------------------------------------------------+
| id              | 9b500f2e-5237-4e5d-bcea-ca9e7ea91c5f                       |
| name            | sg-alumno1                                                 |
| description     | SSH e ICMP para el lab de Neutron                          |
| project_id      | 1784f6fb9e1b4b02853f9ef416d4fd40                           |
| rules           | direction='egress', ethertype='IPv6'                       |
|                 | direction='egress', ethertype='IPv4'                       |
+-----------------+------------------------------------------------------------+
```

> El nuevo SG hereda las dos reglas de egress por defecto (todo el tráfico saliente permitido).
> No tiene ninguna regla de ingress — por ahora bloquea todo el tráfico entrante.

### 7.3 Añadir regla para ICMP (ping)

```bat
openstack security group rule create sg-alumno1 --protocol icmp --ingress
```

**Salida:**
```
+-------------------------+--------------------------------------+
| Field                   | Value                                |
+-------------------------+--------------------------------------+
| id                      | 734f6178-df0d-4933-83d7-c9b843359de8 |
| direction               | ingress                              |
| protocol                | icmp                                 |
| remote_ip_prefix        | 0.0.0.0/0                            |
| ether_type              | IPv4                                 |
+-------------------------+--------------------------------------+
```

> `remote_ip_prefix=0.0.0.0/0` significa que acepta ICMP desde cualquier origen.
> Sin esta regla, los pings a la floating IP no obtendrán respuesta.

### 7.4 Añadir regla para SSH

```bat
openstack security group rule create sg-alumno1 --protocol tcp --dst-port 22 --ingress
```

**Salida:**
```
+-------------------------+--------------------------------------+
| Field                   | Value                                |
+-------------------------+--------------------------------------+
| id                      | c541b75f-de69-421c-a9fb-7332d368ebfb |
| direction               | ingress                              |
| protocol                | tcp                                  |
| port_range_min          | 22                                   |
| port_range_max          | 22                                   |
| remote_ip_prefix        | 0.0.0.0/0                            |
| ether_type              | IPv4                                 |
+-------------------------+--------------------------------------+
```

> Permite TCP al puerto 22 desde cualquier origen. Sin esta regla, el cliente SSH
> se quedaría esperando sin respuesta al intentar conectarse a la floating IP.

### 7.5 Ver las reglas del security group

```bat
openstack security group rule list sg-alumno1 --column Direction --column "IP Protocol" --column "Port Range" --column "IP Range"
```

**Salida:**
```
+-------------+-----------+------------+-----------+
| IP Protocol | IP Range  | Port Range | Direction |
+-------------+-----------+------------+-----------+
| None        | ::/0      |            | egress    |
| icmp        | 0.0.0.0/0 |            | ingress   |
| tcp         | 0.0.0.0/0 | 22:22      | ingress   |
| None        | 0.0.0.0/0 |            | egress    |
+-------------+-----------+------------+-----------+
```

> Cuatro reglas en total:
> - `egress` (sin protocolo ni puerto) para IPv4 e IPv6 — todo el tráfico saliente permitido
> - `ingress icmp` — permite ping desde cualquier IP
> - `ingress tcp/22` — permite SSH desde cualquier IP
>
> Este security group se asignará a las VMs en el lab de Nova para poder hacer ping y SSH.

---

## 8. Práctica 6 — Crear una floating IP

### 8.1 Crear la floating IP

```bat
openstack floating ip create external
```

**Salida:**
```
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| id                  | e9ff036b-40ca-4c3e-b853-098d3c2019fb |
| floating_ip_address | 192.168.2.200                        |
| floating_network_id | 4272e0a7-3f52-4ce5-8fab-00e69507c69b |
| fixed_ip_address    | None                                 |
| port_id             | None                                 |
| router_id           | None                                 |
| status              | DOWN                                 |
| project_id          | 1784f6fb9e1b4b02853f9ef416d4fd40     |
+---------------------+--------------------------------------+
```

> Neutron asignó la IP `192.168.2.200` del pool `external`.
> `status=DOWN` es el estado correcto cuando la floating IP no está asignada a ninguna VM.
> `port_id=None` y `fixed_ip_address=None` confirman que aún no hay VM vinculada.

### 8.2 Ver tus floating IPs

```bat
openstack floating ip list
```

**Salida:**
```
+--------------------------------------+---------------------+------------------+------+--------------------------------------+----------------------------------+
| ID                                   | Floating IP Address | Fixed IP Address | Port | Floating Network                     | Project                          |
+--------------------------------------+---------------------+------------------+------+--------------------------------------+----------------------------------+
| e9ff036b-40ca-4c3e-b853-098d3c2019fb | 192.168.2.200       | None             | None | 4272e0a7-3f52-4ce5-8fab-00e69507c69b | 1784f6fb9e1b4b02853f9ef416d4fd40 |
+--------------------------------------+---------------------+------------------+------+--------------------------------------+----------------------------------+
```

> La floating IP `192.168.2.200` está reservada en tu proyecto pero sin asignar.
> En el lab de Nova la asignarás a `vm-alumno1` para poder acceder por SSH.

### 8.3 Ver detalles de la floating IP

```bat
openstack floating ip show e9ff036b-40ca-4c3e-b853-098d3c2019fb
```

**Salida:**
```
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| id                  | e9ff036b-40ca-4c3e-b853-098d3c2019fb |
| floating_ip_address | 192.168.2.200                        |
| floating_network_id | 4272e0a7-3f52-4ce5-8fab-00e69507c69b |
| fixed_ip_address    | None                                 |
| port_id             | None                                 |
| router_id           | None                                 |
| status              | DOWN                                 |
+---------------------+--------------------------------------+
```

> `status=DOWN` es correcto: la floating IP existe pero no está activa porque no tiene
> VM asignada. Cuando en Nova la asignes a una instancia, pasará a `ACTIVE`.

---

## 9. Resumen — Verificación de la topología

### 9.1 Ver el resumen de redes

```bat
openstack network list
```

**Salida:**
```
+--------------------------------------+-------------------------+--------------------------------------+
| ID                                   | Name                    | Subnets                              |
+--------------------------------------+-------------------------+--------------------------------------+
| 0fc4ee07-d00c-4845-8f11-a37e9a0cb090 | red-alumno1             | d385bd0f-5963-4d69-9ca8-0a82fa2909b7 |
| 4272e0a7-3f52-4ce5-8fab-00e69507c69b | external                | a700b0dc-8f26-4bf7-b73e-2e2a0f638b39 |
| 5ebeb068-24fc-42df-9333-f96bfd7474e7 | HA network tenant ...   | e049e614-1784-4af1-bb2d-cf48044f93df |
+--------------------------------------+-------------------------+--------------------------------------+
```

> Aparece también la red `HA network tenant ...` — es interna de OpenStack para HA del router.
> La puedes ignorar: la gestiona Neutron automáticamente.

### 9.2 Ver el resumen de subredes

```bat
openstack subnet list
```

**Salida:**
```
+--------------------------------------+---------------------------+--------------------------------------+------------------+
| ID                                   | Name                      | Network                              | Subnet           |
+--------------------------------------+---------------------------+--------------------------------------+------------------+
| a700b0dc-8f26-4bf7-b73e-2e2a0f638b39 | external-subnet           | 4272e0a7-3f52-4ce5-8fab-00e69507c69b | 192.168.2.0/24   |
| d385bd0f-5963-4d69-9ca8-0a82fa2909b7 | subnet-alumno1            | 0fc4ee07-d00c-4845-8f11-a37e9a0cb090 | 10.0.0.0/24      |
| e049e614-1784-4af1-bb2d-cf48044f93df | HA subnet tenant ...      | 5ebeb068-24fc-42df-9333-f96bfd7474e7 | 169.254.192.0/18 |
+--------------------------------------+---------------------------+--------------------------------------+------------------+
```

> La subred HA (`169.254.192.0/18`) también es interna del sistema. Solo muestra la tuya:
> `subnet-alumno1` con cidr `10.0.0.0/24`.

### 9.3 Ver el resumen de routers

```bat
openstack router list
```

**Salida:**
```
+--------------------------------------+----------------+--------+-------+----------------------------------+-------------+------+
| ID                                   | Name           | Status | State | Project                          | Distributed | HA   |
+--------------------------------------+----------------+--------+-------+----------------------------------+-------------+------+
| 1291d6bc-6dc2-420f-b1f1-847e4a87436d | router-alumno1 | ACTIVE | UP    | 1784f6fb9e1b4b02853f9ef416d4fd40 | False       | True |
+--------------------------------------+----------------+--------+-------+----------------------------------+-------------+------+
```

> `router-alumno1` está ACTIVE y UP con HA habilitado.

### 9.4 Ver el security group

```bat
openstack security group list
```

**Salida:**
```
+--------------------------------------+------------+-----------------------------------+----------------------------------+------+--------+
| ID                                   | Name       | Description                       | Project                          | Tags | Shared |
+--------------------------------------+------------+-----------------------------------+----------------------------------+------+--------+
| 3f12e9be-...                         | default    | Default security group            | 5405e748...                      | []   | False  |
| 3f3e3ef6-98c4-460a-b418-1b6c117462a4 | default    | Default security group            | 1784f6fb9e1b4b02853f9ef416d4fd40 | []   | False  |
| 5a879812-...                         | default    | Default security group            | b8f18bc3...                      | []   | False  |
| 7eed2e2b-...                         | default    | Default security group            | 6e1deb90...                      | []   | False  |
| 9b500f2e-5237-4e5d-bcea-ca9e7ea91c5f | sg-alumno1 | SSH e ICMP para el lab de Neutron | 1784f6fb9e1b4b02853f9ef416d4fd40 | []   | False  |
+--------------------------------------+------------+-----------------------------------+----------------------------------+------+--------+
```

> Ahora hay 5 SGs: los 4 `default` (uno por proyecto del entorno) y `sg-alumno1` (el tuyo).

### 9.5 Ver las floating IPs

```bat
openstack floating ip list
```

**Salida:**
```
+--------------------------------------+---------------------+------------------+------+--------------------------------------+
| ID                                   | Floating IP Address | Fixed IP Address | Port | Floating Network                     |
+--------------------------------------+---------------------+------------------+------+--------------------------------------+
| e9ff036b-40ca-4c3e-b853-098d3c2019fb | 192.168.2.200       | None             | None | 4272e0a7-3f52-4ce5-8fab-00e69507c69b |
+--------------------------------------+---------------------+------------------+------+--------------------------------------+
```

### Topología resultante

```
Internet
    │
[ red external ]  192.168.2.0/24  (red provider — del admin)
    │
[ router-alumno1 ]  192.168.2.210 (gateway) ↔ 10.0.0.1 (interfaz interna)
    │
[ red-alumno1 / subnet-alumno1 ]  10.0.0.0/24
    │
(aquí irán tus VMs en el lab de Nova)

Floating IP reservada: 192.168.2.200 (sin asignar todavía)
```

---

## 10. Limpieza

```bat
rem 1. Liberar la floating IP
openstack floating ip delete e9ff036b-40ca-4c3e-b853-098d3c2019fb

rem 2. Desconectar la subred del router
openstack router remove subnet router-alumno1 subnet-alumno1

rem 3. Quitar el gateway externo del router
openstack router unset --external-gateway router-alumno1

rem 4. Borrar el router
openstack router delete router-alumno1

rem 5. Borrar la red privada (borra también la subred automáticamente)
openstack network delete red-alumno1

rem 6. Borrar el security group
openstack security group delete sg-alumno1
```

### Verificar que has limpiado todo

```bat
openstack network list
openstack router list
openstack security group list
openstack floating ip list
```

**Salida tras limpieza:**
```
+--------------------------------------+----------+--------------------------------------+
| ID                                   | Name     | Subnets                              |
+--------------------------------------+----------+--------------------------------------+
| 4272e0a7-3f52-4ce5-8fab-00e69507c69b | external | a700b0dc-8f26-4bf7-b73e-2e2a0f638b39 |
+--------------------------------------+----------+--------------------------------------+

(router list vacío)

(security group list solo muestra default de cada proyecto)

(floating ip list vacío)
```

> El entorno vuelve al estado inicial. Solo queda la red `external` (del admin)
> y los SGs `default` de cada proyecto (que no se pueden borrar).
>
> **Recuerda el orden de limpieza:** siempre hay que liberar la floating IP, desconectar
> la subred del router y quitar el gateway **antes** de borrar el router. Si borras la red
> sin haber desconectado el router, Neutron lo rechazará porque tiene puertos activos.
