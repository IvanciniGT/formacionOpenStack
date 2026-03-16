# Administración OpenStack (40 horas)

---

## 1. Perfil del Asistente

Este curso está dirigido a administradores de sistemas, técnicos de infraestructura, desarrolladores, personal de DevOps y profesionales de TI que busquen aprender a administrar y operar OpenStack.

### Requisitos previos

- Experiencia sólida en la línea de comandos de Linux.
- Conocimientos fundamentales de redes (TCP/IP).
- Comprensión básica de virtualización.

---

## 2. Objetivos del Curso

Al finalizar este curso, los asistentes serán capaces de:

- Comprender la arquitectura y los componentes clave de OpenStack.
- Realizar tareas administrativas diarias a través de la CLI y el panel de control Horizon.
- Gestionar usuarios, proyectos, recursos de cómputo, redes y almacenamiento.
- Automatizar el despliegue de recursos básicos con plantillas de orquestación.
- Diagnosticar y resolver problemas comunes en los servicios principales de OpenStack.

---

## Temario del Curso

### Módulo 1: Introducción y Arquitectura de OpenStack (5 horas)

| | |
|---|---|
| **Objetivo** | Entender qué es OpenStack y cómo se estructuran sus servicios. |
| **Contenidos** | Conceptos Cloud (IaaS), arquitectura de servicios, interacción vía Horizon (GUI) y CLI. |
| **Práctica** | Configuración del entorno de cliente y autenticación inicial. |

---

### Módulo 2: Gestión de Identidad con Keystone (4 horas)

| | |
|---|---|
| **Objetivo** | Administrar el acceso y la seguridad del cloud. |
| **Contenidos** | Gestión de Dominios, Proyectos, Usuarios y Roles. |
| **Práctica** | Creación de proyectos y usuarios, y asignación de roles específicos. |

---

### Módulo 3: Gestión de Imágenes con Glance (3 horas)

| | |
|---|---|
| **Objetivo** | Gestionar el catálogo de imágenes de máquinas virtuales. |
| **Contenidos** | Formatos de imagen, subida y gestión de metadatos de imágenes. |
| **Práctica** | Subir una imagen de un sistema operativo a Glance y definir sus propiedades. |

---

### Módulo 4: Gestión de Cómputo con Nova (7 horas)

| | |
|---|---|
| **Objetivo** | Desplegar y gestionar el ciclo de vida de las máquinas virtuales. |
| **Contenidos** | Sabores (flavors), pares de claves, grupos de seguridad, ciclo de vida de instancias. |
| **Práctica** | Lanzar, redimensionar y eliminar una instancia, asociando clave SSH y reglas de firewall. |

---

### Módulo 5: Redes con Neutron (8 horas)

| | |
|---|---|
| **Objetivo** | Diseñar y administrar topologías de red virtuales complejas. |
| **Contenidos** | Redes, subredes, routers virtuales, IPs flotantes y grupos de seguridad. |
| **Práctica** | Crear una topología de red completa para dar acceso a internet a una instancia. |

---

### Módulo 6: Almacenamiento en Bloque con Cinder (5 horas)

| | |
|---|---|
| **Objetivo** | Proveer almacenamiento persistente a las instancias. |
| **Contenidos** | Gestión de volúmenes, tipos de volúmenes e instantáneas (snapshots). |
| **Práctica** | Crear un volumen, adjuntarlo a una instancia, formatearlo y crear un snapshot. |

---

### Módulo 7: Almacenamiento de Objetos con Swift (2 horas)

| | |
|---|---|
| **Objetivo** | Utilizar el almacenamiento de objetos para datos no estructurados. |
| **Contenidos** | Conceptos de Cuentas, Contenedores y Objetos. |
| **Práctica** | Crear un contenedor y subir/descargar ficheros. |

---

### Módulo 8: Orquestación con Heat (3 horas)

| | |
|---|---|
| **Objetivo** | Automatizar la creación de infraestructura como código. |
| **Contenidos** | Sintaxis de plantillas Heat (HOT), lanzamiento y gestión de "stacks". |
| **Práctica** | Crear una plantilla para desplegar automáticamente una instancia con su red. |

---

### Módulo 9: Resolución de Problemas (Troubleshooting) (3 horas)

| | |
|---|---|
| **Objetivo** | Aprender a diagnosticar y solucionar problemas comunes. |
| **Contenidos** | Metodología de diagnóstico, análisis de logs de servicios, comandos de depuración. |
| **Práctica** | Ejercicios guiados para identificar y resolver fallos en instancias y redes. |

---

## Resumen de horas por módulo

| Módulo | Tema | Horas |
|--------|------|-------|
| 1 | Introducción y Arquitectura | 5 |
| 2 | Keystone (Identidad) | 4 |
| 3 | Glance (Imágenes) | 3 |
| 4 | Nova (Cómputo) | 7 |
| 5 | Neutron (Redes) | 8 |
| 6 | Cinder (Almacenamiento en bloque) | 5 |
| 7 | Swift (Almacenamiento de objetos) | 2 |
| 8 | Heat (Orquestación) | 3 |
| 9 | Troubleshooting | 3 |
| | **Total** | **40** |
