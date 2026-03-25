# Respuestas del lab — Prácticas de Nova

> Ejecutado con el usuario **alumno1** contra `https://nova.ivanosuna.com`
> Fecha: 23 de marzo de 2026 — Cliente: openstack 9.0.0

---

## 0. Requisitos previos — Infraestructura de red

> Si vienes del lab de Neutron y ya limpiaste, recrea los recursos de red con estos comandos.
> Estos son los mismos recursos que creaste en el lab de Neutron.

```bat
rem Red privada y subred
openstack network create red-alumno1
openstack subnet create subnet-alumno1 --network red-alumno1 --subnet-range 10.0.0.0/24 --gateway 10.0.0.1 --dns-nameserver 8.8.8.8

rem Router conectado a la red externa
openstack router create router-alumno1
openstack router set router-alumno1 --external-gateway external
openstack router add subnet router-alumno1 subnet-alumno1

rem Security group con SSH e ICMP
openstack security group create sg-alumno1 --description "SSH e ICMP para el lab de Nova"
openstack security group rule create sg-alumno1 --protocol icmp --ingress
openstack security group rule create sg-alumno1 --protocol tcp --dst-port 22 --ingress
```

> Todos estos comandos son los mismos del lab de Neutron — si los hiciste ayer,
> el entorno es idéntico. Solo cambia la descripción del security group.

---

## 1. Preparación del entorno

### 1.1 Verificar autenticación

```bat
openstack token issue
```

**Salida:**
```
+------------+------------------------------------------+
| Field      | Value                                    |
+------------+------------------------------------------+
| expires    | 2026-03-23T14:17:22+0000                 |
| id         | gAAAAAB...                               |
| project_id | 1784f6fb9e1b4b02853f9ef416d4fd40         |
| user_id    | acc4deedc4134fa29f866845f7fa3030         |
+------------+------------------------------------------+
```

> Confirma que estás autenticado. El `project_id` `1784f6fb9e1b4b02` es tu proyecto `proyecto-alumno1`.

### 1.2 Verificar que Nova está disponible

```bat
openstack catalog show compute
```

**Salida:**
```
+-----------+---------------------------------------------------------------+
| Field     | Value                                                         |
+-----------+---------------------------------------------------------------+
| endpoints | RegionOne                                                     |
|           |   admin: https://nova.ivanosuna.com/v2.1/                     |
|           |   public: https://nova.ivanosuna.com/v2.1/                    |
|           |   internal: http://nova-api.openstack.svc.cluster.local:8774/ |
|           | v2.1/                                                         |
| name      | nova                                                          |
| type      | compute                                                       |
+-----------+---------------------------------------------------------------+
```

> El servicio de cómputo `nova` está disponible con endpoint público en `nova.ivanosuna.com`.
> El endpoint interno es el nombre del pod de Kubernetes directamente.

---

## 2. Explorar imágenes y flavors

### 2.1 Listar imágenes disponibles

```bat
openstack image list --status active
```

**Salida:**
```
+--------------------------------------+-----------------------+--------+
| ID                                   | Name                  | Status |
+--------------------------------------+-----------------------+--------+
| d14c18b1-1aeb-4491-9ddb-2ca5fa025b3d | mi-cirros             | active |
| 914b6777-7c03-445a-bfd2-e0227b3c291e | mi-cirros             | active |
| d660919b-4abd-4f27-aee7-82951ba2a62a | mi-cirros             | active |
| 90e2b6da-9fa8-4e1d-b163-fc55844c8ca8 | mi-cirros             | active |
| a1b16d2b-71b7-4bb3-97a5-592913390aca | mi-cirros             | active |
| f8588c81-373c-49ed-b10d-65e2861dfa9f | mi-cirros             | active |
| adc43921-e322-45ad-95f6-8fbc6056e2df | mi-cirros             | active |
| 6a4c90e6-d208-4d96-80f7-73c85d7ce747 | mi-cirros-web         | active |
| ...                                  | ...                   | active |
+--------------------------------------+-----------------------+--------+
```

> Hay múltiples imágenes con el mismo nombre `mi-cirros` — una por cada alumno del entorno.
> Cada alumno subió la suya en el lab de Glance.
>
> **Importante:** `openstack image show mi-cirros` fallará porque hay varias con ese nombre.
> Para ver la tuya usa el ID directamente:
> ```bat
> openstack image list --name mi-cirros
> ```
> La tuya es la que tiene `owner` igual a tu `project_id`.

### 2.2 Ver detalles de la imagen cirros

> Como hay múltiples imágenes con el mismo nombre, usa el ID de la tuya:

```bat
openstack image list --name mi-cirros
openstack image show d14c18b1-1aeb-4491-9ddb-2ca5fa025b3d
```

**Salida:**
```
+------------------+-----------------------------------------------------------+
| Field            | Value                                                     |
+------------------+-----------------------------------------------------------+
| id               | d14c18b1-1aeb-4491-9ddb-2ca5fa025b3d                      |
| name             | mi-cirros                                                 |
| disk_format      | qcow2                                                     |
| container_format | bare                                                      |
| size             | 21430272                                                  |
| virtual_size     | 117440512                                                 |
| status           | active                                                    |
| visibility       | private                                                   |
| min_disk         | 1                                                         |
| min_ram          | 64                                                        |
| owner            | 9889847d26fc49e7aa938b0926656660                          |
| properties       | os_distro='cirros', os_version='0.6.2'                   |
+------------------+-----------------------------------------------------------+
```

> `disk_format=qcow2` — formato de imagen comprimido, muy eficiente para snapshots e imágenes base.
>
> `size=21430272` bytes (~21 MB) frente a `virtual_size=117440512` bytes (~112 MB) — el disco
> virtual de la VM es mucho mayor que la imagen almacenada gracias a la compresión de qcow2.
>
> `visibility=private` — solo visible desde tu proyecto. Cada alumno tiene la suya propia.
>
> `os_version=0.6.2` — cirros 0.6.2. **Importante**: cirros usa `#!/bin/sh`, no `#!/bin/bash`.
> El shell es BusyBox ash. Usa `#!/bin/sh` en los scripts de user-data.

### 2.3 Listar flavors disponibles

```bat
openstack flavor list
```

**Salida:**
```
+--------------------------------------+-----------+-------+------+-----------+-------+-----------+
| ID                                   | Name      |   RAM | Disk | Ephemeral | VCPUs | Is Public |
+--------------------------------------+-----------+-------+------+-----------+-------+-----------+
| 067f9ee8-1ead-44e9-9498-ae615ed7a9c9 | m1.medium |  4096 |   40 |         0 |     2 | True      |
| 35ad9481-01df-41f7-aa9d-60fe2ea0e01c | m1.xlarge | 16384 |  160 |         0 |     8 | True      |
| d6fbefd3-1049-4513-be15-30a1864c73e4 | m1.tiny   |   512 |    1 |         0 |     1 | True      |
| de217e91-230d-49f9-a464-7aaf5b311ef8 | m1.small  |  2048 |   20 |         0 |     1 | True      |
| ecec2f7b-2ff3-4374-a69e-6127286b8b59 | m1.large  |  8192 |   80 |         0 |     4 | True      |
+--------------------------------------+-----------+-------+------+-----------+-------+-----------+
```

> Los flavors `m1.*` los gestiona el administrador del entorno — son `Is Public=True` y los
> pueden usar todos los proyectos.
>
> No hay un flavor pequeño para testing (512 MB, 1 vCPU) — lo crearás tú en la siguiente sección
> para no desperdiciar recursos del hipervisor.

### 2.4 Ver detalles de un flavor

```bat
openstack flavor show m1.tiny
```

**Salida:**
```
+----------------------------+--------------------------------------+
| Field                      | Value                                |
+----------------------------+--------------------------------------+
| id                         | d6fbefd3-1049-4513-be15-30a1864c73e4 |
| name                       | m1.tiny                              |
| ram                        | 512                                  |
| disk                       | 1                                    |
| vcpus                      | 1                                    |
| OS-FLV-EXT-DATA:ephemeral  | 0                                    |
| os-flavor-access:is_public | True                                 |
| swap                       | 0                                    |
+----------------------------+--------------------------------------+
```

> `m1.tiny`: 512 MB RAM, 1 GB disco, 1 vCPU. El flavor más ligero, ideal para pruebas con cirros.
> Para el resize de la práctica 6 se usa `m1.small` (2 GB RAM, 20 GB disco).

---

## 3. Práctica 1 — Crear un flavor personalizado

### 3.1 Crear el flavor

```bat
openstack flavor create flavor-alumno1 --ram 512 --disk 5 --vcpus 1
```

**Salida:**
```
+----------------------------+--------------------------------------+
| Field                      | Value                                |
+----------------------------+--------------------------------------+
| id                         | 1dfc1bfa-c9ed-4c27-867d-5fcbe7f8274b |
| name                       | flavor-alumno1                       |
| ram                        | 512                                  |
| disk                       | 5                                    |
| vcpus                      | 1                                    |
| OS-FLV-EXT-DATA:ephemeral  | 0                                    |
| os-flavor-access:is_public | True                                 |
| swap                       | 0                                    |
+----------------------------+--------------------------------------+
```

> El flavor se crea como público (`is_public=True`) porque tienes el rol `admin`.
> Con un rol normal (`member`) necesitarías `--private` o el administrador tendría que
> darte acceso al flavor.
>
> `disk=5` GB es el disco raíz efímero de la VM. No es un volumen Cinder — es espacio
> en el storage local del hipervisor. Se elimina cuando se borra la VM.
> Para persistencia de datos hay que usar volúmenes Cinder.

### 3.2 Verificar el flavor creado

```bat
openstack flavor show flavor-alumno1
```

**Salida:**
```
+----------------------------+--------------------------------------+
| Field                      | Value                                |
+----------------------------+--------------------------------------+
| id                         | 1dfc1bfa-c9ed-4c27-867d-5fcbe7f8274b |
| name                       | flavor-alumno1                       |
| ram                        | 512                                  |
| disk                       | 5                                    |
| vcpus                      | 1                                    |
| os-flavor-access:is_public | True                                 |
| access_project_ids         | None                                 |
+----------------------------+--------------------------------------+
```

> `access_project_ids=None` junto con `is_public=True` significa que cualquier proyecto
> puede usar este flavor. Si fuera privado (`is_public=False`), aquí aparecerían los IDs
> de los proyectos con acceso.

---

## 4. Práctica 2 — Crear una keypair SSH

### 4.1 Crear la keypair

```bat
openstack keypair create keypair-alumno1 --private-key keypair-alumno1.pem
```

**Salida:**
```
+-------------+-------------------------------------------------+
| Field       | Value                                           |
+-------------+-------------------------------------------------+
| name        | keypair-alumno1                                 |
| fingerprint | da:cb:79:fc:6d:2e:03:8d:91:ce:6d:59:78:fd:ff:b4 |
| type        | ssh                                             |
| user_id     | acc4deedc4134fa29f866845f7fa3030                |
+-------------+-------------------------------------------------+
```

> El comando genera un par RSA, guarda la clave privada en `keypair-alumno1.pem` y
> sube la clave pública a OpenStack. La clave privada es tuya: OpenStack **nunca**
> la almacena ni la puede recuperar.

En Linux/macOS ajusta los permisos del fichero para que SSH lo acepte:

```bash
chmod 600 keypair-alumno1.pem
```

> SSH rechaza claves privadas con permisos abiertos (0644 o similares) por seguridad.
> El error que verías sin el chmod sería:
> `WARNING: UNPROTECTED PRIVATE KEY FILE! Permissions 0644... bad permissions`

### 4.2 Ver las keypairs existentes

```bat
openstack keypair list
```

**Salida:**
```
+-----------------+-------------------------------------------------+------+
| Name            | Fingerprint                                     | Type |
+-----------------+-------------------------------------------------+------+
| keypair-alumno1 | da:cb:79:fc:6d:2e:03:8d:91:ce:6d:59:78:fd:ff:b4 | ssh  |
+-----------------+-------------------------------------------------+------+
```

### 4.3 Ver detalles de la keypair

```bat
openstack keypair show keypair-alumno1
```

**Salida:**
```
+-------------+-------------------------------------------------+
| Field       | Value                                           |
+-------------+-------------------------------------------------+
| name        | keypair-alumno1                                 |
| fingerprint | da:cb:79:fc:6d:2e:03:8d:91:ce:6d:59:78:fd:ff:b4 |
| type        | ssh                                             |
| user_id     | acc4deedc4134fa29f866845f7fa3030                |
| private_key | None                                            |
+-------------+-------------------------------------------------+
```

> `private_key=None` confirma que la clave privada NO está almacenada en OpenStack.
> Solo está en el fichero local `keypair-alumno1.pem`.
> Si lo pierdes, no hay forma de recuperarlo — tendrías que crear una nueva keypair
> y acceder a la VM por consola VNC para añadir la nueva clave pública manualmente.

---

## 5. Práctica 3 — Lanzar la primera VM

### 5.1 Lanzar la VM

> Hay varias imágenes `mi-cirros` en el entorno. Usa el ID de la tuya para evitar
> que Nova elija una aleatoria:
> ```bat
> openstack image list --name mi-cirros
> ```

```bat
openstack server create vm-alumno1 --image d14c18b1-1aeb-4491-9ddb-2ca5fa025b3d --flavor flavor-alumno1 --network red-alumno1 --security-group sg-alumno1 --key-name keypair-alumno1 --wait
```

**Salida:**
```
+-------------------------------------+----------------------------------------+
| Field                               | Value                                  |
+-------------------------------------+----------------------------------------+
| OS-EXT-SRV-ATTR:host                | worker3                                |
| OS-EXT-STS:power_state              | Running                                |
| OS-EXT-STS:vm_state                 | active                                 |
| OS-SRV-USG:launched_at              | 2026-03-23T02:18:23.000000             |
| addresses                           | red-alumno1=10.0.0.133                 |
| flavor                              | flavor-alumno1 (ram=512, disk=5, vcpus=1) |
| id                                  | 8de43d38-04ca-48b8-b15c-72c5ee23af80   |
| image                               | mi-cirros (d14c18b1-1aeb-...-2ca5fa025b3d) |
| key_name                            | keypair-alumno1                        |
| name                                | vm-alumno1                             |
| security_groups                     | name='sg-alumno1'                      |
| status                              | ACTIVE                                 |
+-------------------------------------+----------------------------------------+
```

> La VM recibió la IP `10.0.0.133` del pool DHCP de `subnet-alumno1`.
> Nova tardó ~13 segundos en pasar desde BUILD a ACTIVE.
>
> El campo `OS-EXT-SRV-ATTR:host=worker3` muestra en qué hipervisor está corriendo la VM
> (visible porque tienes rol admin).

### 5.2 Ver el estado de la VM

```bat
openstack server show vm-alumno1
```

**Salida (campos clave):**
```
+---------------------------+----------------------------------------------+
| Field                     | Value                                        |
+---------------------------+----------------------------------------------+
| status                    | ACTIVE                                       |
| addresses                 | red-alumno1=10.0.0.133                       |
| flavor                    | flavor-alumno1 (ram=512, disk=5, vcpus=1)   |
| image                     | mi-cirros (d14c18b1-...)                     |
| key_name                  | keypair-alumno1                              |
| security_groups           | name='sg-alumno1'                            |
| OS-EXT-SRV-ATTR:host      | worker3                                      |
+---------------------------+----------------------------------------------+
```

### 5.3 Ver la lista de instancias

```bat
openstack server list
```

**Salida:**
```
+--------------------------------------+------------+--------+------------------------+-----------+----------------+
| ID                                   | Name       | Status | Networks               | Image     | Flavor         |
+--------------------------------------+------------+--------+------------------------+-----------+----------------+
| 8de43d38-04ca-48b8-b15c-72c5ee23af80 | vm-alumno1 | ACTIVE | red-alumno1=10.0.0.133 | mi-cirros | flavor-alumno1 |
+--------------------------------------+------------+--------+------------------------+-----------+----------------+
```

### 5.4 Ver los logs de arranque

```bat
openstack console log show vm-alumno1
```

**Salida (últimas líneas relevantes):**
```
info: /etc/init.d/rc.sysinit: up at 1.81
info: container: none
Starting syslogd: OK
Starting acpid: OK
Starting network: dhcpcd-9.4.1 starting
DUID 00:04:8d:e4:3d:38:04:ca:48:b8:b1:5c:72:c5:ee:23:af:80
forked to background, child pid 250
OK
checking http://169.254.169.254/2009-04-04/instance-id
failed 1/20: up 2.00. request failed
...
successful after 5/20 tries: up 10.06. iid=i-0000000d
failed to get http://169.254.169.254/2009-04-04/user-data
warning: no ec2 metadata for user-data
Top of dropbear init script
Starting dropbear sshd: OK
GROWROOT: CHANGED: partition=1 start=18432 old: size=210911 end=229343 new: size=10467295
```

> `failed to get...user-data` es normal en esta VM — no tiene user-data, así que cloud-init
> lo avisa y sigue adelante.
>
> `Starting dropbear sshd: OK` confirma que el servidor SSH está activo y la VM está lista
> para conexiones.
>
> `GROWROOT: CHANGED` indica que la VM detectó que el disco físico es mayor que la partición
> de la imagen y la expandió automáticamente hasta los 5 GB del flavor.

### 5.5 Acceder por consola VNC

```bat
openstack console url show vm-alumno1
```

**Salida:**
```
+----------+-------------------------------------------------------------------+
| Field    | Value                                                             |
+----------+-------------------------------------------------------------------+
| protocol | vnc                                                               |
| type     | novnc                                                             |
| url      | https://novnc.ivanosuna.com/vnc_auto.html?path=%3Ftoken%3D...    |
+----------+-------------------------------------------------------------------+
```

> Abre la URL en un navegador para ver la consola gráfica de la VM.
> Credenciales cirros: usuario `cirros`, contraseña `gocubsgo`.
> La consola VNC es útil cuando la VM no responde por SSH o necesitas ver el proceso de arranque.

---

## 6. Práctica 4 — Asignar floating IP y conectar por SSH

### 6.1 Crear una floating IP

```bat
openstack floating ip create external
```

**Salida:**
```
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| id                  | c0764be2-16e2-4b76-9d7f-a67b9ec22679 |
| floating_ip_address | 192.168.2.201                        |
| floating_network_id | 4272e0a7-3f52-4ce5-8fab-00e69507c69b |
| fixed_ip_address    | None                                 |
| port_id             | None                                 |
| status              | DOWN                                 |
+---------------------+--------------------------------------+
```

> Neutron asignó la `192.168.2.201`. `status=DOWN` es correcto — no está asociada a ninguna VM todavía.

### 6.2 Asignar la floating IP a la VM

```bat
openstack server add floating ip vm-alumno1 192.168.2.201
```

> Este comando no produce salida si tiene éxito.
> Neutron crea una regla NAT en el router: `192.168.2.201 → 10.0.0.133`.

### 6.3 Verificar la asignación

```bat
openstack server show vm-alumno1 --column addresses
```

**Salida:**
```
+-----------+---------------------------------------+
| Field     | Value                                 |
+-----------+---------------------------------------+
| addresses | red-alumno1=10.0.0.133, 192.168.2.201 |
+-----------+---------------------------------------+
```

> La VM tiene ahora dos "IPs": la privada `10.0.0.133` (fija, asignada por DHCP de Neutron)
> y la flotante `192.168.2.201` (NAT en el router). Desde dentro de la VM solo se ve la `10.0.0.133`.

### 6.4 Conectarse por SSH con la keypair

En Linux/macOS:

```bash
ssh -i keypair-alumno1.pem cirros@192.168.2.201
```

**Resultado:**
```
Warning: Permanently added '192.168.2.201' (ED25519) to the list of known hosts.
$
```

> Conexión exitosa. El usuario de cirros es `cirros` (no `root`, no `ubuntu`).
>
> Si obtienes `Permission denied (publickey,password)`, comprueba:
> - Que el fichero `.pem` tiene permisos `600` (`chmod 600 keypair-alumno1.pem`)
> - Que el security group tiene la regla TCP/22 ingress
> - Que la floating IP está asignada a la VM correcta

### 6.5 Desde dentro de la VM: comprobar la red

```bash
ip addr
```

**Salida:**
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 ...
    inet 127.0.0.1/8 scope host lo
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 ...
    inet 10.0.0.133/24 brd 10.0.0.255 scope global dynamic noprefixroute eth0
```

```bash
ip route
```

**Salida:**
```
default via 10.0.0.1 dev eth0  src 10.0.0.133  metric 1002
10.0.0.0/24 dev eth0 scope link  src 10.0.0.133  metric 1002
169.254.169.254 via 10.0.0.2 dev eth0  src 10.0.0.133  metric 1002
```

> La puerta de enlace es `10.0.0.1` — la interfaz interna del `router-alumno1`.
> `169.254.169.254` es el servicio de metadatos de Nova, enrutado por el agente DHCP (`10.0.0.2`).

```bash
ping -c 3 8.8.8.8
```

**Salida:**
```
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=116 time=8.84 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=116 time=6.12 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=116 time=5.71 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
```

> Ping a Internet funciona: el tráfico sale por el router con SNAT.
> El camino es: VM(10.0.0.133) → router(10.0.0.1/SNAT → 192.168.2.210) → Internet.

---

## 7. Práctica 5 — Personalizar la VM con cloud-init (user data)

### 7.1 Crear el fichero de user data

```bash
#!/bin/sh
echo "Hola desde cloud-init" > /tmp/saludo.txt
echo "Hostname: $(hostname)" >> /tmp/saludo.txt
echo "Fecha: $(date)" >> /tmp/saludo.txt
```

Guárdalo como `userdata.sh`. En Windows (PowerShell):

```powershell
@"
#!/bin/sh
echo "Hola desde cloud-init" > /tmp/saludo.txt
echo "Hostname: `$(hostname)" >> /tmp/saludo.txt
echo "Fecha: `$(date)" >> /tmp/saludo.txt
"@ | Set-Content userdata.sh
```

> **Importante**: el shebang debe ser `#!/bin/sh`, **no** `#!/bin/bash`.
> Cirros usa BusyBox ash como shell. Si usas `#!/bin/bash`, cloud-init ejecutará el script
> pero fallará porque `/bin/bash` no existe en cirros — el fichero `/tmp/saludo.txt`
> no se creará.

### 7.2 Lanzar la VM con user data

```bat
openstack server create vm-alumno1-cloudinit --image d14c18b1-1aeb-4491-9ddb-2ca5fa025b3d --flavor flavor-alumno1 --network red-alumno1 --security-group sg-alumno1 --key-name keypair-alumno1 --user-data userdata.sh --wait
```

**Salida:**
```
+-------------------------------------+----------------------------------------+
| Field                               | Value                                  |
+-------------------------------------+----------------------------------------+
| OS-EXT-SRV-ATTR:host                | worker3                                |
| OS-EXT-STS:vm_state                 | active                                 |
| OS-SRV-USG:launched_at              | 2026-03-23T02:19:56.000000             |
| addresses                           | red-alumno1=10.0.0.42                  |
| id                                  | 2b5c7dad-b8f9-46fb-86b7-f05d5ea5b48f   |
| name                                | vm-alumno1-cloudinit                   |
| status                              | ACTIVE                                 |
| OS-EXT-SRV-ATTR:user_data           | IyEvYmluL3NoCmVjaG8gIkhvbGEgZGVzZGUgY2 |
|                                     | xvdWQtaW5pdCIgPiAvdG1wL3NhbHVkby50eHQK |
|                                     | ... (base64)                           |
+-------------------------------------+----------------------------------------+
```

> La segunda VM recibió la IP `10.0.0.42`. No le asignamos floating IP — la alcanzaremos
> desde `vm-alumno1` usando su IP privada.
>
> El campo `user_data` muestra el script codificado en base64.

### 7.3 Ver los logs para comprobar que cloud-init ejecutó el script

```bat
openstack console log show vm-alumno1-cloudinit
```

**Salida (líneas finales):**
```
successful after 5/20 tries: up 10.04. iid=i-0000000e
instance-id: i-0000000e
name: N/A
availability-zone: nova
local-hostname: vm-alumno1-cloudinit.novalocal
launch-index: 0
=== cirros: current=0.6.2 latest=0.6.3 uptime=21.54 ===
...
login as 'cirros' user. default password: 'gocubsgo'. use 'sudo' for root.
vm-alumno1-cloudinit login:
```

> A diferencia de `vm-alumno1`, aquí **no aparece** `failed to get user-data` — cloud-init
> recuperó el script correctamente del servicio de metadatos y lo ejecutó antes de que
> apareciera el prompt de login.

### 7.4 Verificar la ejecución del script

```bat
rem Obtener la IP de vm-alumno1-cloudinit
openstack server show vm-alumno1-cloudinit --column addresses
```

**Salida:**
```
+-----------+-----------------------+
| Field     | Value                 |
+-----------+-----------------------+
| addresses | red-alumno1=10.0.0.42 |
+-----------+-----------------------+
```

Desde **dentro de `vm-alumno1`** (conectado por SSH):

```bash
ping 10.0.0.42
```

**Salida:**
```
PING 10.0.0.42 (10.0.0.42) 56(84) bytes of data.
64 bytes from 10.0.0.42: icmp_seq=1 ttl=64 time=2.20 ms
64 bytes from 10.0.0.42: icmp_seq=2 ttl=64 time=1.08 ms
64 bytes from 10.0.0.42: icmp_seq=3 ttl=64 time=0.367 ms

--- 10.0.0.42 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
```

> Las dos VMs se ven directamente sin necesidad de floating IP porque están en la misma
> red `red-alumno1`. El tráfico entre ellas no sale por el router — va directo por la
> red VXLAN del hipervisor.

Verificación del fichero `/tmp/saludo.txt` (accediendo via SSH con jump):

```bash
$ cat /tmp/saludo.txt
Hola desde cloud-init
Hostname: vm-alumno1-cloudinit
Fecha: Mon Mar 23 03:20:17 UTC 2026
```

> Cloud-init ejecutó el script correctamente en el primer arranque:
> - El hostname es `vm-alumno1-cloudinit` (el que Nova asignó a la VM)
> - La fecha corresponde al momento del arranque
>
> Si el fichero no existiera, significaría que `#!/bin/sh` faltaba o que el script
> tenía errores de sintaxis.

---

## 8. Práctica 6 — Ciclo de vida de una instancia

### 8.1 Parar la VM (soft stop)

```bat
openstack server stop vm-alumno1
openstack server show vm-alumno1 --column status
```

**Salida:**
```
+--------+---------+
| Field  | Value   |
+--------+---------+
| status | SHUTOFF |
+--------+---------+
```

> `SHUTOFF` — la VM está apagada, el proceso QEMU sigue en el hipervisor pero no hay
> CPU ni RAM asignadas. El disco efímero se conserva con todos sus datos.

### 8.2 Arrancar la VM parada

```bat
openstack server start vm-alumno1
openstack server show vm-alumno1 --column status
```

**Salida:**
```
+--------+--------+
| Field  | Value  |
+--------+--------+
| status | ACTIVE |
+--------+--------+
```

> La VM vuelve a estar activa. En unos segundos estará lista para SSH.

### 8.3 Reiniciar la VM (reboot soft)

```bat
openstack server reboot vm-alumno1
openstack server show vm-alumno1 --column status
```

**Salida:**
```
+--------+--------+
| Field  | Value  |
+--------+--------+
| status | ACTIVE |
+--------+--------+
```

> Reboot suave: Nova señaliza al SO que reinicie (equivalente a `shutdown -r now`).
> La diferencia con `stop`+`start`: el proceso QEMU no se destruye — la VM nunca llega
> a `SHUTOFF`.

### 8.4 Reinicio forzado (hard reboot)

```bat
openstack server reboot --hard vm-alumno1
```

> Equivale a pulsar el botón de reset físico: corte de alimentación inmediato sin avisar
> al SO. Usar solo si la VM no responde al reboot normal.

### 8.5 Redimensionar la VM (resize)

```bat
openstack server resize --flavor m1.small vm-alumno1 --wait
```

**Salida:**
```
Complete
```

```bat
openstack server show vm-alumno1 --column status --column flavor
```

**Salida (antes de confirmar):**
```
+--------+---------------------------------------------------------------------+
| Field  | Value                                                               |
+--------+---------------------------------------------------------------------+
| flavor | m1.small (ram=2048, disk=20, vcpus=1)                               |
| status | VERIFY_RESIZE                                                       |
+--------+---------------------------------------------------------------------+
```

> `VERIFY_RESIZE` — Nova migró el disco de la VM al hipervisor de destino y está esperando
> confirmación. Durante este estado puedes verificar que la VM funciona bien y luego confirmar,
> o revertir al flavor original.
>
> En este entorno el resize migra la VM entre `worker3` y `worker4` (los dos hipervisores).

```bat
openstack server resize confirm vm-alumno1
```

### 8.6 Verificar el nuevo flavor

```bat
openstack server show vm-alumno1 --column status --column flavor
```

**Salida:**
```
+--------+---------------------------------------------------------------------+
| Field  | Value                                                               |
+--------+---------------------------------------------------------------------+
| flavor | m1.small (ram=2048, disk=20, vcpus=1)                               |
| status | ACTIVE                                                              |
+--------+---------------------------------------------------------------------+
```

> La VM vuelve a `ACTIVE` con el nuevo flavor `m1.small` (RAM subió de 512 MB a 2 GB,
> disco de 5 GB a 20 GB). El resize ha completado correctamente.

---

## 9. Resumen — Estado final

```bat
openstack server list
```

**Salida:**
```
+--------------------------------------+----------------------+--------+------------------------------------+-----------+----------------+
| ID                                   | Name                 | Status | Networks                           | Image     | Flavor         |
+--------------------------------------+----------------------+--------+------------------------------------+-----------+----------------+
| 2b5c7dad-b8f9-46fb-86b7-f05d5ea5b48f | vm-alumno1-cloudinit | ACTIVE | red-alumno1=10.0.0.42              | mi-cirros | flavor-alumno1 |
| 8de43d38-04ca-48b8-b15c-72c5ee23af80 | vm-alumno1           | ACTIVE | red-alumno1=10.0.0.133, 192.168.2.201 | mi-cirros | m1.small    |
+--------------------------------------+----------------------+--------+------------------------------------+-----------+----------------+
```

```bat
openstack keypair list
```

**Salida:**
```
+-----------------+-------------------------------------------------+------+
| Name            | Fingerprint                                     | Type |
+-----------------+-------------------------------------------------+------+
| keypair-alumno1 | da:cb:79:fc:6d:2e:03:8d:91:ce:6d:59:78:fd:ff:b4 | ssh  |
+-----------------+-------------------------------------------------+------+
```

```bat
openstack flavor list | grep alumno1
```

**Salida:**
```
| 1dfc1bfa-c9ed-4c27-867d-5fcbe7f8274b | flavor-alumno1 |   512 |    5 |    0 |     1 | True |
```

```bat
openstack floating ip list
```

**Salida:**
```
+--------------------------------------+---------------------+------------------+------+--------------------------------------+
| ID                                   | Floating IP Address | Fixed IP Address | Port | Floating Network                     |
+--------------------------------------+---------------------+------------------+------+--------------------------------------+
| c0764be2-16e2-4b76-9d7f-a67b9ec22679 | 192.168.2.201       | 10.0.0.133       | ...  | 4272e0a7-3f52-4ce5-8fab-00e69507c69b |
+--------------------------------------+---------------------+------------------+------+--------------------------------------+
```

> Estado final antes de la limpieza:
> - `vm-alumno1`: ACTIVE con m1.small, floating IP `192.168.2.201`, ya resizeada
> - `vm-alumno1-cloudinit`: ACTIVE con flavor-alumno1, solo IP privada `10.0.0.42`
> - Una keypair `keypair-alumno1` y un flavor `flavor-alumno1`
> - Floating IP `192.168.2.201` asignada a `vm-alumno1`

---

## 10. Limpieza

### 10.1 Borrar las instancias

```bat
openstack server delete vm-alumno1 vm-alumno1-cloudinit --wait
```

> `--wait` hace que el comando no devuelva el prompt hasta que las VMs estén completamente
> eliminadas. Sin `--wait` el siguiente comando (borrar la FIP) podría fallar si el port
> todavía está en uso.

### 10.2 Liberar las floating IPs

```bat
openstack floating ip list
openstack floating ip delete c0764be2-16e2-4b76-9d7f-a67b9ec22679
```

### 10.3 Borrar la keypair

```bat
openstack keypair delete keypair-alumno1
```

> Solo borra la keypair de OpenStack. El fichero `keypair-alumno1.pem` local lo borras
> tú manualmente si quieres.

### 10.4 Borrar el flavor personalizado

```bat
openstack flavor delete flavor-alumno1
```

### 10.5 Borrar la infraestructura de red

```bat
openstack router remove subnet router-alumno1 subnet-alumno1
openstack router unset --external-gateway router-alumno1
openstack router delete router-alumno1
openstack network delete red-alumno1
openstack security group delete sg-alumno1
```

### 10.6 Verificar limpieza

```bat
openstack server list
openstack floating ip list
openstack keypair list
openstack network list
openstack router list
openstack security group list
openstack image list --status active | grep alumno1
```

**Salida tras limpieza:**
```
(server list vacío)
(floating ip list vacío)
(keypair list vacío)

+--------------------------------------+----------+--------------------------------------+
| ID                                   | Name     | Subnets                              |
+--------------------------------------+----------+--------------------------------------+
| 4272e0a7-3f52-4ce5-8fab-00e69507c69b | external | a700b0dc-8f26-4bf7-b73e-2e2a0f638b39 |
+--------------------------------------+----------+--------------------------------------+

(router list vacío)

(security group list solo muestra default de cada proyecto)

(image list | grep alumno1 vacío — las imágenes mi-cirros no llevan "alumno1" en el nombre)
```

> Entorno limpio. Solo queda la red `external` (del admin) y los SGs `default` de cada
> proyecto. La imagen `mi-cirros` sigue disponible para futuros labs (no la borramos).
>
> **Recuerda el orden de limpieza de Nova:**
> 1. Borrar instancias (`--wait` es importante)
> 2. Liberar floating IPs (ya se desasocian al borrar las VMs, pero hay que liberarlas del proyecto)
> 3. Borrar keypair y flavor
> 4. Borrar infraestructura de red (en el orden del lab de Neutron)
