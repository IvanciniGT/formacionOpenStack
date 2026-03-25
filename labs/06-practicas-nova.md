# Prácticas de Nova — Máquinas virtuales en OpenStack

## Objetivo

En estas prácticas vas a:

- entender qué es Nova y cómo orquesta las instancias
- explorar imágenes y flavors disponibles
- crear un flavor personalizado
- crear una keypair SSH
- lanzar instancias y controlar su ciclo de vida
- asignar floating IPs y conectarte por SSH
- usar cloud-init para personalizar una VM al arranque
- crear un snapshot de instancia
- verificar conectividad entre dos VMs en la misma red

## ¿Qué es Nova?

Nova es el servicio de **cómputo** de OpenStack.
Se encarga de lanzar, parar, redimensionar y gestionar las instancias (máquinas virtuales).

Nova no almacena imágenes (eso es Glance), ni gestiona redes (eso es Neutron), ni almacena volúmenes (eso es Cinder). Nova **orquesta** todos esos servicios para arrancar una VM.

## Conceptos clave

| Concepto | Descripción |
|---|---|
| **Instancia** | La VM en sí. Tiene CPU, RAM, disco efímero y una o más interfaces de red. |
| **Flavor** | La "talla" de la VM: cuántas vCPUs, cuánta RAM, cuánto disco raíz. |
| **Keypair** | Par de claves SSH. OpenStack inyecta la clave pública en la VM al crearla. |
| **User data** | Script que cloud-init ejecuta en el primer arranque de la VM. |
| **Consola VNC** | Acceso gráfico de emergencia a la VM, sin necesidad de red ni SSH. |
| **Snapshot** | Foto del estado del disco de la VM. Se guarda como imagen en Glance. |

## Tu contexto en este laboratorio

En este laboratorio usas tu usuario habitual (`alumno1`) con tu proyecto (`proyecto-alumno1`).
Tienes rol `admin` en tu dominio, lo que te permite crear flavors y gestionar todos los recursos del lab.

---

# 0. Requisitos previos — Infraestructura de red

> Si vienes del lab de Neutron y ya limpiaste, recrea los recursos de red con estos
> comandos. Si los tienes de antes, sáltate este apartado.

## 0.1 Activar entorno y cargar credenciales

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
```

## 0.2 Recrear la infraestructura de red

```bat
rem Red privada y subred.
openstack network create red-alumno1
openstack subnet create subnet-alumno1 --network red-alumno1 --subnet-range 10.0.0.0/24 --gateway 10.0.0.1 --dns-nameserver 8.8.8.8

rem Router conectado a la red externa.
openstack router create router-alumno1
openstack router set router-alumno1 --external-gateway external
openstack router add subnet router-alumno1 subnet-alumno1

rem Security group con SSH e ICMP.
openstack security group create sg-alumno1 --description "SSH e ICMP para el lab de Nova"
openstack security group rule create sg-alumno1 --protocol icmp --ingress
openstack security group rule create sg-alumno1 --protocol tcp --dst-port 22 --ingress
```

---

# 1. Preparación del entorno

## 1.1 Verificar autenticación

```bat
rem Comprueba que tienes token válido y que estás en el proyecto correcto.
openstack token issue
```

## 1.2 Verificar que Nova está disponible

```bat
rem Busca el servicio de cómputo en el catálogo.
rem Debe aparecer un servicio de tipo "compute".
openstack catalog show compute
```

---

# 2. Explorar imágenes y flavors

Antes de lanzar una VM necesitas elegir imagen y flavor.

## 2.1 Listar imágenes disponibles

```bat
rem Lista las imágenes activas accesibles desde tu proyecto.
rem Solo ves las tuyas (privadas) y las de comunidad/públicas del entorno.
openstack image list --status active
```

## 2.2 Ver detalles de la imagen cirros

```bat
rem Muestra los detalles de la imagen que usaremos: tamaño, formato, visibilidad.
rem Cirros es una imagen Linux mínima (~20 MB) pensada para testing.
openstack image show mi-cirros
```

> **Nota:** En un entorno compartido puede haber varias imágenes con el mismo nombre `mi-cirros`
> (una por alumno). Si el comando devuelve *"More than one Image exists"*, obtén el ID
> de la tuya con:
> ```bat
> openstack image list --name mi-cirros
> ```
> Usa ese ID en todos los comandos que piden `--image mi-cirros`.

## 2.3 Listar flavors disponibles

```bat
rem Lista los flavors del entorno: las "tallas" de VM disponibles.
rem Columnas clave: Name, RAM (MB), Disk (GB), VCPUs.
openstack flavor list
```

## 2.4 Ver detalles de un flavor

```bat
rem Muestra todos los detalles de un flavor concreto.
openstack flavor show m1.tiny
```

### Qué debes observar

- Los flavors disponibles (m1.tiny, m1.small, m1.medium...) los gestiona el administrador
- Tú podrás crear tus propios flavors personalizados (siguiente sección)
- La imagen `mi-cirros` es la que usarás para lanzar las VMs del lab

---

# 3. Práctica 1 — Crear un flavor personalizado

## Objetivo

Crear un flavor ligero para usar en el lab.

## 3.1 Crear el flavor

```bat
rem Crea un flavor personalizado llamado "flavor-alumno1".
rem --ram 512: 512 MB de RAM.
rem --disk 5: 5 GB de disco raíz efímero.
rem --vcpus 1: 1 CPU virtual.
rem Con el rol admin, los flavors se crean públicos por defecto (visibles a todos).
rem Para crearlo privado (solo tu proyecto) añade --private.
openstack flavor create flavor-alumno1 --ram 512 --disk 5 --vcpus 1
```

## 3.2 Verificar el flavor creado

```bat
openstack flavor show flavor-alumno1
```

### Preguntas

1. ¿En qué se diferencia `flavor-alumno1` de `m1.tiny`?
2. ¿Qué pasaría si creas un flavor con más RAM de la que tiene el hipervisor?
3. ¿El disco del flavor es un volumen Cinder? ¿Qué es exactamente?

---

# 4. Práctica 2 — Crear una keypair SSH

## Objetivo

Crear un par de claves SSH. OpenStack inyectará la clave pública en la VM al crearla.
Sin keypair solo puedes acceder por consola VNC o por contraseña (si la imagen la permite).

## 4.1 Crear la keypair

```bat
rem Genera un par de claves RSA y guarda la clave privada en un fichero local.
rem La clave pública se almacena en OpenStack y se inyectará en las VMs.
rem --private-key: fichero donde se guarda la clave privada (solo tú tienes acceso a ella).
openstack keypair create keypair-alumno1 --private-key keypair-alumno1.pem
```

En Linux/macOS ajusta los permisos del fichero:

```bash
chmod 600 keypair-alumno1.pem
```

## 4.2 Ver las keypairs existentes

```bat
rem Lista las keypairs de tu proyecto.
openstack keypair list
```

## 4.3 Ver detalles de la keypair

```bat
rem Muestra la huella (fingerprint) de la clave pública almacenada en OpenStack.
rem La clave privada NUNCA se sube a OpenStack: solo la pública.
openstack keypair show keypair-alumno1
```

### Preguntas

1. ¿Dónde se almacena la clave privada? ¿Y la pública?
2. ¿Qué pasaría si pierdes el fichero `.pem`? ¿Puedes recuperarlo de OpenStack?
3. ¿Por qué es importante el `chmod 600` en Linux/macOS?

---

# 5. Práctica 3 — Lanzar la primera VM

## Objetivo

Crear una instancia usando la imagen cirros, el flavor personalizado, la keypair y la red del lab.

## 5.1 Lanzar la VM

```bat
rem Crea la instancia "vm-alumno1".
rem --image: imagen de disco desde la que arranca.
rem --flavor: talla de la VM (CPU, RAM, disco).
rem --network: red privada donde se conectará.
rem --security-group: reglas de firewall que se aplican.
rem --key-name: keypair cuya clave pública se inyectará en la VM.
rem --wait: espera hasta que la VM esté en estado ACTIVE antes de devolver el prompt.
openstack server create vm-alumno1 --image mi-cirros --flavor flavor-alumno1 --network red-alumno1 --security-group sg-alumno1 --key-name keypair-alumno1 --wait
```

> Si hay varias imágenes `mi-cirros`, usa el ID en lugar del nombre:
> ```bat
> openstack image list --name mi-cirros
> openstack server create vm-alumno1 --image <ID-de-tu-mi-cirros> --flavor flavor-alumno1 --network red-alumno1 --security-group sg-alumno1 --key-name keypair-alumno1 --wait
> ```

## 5.2 Ver el estado de la VM

```bat
rem Muestra todos los detalles de la instancia: estado, IP, flavor, imagen, etc.
rem Estado esperado: ACTIVE. Si está en ERROR, revisa los logs.
openstack server show vm-alumno1
```

## 5.3 Ver la lista de instancias

```bat
rem Lista todas las instancias de tu proyecto con su estado y red.
openstack server list
```

## 5.4 Ver los logs de arranque

```bat
rem Muestra la salida de consola (stdout) de la VM desde el arranque.
rem Útil para ver si cloud-init ha terminado y si hay errores.
rem En cirros verás el proceso de arranque y el prompt de login al final.
openstack console log show vm-alumno1
```

## 5.5 Acceder por consola VNC

```bat
rem Obtiene la URL de la consola gráfica VNC.
rem Ábrela en el navegador para ver la VM como si tuvieras monitor conectado.
rem Usuario: cirros / Contraseña: gocubsgo
openstack console url show vm-alumno1
```

### Preguntas

1. ¿Qué IP privada tiene la VM? ¿De qué subred viene?
2. ¿Cuánto tarda en pasar de BUILD a ACTIVE?
3. ¿Ves la keypair que creaste en los logs de arranque?

---

# 6. Práctica 4 — Asignar floating IP y conectar por SSH

## Objetivo

Dar acceso exterior a la VM asignando una floating IP y conectarte por SSH.

## 6.1 Crear una floating IP

```bat
rem Reserva una IP pública del pool de la red external.
openstack floating ip create external
```

## 6.2 Asignar la floating IP a la VM

```bat
rem Asocia la floating IP a la instancia.
rem Sustituye <IP-flotante> por la IP que obtuviste en el paso anterior.
openstack server add floating ip vm-alumno1 <IP-flotante>
```

## 6.3 Verificar la asignación

```bat
rem Comprueba que la VM ya tiene la floating IP asignada.
rem Verás dos IPs: la privada (10.0.0.x) y la pública (192.168.x.x).
openstack server show vm-alumno1 --column addresses
```

## 6.4 Conectarse por SSH con la keypair

En Linux/macOS:

```bash
# -i: fichero de clave privada.
# cirros: usuario por defecto de la imagen cirros.
# Sustituye <IP-flotante> por tu IP pública.
ssh -i keypair-alumno1.pem cirros@<IP-flotante>
```

En Windows (PowerShell, si ssh está instalado):

```powershell
ssh -i keypair-alumno1.pem cirros@<IP-flotante>
```

> Si la conexión se cuelga, revisa que el security group tiene la regla TCP/22.
> Si el servidor rechaza la clave, asegúrate de que `chmod 600` está aplicado.

## 6.5 Desde dentro de la VM: comprobar la red

```bash
# Dentro de la VM cirros:
ip addr        # ver IP privada
ip route       # ver la ruta por defecto (el router)
ping 8.8.8.8   # comprobar salida a Internet a través del router
```

### Preguntas

1. ¿Puedes hacer ping a Internet desde dentro de la VM?
2. ¿Qué IP aparece como puerta de enlace? ¿La reconoces?
3. ¿Cuántas IPs tiene la VM? ¿Cuál es la diferencia entre ellas?

---

# 7. Práctica 5 — Personalizar la VM con cloud-init (user data)

## Objetivo

Lanzar una segunda VM que ejecute un script automáticamente al arrancar.
Esto simula el aprovisionamiento automático de servidores en un entorno real.

## 7.1 Crear el fichero de user data

Crea un fichero llamado `userdata.sh` con este contenido:

```bash
#!/bin/sh
echo "Hola desde cloud-init" > /tmp/saludo.txt
echo "Hostname: $(hostname)" >> /tmp/saludo.txt
echo "Fecha: $(date)" >> /tmp/saludo.txt
```

En Windows (PowerShell):

```powershell
@"
#!/bin/sh
echo "Hola desde cloud-init" > /tmp/saludo.txt
echo "Hostname: `$(hostname)" >> /tmp/saludo.txt
echo "Fecha: `$(date)" >> /tmp/saludo.txt
"@ | Set-Content userdata.sh
```

## 7.2 Lanzar la VM con user data

```bat
rem --user-data: fichero con el script que ejecutará cloud-init en el primer arranque.
rem Esta VM no tiene floating IP — se conectará a ella desde vm-alumno1.
openstack server create vm-alumno1-cloudinit --image mi-cirros --flavor flavor-alumno1 --network red-alumno1 --security-group sg-alumno1 --key-name keypair-alumno1 --user-data userdata.sh --wait
```

## 7.3 Ver los logs para comprobar que cloud-init ejecutó el script

```bat
rem Busca en los logs la ejecución de cloud-init y el resultado del script.
openstack console log show vm-alumno1-cloudinit
```

## 7.4 Conectarse desde vm-alumno1 a vm-alumno1-cloudinit (ping entre VMs)

```bat
rem Obtén la IP privada de la segunda VM.
openstack server show vm-alumno1-cloudinit --column addresses
```

Luego desde **dentro de vm-alumno1** (conectado por SSH):

```bash
# Sustituye <IP-privada-cloudinit> por la IP 10.0.0.x de la segunda VM.
ping <IP-privada-cloudinit>
```

> Esto demuestra que ambas VMs en la misma red privada se ven directamente
> sin necesidad de floating IP.

### Preguntas

1. ¿Ves en los logs cuándo ejecutó cloud-init el script?
2. ¿Las dos VMs se hacen ping entre ellas? ¿Por qué pueden verse sin floating IP?
3. ¿Qué ventaja tiene cloud-init frente a conectarse por SSH y ejecutar el script manualmente?

---

# 8. Práctica 6 — Ciclo de vida de una instancia

## Objetivo

Controlar el estado de la VM: parar, reiniciar y redimensionar.

## 8.1 Parar la VM (soft stop)

```bat
rem Envía una señal de apagado al SO de la VM (equivalente a "apagar el ordenador").
rem La VM pasa a estado SHUTOFF. Los datos del disco se conservan.
openstack server stop vm-alumno1
openstack server show vm-alumno1 --column status
```

## 8.2 Arrancar la VM parada

```bat
rem Arranca de nuevo la VM desde estado SHUTOFF.
openstack server start vm-alumno1
openstack server show vm-alumno1 --column status
```

## 8.3 Reiniciar la VM (reboot soft)

```bat
rem Reinicio suave: equivale a "restart" dentro del SO.
openstack server reboot vm-alumno1
openstack server show vm-alumno1 --column status
```

## 8.4 Reinicio forzado (hard reboot)

```bat
rem Reinicio duro: equivale a pulsar el botón de reset físico.
rem Usar solo si la VM no responde al reboot normal.
openstack server reboot --hard vm-alumno1
```

## 8.5 Redimensionar la VM (resize)

```bat
rem Cambia el flavor de la VM a m1.small (más RAM y disco).
rem Nova apaga la VM, migra el disco y la arranca con el nuevo flavor.
openstack server resize --flavor m1.small vm-alumno1 --wait

rem Después del resize hay que confirmarlo explícitamente.
rem Hasta que no confirmes, puedes revertir al flavor original.
openstack server resize confirm vm-alumno1
```

## 8.6 Verificar el nuevo flavor

```bat 
rem Comprueba que la VM ya está con el flavor m1.small.
openstack server show vm-alumno1 --column flavor
```

### Preguntas

1. ¿Qué diferencia hay entre `stop` y `reboot`?
2. ¿Los datos del disco se pierden al parar la VM?
3. ¿Por qué hay que confirmar el resize? ¿Para qué sirve el periodo de confirmación?

---

# 9. Resumen — Estado final

Antes de la limpieza, comprueba todo lo que has creado:

```bat
openstack server list
openstack keypair list
openstack flavor list | grep alumno1
openstack floating ip list
```

---

# 10. Limpieza

> Ejecuta estos comandos al finalizar el laboratorio.
> **El orden importa.**

## 10.1 Borrar las instancias

```bat
rem Borra todas las VMs del lab. --wait espera a que la eliminación sea completa.
openstack server delete vm-alumno1 vm-alumno1-cloudinit --wait
```

## 10.2 Liberar las floating IPs

```bat
rem Lista las floating IPs y bórralas todas.
rem Sustituye <ID> por los IDs que aparecen en el listado.
openstack floating ip list
openstack floating ip delete <ID>
```

## 10.3 Borrar la keypair

```bat
rem Borra la keypair de OpenStack (el fichero .pem local lo borras tú manualmente).
openstack keypair delete keypair-alumno1
```

## 10.4 Borrar el flavor personalizado

```bat
openstack flavor delete flavor-alumno1
```

## 10.5 Borrar la infraestructura de red

```bat
rem En el orden correcto: router desconectado antes de borrar.
openstack router remove subnet router-alumno1 subnet-alumno1
openstack router unset --external-gateway router-alumno1
openstack router delete router-alumno1
openstack network delete red-alumno1
openstack security group delete sg-alumno1
```

## 10.6 Verificar limpieza

```bat
openstack server list
openstack floating ip list
openstack keypair list
openstack network list
openstack router list
openstack security group list
openstack image list --status active | grep alumno1
```
