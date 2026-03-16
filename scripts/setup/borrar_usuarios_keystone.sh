#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Script de limpieza — elimina todo lo creado por
# crear_usuarios_keystone.sh
#
# Borra para cada usuario (alumno1..alumno15 + profesor):
#   - roles asignados en dominio y proyecto
#   - el usuario
#   - el proyecto
#   - el dominio (desactivándolo primero)
# Al final:
#   - borra la carpeta salida-usuarios-keystone/
#
# Requisitos:
#   - tener cargado un contexto admin válido
#   - disponer del comando "openstack"
#
# Uso:
#   source admin-openrc.sh
#   ./borrar_usuarios_keystone.sh
# =========================================================

OUTDIR="salida-usuarios-keystone"

echo "=========================================="
echo "  ATENCIÓN: Esto va a borrar todos los"
echo "  dominios, usuarios y proyectos del curso."
echo "=========================================="
read -rp "¿Estás seguro? (escribe SI para continuar): " CONFIRMACION
if [[ "${CONFIRMACION}" != "SI" ]]; then
  echo "Cancelado."
  exit 0
fi

borrar_usuario_con_dominio() {
  local usuario="$1"
  local dominio="dominio-${usuario}"
  local proyecto="proyecto-${usuario}"

  echo "==> Borrando ${usuario} / ${dominio} / ${proyecto}"

  # Quitar rol admin del dominio
  openstack role remove \
    --user "${usuario}" \
    --user-domain "${dominio}" \
    --domain "${dominio}" \
    admin 2>/dev/null || true

  # Quitar rol admin del proyecto
  openstack role remove \
    --user "${usuario}" \
    --user-domain "${dominio}" \
    --project "${proyecto}" \
    --project-domain "${dominio}" \
    admin 2>/dev/null || true

  # Eliminar usuario
  if openstack user show "${usuario}" --domain "${dominio}" >/dev/null 2>&1; then
    openstack user delete "${usuario}" --domain "${dominio}"
    echo "    Usuario ${usuario} eliminado"
  else
    echo "    Usuario ${usuario} no existe, saltando"
  fi

  # Eliminar proyecto
  if openstack project show "${proyecto}" --domain "${dominio}" >/dev/null 2>&1; then
    openstack project delete "${proyecto}" --domain "${dominio}"
    echo "    Proyecto ${proyecto} eliminado"
  else
    echo "    Proyecto ${proyecto} no existe, saltando"
  fi

  # Desactivar y eliminar dominio
  if openstack domain show "${dominio}" >/dev/null 2>&1; then
    openstack domain set --disable "${dominio}"
    openstack domain delete "${dominio}"
    echo "    Dominio ${dominio} eliminado"
  else
    echo "    Dominio ${dominio} no existe, saltando"
  fi
}

# Borrar alumnos
for i in $(seq 1 15); do
  borrar_usuario_con_dominio "alumno${i}"
done

# Borrar profesor
borrar_usuario_con_dominio "profesor"

# Borrar carpeta de salida
if [[ -d "${OUTDIR}" ]]; then
  rm -rf "${OUTDIR}"
  echo ""
  echo "Carpeta ${OUTDIR}/ eliminada."
fi

echo
echo "=============================================="
echo "Limpieza terminada."
echo "=============================================="
