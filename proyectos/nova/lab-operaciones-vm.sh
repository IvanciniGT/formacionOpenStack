#!/bin/bash
# ==============================================================
# LAB — Operaciones sobre una VM con Nova
# ==============================================================
# Ajusta esta variable al nombre de tu VM antes de ejecutar
VM="profesor-vm-nginx"

# Ver el estado actual de la VM
openstack server show "$VM"

# Ver en qué hipervisor/host está corriendo
# (requiere permisos de admin; con usuario normal devuelve None)
openstack server show "$VM" -c OS-EXT-SRV-ATTR:host -c OS-EXT-SRV-ATTR:hypervisor_hostname


# --------------------------------------------------------------
# APAGADO Y ENCENDIDO
# --------------------------------------------------------------

# Apagado limpio (equivale a apagar el SO desde dentro)
openstack server stop "$VM"
# → estado: SHUTOFF

# Encender
openstack server start "$VM"
# → estado: ACTIVE


# --------------------------------------------------------------
# REINICIO
# --------------------------------------------------------------

# Soft reboot — envía señal de reinicio al SO (ACPI), más seguro
openstack server reboot "$VM"
# → pasa por REBOOT → vuelve a ACTIVE

# Hard reboot — corte de corriente y arranque, equivale a pulsar reset
openstack server reboot --hard "$VM"
# → pasa por HARD_REBOOT → vuelve a ACTIVE

# Ver eventos del servidor (historial de todas las operaciones)
openstack server event list "$VM"


# --------------------------------------------------------------
# PAUSA / SUSPENSIÓN
# --------------------------------------------------------------

# Pause — congela la CPU en el hipervisor; la RAM sigue ocupada
openstack server pause "$VM"
# → estado: PAUSED
openstack server unpause "$VM"
# → estado: ACTIVE

# Suspend — guarda el estado en disco y libera CPU/RAM del hipervisor
openstack server suspend "$VM"
# → estado: SUSPENDED
openstack server resume "$VM"
# → estado: ACTIVE


# --------------------------------------------------------------
# RESIZE (cambio de sabor)
# --------------------------------------------------------------

# Ver sabores disponibles
openstack flavor list

# Lanzar el resize (la VM se reinicia con el nuevo sabor)
openstack server resize --flavor m1.small "$VM"
# → pasa por RESIZE → llega a VERIFY_RESIZE

# Confirmar el resize
# IMPORTANTE: si no confirmas, Nova lo revierte automáticamente pasado un tiempo
openstack server resize confirm "$VM"
# → estado: ACTIVE con el nuevo sabor

# Si algo fue mal antes de confirmar, revertir al sabor original
# openstack server resize revert "$VM"


# --------------------------------------------------------------
# LIVE MIGRATION (migración en caliente)
#
# REQUISITOS:
#   - Permisos de admin (el rol de operador/usuario normal da 403)
#   - Al menos 2 nodos de cómputo en el entorno
#   - Almacenamiento compartido (Ceph, NFS...) para live migration estándar
#
# --------------------------------------------------------------

# Ver los nodos de cómputo disponibles (solo admin)
openstack compute service list --service nova-compute

# Ver en qué nodo está la VM actualmente (solo admin)
openstack server show "$VM" -c OS-EXT-SRV-ATTR:host

# Live migration a cualquier host que elija el scheduler
openstack server migrate --live-migration "$VM"

# Live migration a un host concreto
openstack server migrate --live-migration --host worker4 "$VM"

# Live migration sin almacenamiento compartido (copia el disco entre hosts)
openstack server migrate --live-migration --block-migration "$VM"

# Seguir el progreso (el host cambia cuando termina)
openstack server show "$VM" -c status -c OS-EXT-SRV-ATTR:host

# Ver historial de migraciones de la VM
openstack server migration list --server "$VM"


# --------------------------------------------------------------
# COLD MIGRATION
# La VM se para, se mueve al otro nodo y vuelve a arrancar.
# No requiere almacenamiento compartido ni SSH entre hipervisores.
# Hay breve downtime (~15-30s).
# --------------------------------------------------------------

# Lanzar la cold migration (el scheduler elige el nodo destino)
openstack server migrate "$VM"
# → pasa por RESIZE mientras se mueve

# O a un nodo concreto
openstack server migrate --host worker4 "$VM"

# Esperar a VERIFY_RESIZE y confirmar (igual que un resize)
openstack server resize confirm "$VM"
# → estado: ACTIVE en el nuevo nodo
