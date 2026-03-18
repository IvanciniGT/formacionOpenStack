# Guía rápida del cliente `openstack`

## 1. Qué es

El comando `openstack` es el **cliente unificado** de OpenStack.

La idea mental correcta es:

> **objeto + verbo + argumentos**

No pienses en comandos sueltos. Piensa en recursos cloud y acciones sobre ellos.

---

## 2. Sintaxis básica

```bash
openstack [opciones-globales] <objeto> <acción> [subobjeto] [argumentos]
```

Ejemplos:

```bash
openstack server list
openstack image show ubuntu-24.04
openstack network create red-interna
openstack volume delete disco1
```

---

## 3. Configuración previa

Antes de usar el cliente, normalmente cargas un `openrc` o defines variables `OS_*`.

Las más típicas son:

* `OS_AUTH_URL`
* `OS_USERNAME`
* `OS_PASSWORD`
* `OS_PROJECT_NAME`
* `OS_USER_DOMAIN_NAME`
* `OS_PROJECT_DOMAIN_NAME`
* `OS_IDENTITY_API_VERSION`

Ejemplo:

```bash
source alumno1-openrc.sh
openstack token issue
```

---

## 4. Ayuda

```bash
openstack --help
openstack help server
openstack server --help
```

---

## 5. Objetos más importantes

### Identidad

* `token`
* `project`
* `user`
* `domain`
* `role`
* `service`
* `endpoint`

### Imágenes

* `image`

### Cómputo

* `server`
* `flavor`
* `keypair`

### Red

* `network`
* `subnet`
* `router`
* `port`
* `floating ip`
* `security group`

### Almacenamiento

* `volume`
* `volume type`
* `snapshot`

### Object Storage

* `container`
* `object`

---

## 6. Verbos principales

Los verbos que más se repiten son:

* `list` → listar varios
* `show` → ver uno en detalle
* `create` → crear
* `delete` → borrar
* `set` → modificar
* `unset` → quitar una propiedad
* `add` / `remove` → asociar o desasociar
* `start` / `stop` / `reboot` → ciclo de vida

Regla mental rápida:

* si quieres ver muchos → `list`
* si quieres ver uno → `show`
* si quieres crear → `create`
* si quieres borrar → `delete`

---

## 7. Ejemplos básicos

### Identidad

```bash
openstack token issue
openstack project list
openstack project show proyecto-alumno1
openstack user show alumno1
openstack role assignment list --user alumno1 --names
```

### Imágenes

```bash
openstack image list
openstack image show ubuntu
```

### Cómputo

```bash
openstack flavor list
openstack server list
openstack server show vm1
openstack server stop vm1
openstack server start vm1
openstack server reboot vm1
```

### Red

```bash
openstack network list
openstack subnet list
openstack router list
openstack port list
openstack floating ip list
openstack security group list
```

### Almacenamiento

```bash
openstack volume list
openstack volume show disco1
openstack volume create --size 10 disco1
openstack volume delete disco1
```

---

## 8. Ejemplos un poco más reales

### Crear red y subred

```bash
openstack network create red-interna

openstack subnet create \
  --network red-interna \
  --subnet-range 10.0.0.0/24 \
  subred-interna
```

### Crear volumen

```bash
openstack volume create --size 20 disco-datos
```

### Crear instancia

```bash
openstack server create \
  --flavor m1.small \
  --image ubuntu \
  --network red-interna \
  --key-name mi-clave \
  vm1
```

### Ver detalles de la instancia

```bash
openstack server show vm1
```

### Crear floating IP y asociarla

```bash
openstack floating ip create public
openstack server add floating ip vm1 203.0.113.50
```

---

## 9. Formatos de salida

Muy útil para scripting y automatización.

```bash
openstack server list -f table
openstack project list -f json
openstack token issue -f yaml
openstack token issue -f value -c user_id
```

Regla rápida:

* `table` → para humanos
* `json` / `yaml` → para scripts
* `value` → para extraer campos concretos

---

## 10. Resumen final

La CLI de OpenStack se entiende muy bien si piensas así:

* **hay objetos**: proyecto, usuario, red, servidor, volumen...
* **hay verbos**: listar, mostrar, crear, borrar, modificar...
* **la sintaxis suele ser uniforme**: `openstack objeto acción`

Ejemplos representativos:

```bash
openstack server list
openstack network create red1
openstack volume show disco1
openstack project delete proyecto-prueba
```

La idea más importante es esta:

> El cliente `openstack` no es una colección caótica de comandos.
> Es una CLI bastante coherente basada en **recursos cloud** y **acciones sobre esos recursos**.
