# Instalación y configuración del cliente OpenStack CLI en Windows

## Objetivo

En este documento vas a aprender a:

- instalar el cliente CLI de OpenStack en Windows
- verificar que funciona correctamente
- configurar el acceso al entorno del curso
- autenticarte contra Keystone
- comprobar que puedes hablar con la plataforma

---

## Requisitos previos

Necesitas:

- un equipo con Windows
- conexión a Internet
- permisos para instalar software
- una cuenta del laboratorio
- acceso al endpoint de Keystone del entorno del curso

---

## Recomendación importante

Para este curso, en Windows vamos a usar:

- **Python oficial**
- **Command Prompt (`cmd.exe`)**
- **pip**
- y opcionalmente un **entorno virtual**

> **Importante:** para este cliente usaremos **cmd.exe**, no PowerShell.

---

## Paso 1. Instalar Python

Descarga e instala Python desde la web oficial:

- https://www.python.org/downloads/

> **Versión recomendada:** Python **3.10** o superior. Mínimo 3.9.

Durante la instalación, marca esta casilla:

- **Add Python to PATH**

Eso es muy importante.

---

## Paso 2. Verificar Python y pip

Abre **Símbolo del sistema** (`cmd.exe`) y ejecuta:

```bat
python --version
pip --version
```

Si ambos comandos responden, Python y pip ya están disponibles.

---

## Paso 3. Crear un entorno virtual

En `cmd.exe`:

```bat
python -m venv %USERPROFILE%\openstack-client
```

Esto crea un entorno virtual en tu perfil de usuario.

---

## Paso 4. Activar el entorno virtual

```bat
%USERPROFILE%\openstack-client\Scripts\activate
```

Si todo va bien, el prompt cambiará y verás algo parecido a esto:

```bat
(openstack-client) C:\Users\TuUsuario>
```

Para **salir** del entorno virtual en cualquier momento:

```bat
deactivate
```

---

## Paso 5. Actualizar pip

```bat
python -m pip install --upgrade pip
```

---

## Paso 6. Instalar OpenStackClient

```bat
pip install python-openstackclient
```

> **Si la instalación falla** con errores de compilación, es posible que necesites instalar
> **Microsoft Visual C++ Build Tools**. Descárgalas desde:
> https://visualstudio.microsoft.com/visual-cpp-build-tools/
>
> Instala el componente **"Desktop development with C++"** y vuelve a intentar.

---

## Paso 7. Verificar la instalación

```bat
openstack --version
```

Si responde con una versión, el cliente ya está instalado correctamente.

---

## Opción rápida sin entorno virtual

Si no quieres usar entorno virtual, puedes instalar el cliente directamente:

```bat
python -m pip install --upgrade pip
pip install python-openstackclient
openstack --version
```

Aun así, para clase se recomienda usar `venv`.

---

## Qué consola debes usar

Usa una de estas opciones:

* **Símbolo del sistema** (`cmd.exe`)
* **Windows Terminal** abriendo un perfil de **Command Prompt**

> No uses PowerShell para este laboratorio.

---

## Configurar el acceso al laboratorio

Tienes dos formas cómodas:

* con un archivo `openrc.cmd`
* con `clouds.yaml`

Durante el curso usaremos primero **`openrc.cmd`**, porque ayuda a entender mejor la autenticación.

---

## Opción A. Configuración con `openrc.cmd`

Recibirás un archivo parecido a este, por ejemplo `alumno1-openrc.cmd`:

```bat
set OS_AUTH_URL=https://keystone.ivanosuna.com/v3
set OS_IDENTITY_API_VERSION=3
set OS_USERNAME=alumno1
set OS_PASSWORD=<Escribe aqui tu password>
set OS_PROJECT_NAME=proyecto-alumno1
set OS_USER_DOMAIN_NAME=dominio-alumno1
set OS_PROJECT_DOMAIN_NAME=dominio-alumno1
```

### Cómo cargarlo

Desde `cmd.exe`, en la carpeta donde esté el archivo:

```bat
call alumno1-openrc.cmd
```

### Cómo comprobar que funciona

```bat
openstack token issue
openstack catalog list
openstack service list
openstack endpoint list
```

---

## Opción B. Configuración con `clouds.yaml`

### Crear la carpeta

```bat
mkdir %USERPROFILE%\.config\openstack
```

### Crear el archivo `%USERPROFILE%\.config\openstack\clouds.yaml`

Ejemplo:

```yaml
clouds:
  curso-openstack:
    region_name: RegionOne
    identity_api_version: 3
    auth:
      auth_url: https://keystone.ivanosuna.com/v3
      username: alumno1
      password: <Escribe aqui tu password>
      project_name: proyecto-alumno1
      user_domain_name: dominio-alumno1
      project_domain_name: dominio-alumno1
```

### Usarlo

```bat
openstack --os-cloud curso-openstack token issue
```

---

## Primeros comandos de comprobación

Una vez instalada la CLI y cargada la configuración, prueba estos comandos:

```bat
openstack token issue
openstack catalog list
openstack service list
openstack endpoint list
```

Si funcionan, ya estás autenticado correctamente y puedes hablar con la plataforma.

---

## Problemas típicos en Windows

### 1. `python` no se reconoce

Posibles causas:

* Python no está en `PATH`

Soluciones:

* reinstalar Python marcando **Add Python to PATH**
* cerrar y abrir de nuevo la consola

---

### 2. `openstack` no se reconoce

Posibles causas:

* no has activado el entorno virtual
* la instalación falló

Soluciones:

* activar el `venv`
* repetir:

```bat
pip install python-openstackclient
```

---

### 3. Estás usando PowerShell

Problema:

* no es la consola recomendada para este laboratorio

Solución:

* usa **cmd.exe**
* o Windows Terminal con perfil **Command Prompt**

---

### 4. El `openrc` no funciona

En Windows debes usar:

* `set`
* no `export`

Y cargar el archivo con:

```bat
call alumno1-openrc.cmd
```

---

### 5. Falla la autenticación

Revisa:

* `OS_AUTH_URL`
* usuario
* contraseña
* proyecto
* dominio

---

### 6. Error de certificado SSL

Si ves un error como `SSL: CERTIFICATE_VERIFY_FAILED`, el endpoint puede estar usando un certificado autofirmado.

Solución rápida (solo para laboratorio):

```bat
openstack --insecure token issue
```

O configurar la variable de entorno:

```bat
set OS_INSECURE=true
```

> En producción se configuraría el certificado CA correcto.

---

### 7. Al cerrar la consola se pierde todo

Cada vez que abres una consola nueva necesitas:

1. **Activar el entorno virtual:**

```bat
%USERPROFILE%\openstack-client\Scripts\activate
```

2. **Cargar de nuevo tu openrc:**

```bat
call alumno1-openrc.cmd
```

Estas variables solo viven mientras la consola esté abierta.

---

## Resumen rápido

### Instalación mínima

```bat
python -m venv %USERPROFILE%\openstack-client
%USERPROFILE%\openstack-client\Scripts\activate
python -m pip install --upgrade pip
pip install python-openstackclient
openstack --version
```

### Cargar acceso con `openrc.cmd`

```bat
call alumno1-openrc.cmd
openstack token issue
```

### O usar `clouds.yaml`

```bat
openstack --os-cloud curso-openstack token issue
```

---

## Qué debes entender al terminar

Debes ser capaz de:

* instalar el cliente CLI
* abrir la consola correcta
* cargar tu configuración de acceso
* autenticarte contra el laboratorio
* listar catálogo, servicios y endpoints
