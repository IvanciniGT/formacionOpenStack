#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Script de preparación de usuarios y proyectos para el curso
# Crea para cada usuario (alumno1..alumno15 + profesor):
#   - un dominio propio (dominio-alumnoX)
#   - un proyecto dentro de ese dominio (proyecto-alumnoX)
#   - el usuario dentro de ese dominio
#   - rol admin en el DOMINIO (admin de todo su dominio)
#   - genera openrc Linux/macOS, openrc.cmd, clouds.yaml
#   - genera un CSV con credenciales
#
# Así cada alumno es admin de su propio dominio y puede
# crear usuarios, proyectos y roles sin colisionar con
# otros alumnos.
#
# Requisitos:
#   - tener cargado un contexto admin válido
#   - disponer del comando "openstack"
#
# Uso:
#   source admin-openrc.sh
#   ./crear_usuarios_keystone.sh
# =========================================================

OS_AUTH_URL_DEFAULT="${OS_AUTH_URL:-https://keystone.ivanosuna.com/v3}"
PASSWORD_PLACEHOLDER='<Escribe aqui tu password>'
OUTDIR="salida-usuarios-keystone"
CREDCSV="${OUTDIR}/credenciales.csv"

# Pedir contraseña por consola (no se muestra en pantalla)
read -rsp "Introduce la contraseña para los usuarios del curso: " PASSWORD
echo
if [[ -z "${PASSWORD}" ]]; then
  echo "Error: la contraseña no puede estar vacía."
  exit 1
fi

mkdir -p "${OUTDIR}"

echo "usuario,dominio,proyecto,password" > "${CREDCSV}"

crear_usuario_con_dominio() {
  local usuario="$1"
  local dominio="dominio-${usuario}"
  local proyecto="proyecto-${usuario}"

  echo "==> Procesando ${usuario} / ${dominio} / ${proyecto}"

  # Crear dominio si no existe
  if ! openstack domain show "${dominio}" >/dev/null 2>&1; then
    openstack domain create \
      --description "Dominio personal de ${usuario}" \
      "${dominio}"
  fi

  # Crear proyecto dentro del dominio
  if ! openstack project show "${proyecto}" --domain "${dominio}" >/dev/null 2>&1; then
    openstack project create \
      --domain "${dominio}" \
      --description "Proyecto principal de ${usuario}" \
      "${proyecto}"
  fi

  # Crear usuario dentro del dominio
  if ! openstack user show "${usuario}" --domain "${dominio}" >/dev/null 2>&1; then
    openstack user create \
      --domain "${dominio}" \
      --password "${PASSWORD}" \
      "${usuario}"
  fi

  # Asignar admin en el DOMINIO (admin de todo su dominio)
  openstack role add \
    --user "${usuario}" \
    --user-domain "${dominio}" \
    --domain "${dominio}" \
    admin || true

  # También asignar admin en su proyecto (para que el token tenga scope de proyecto)
  openstack role add \
    --user "${usuario}" \
    --user-domain "${dominio}" \
    --project "${proyecto}" \
    --project-domain "${dominio}" \
    admin || true

  # CSV de credenciales
  echo "${usuario},${dominio},${proyecto},${PASSWORD}" >> "${CREDCSV}"

  # Carpeta por usuario
  local userdir="${OUTDIR}/${usuario}"
  mkdir -p "${userdir}"

  # openrc Linux/macOS
  cat > "${userdir}/${usuario}-openrc.sh" <<EOF
export OS_AUTH_URL="${OS_AUTH_URL_DEFAULT}"
export OS_IDENTITY_API_VERSION=3
export OS_USERNAME="${usuario}"
export OS_PASSWORD='${PASSWORD_PLACEHOLDER}'
export OS_PROJECT_NAME="${proyecto}"
export OS_USER_DOMAIN_NAME="${dominio}"
export OS_PROJECT_DOMAIN_NAME="${dominio}"
EOF

  # openrc Windows cmd
  cat > "${userdir}/${usuario}-openrc.cmd" <<EOF
set OS_AUTH_URL=${OS_AUTH_URL_DEFAULT}
set OS_IDENTITY_API_VERSION=3
set OS_USERNAME=${usuario}
set OS_PASSWORD=${PASSWORD_PLACEHOLDER}
set OS_PROJECT_NAME=${proyecto}
set OS_USER_DOMAIN_NAME=${dominio}
set OS_PROJECT_DOMAIN_NAME=${dominio}
EOF

  # clouds.yaml
  cat > "${userdir}/clouds.yaml" <<EOF
clouds:
  curso-openstack:
    region_name: RegionOne
    identity_api_version: 3
    auth:
      auth_url: ${OS_AUTH_URL_DEFAULT}
      username: ${usuario}
      password: ${PASSWORD_PLACEHOLDER}
      project_name: ${proyecto}
      user_domain_name: ${dominio}
      project_domain_name: ${dominio}
EOF
}

# Crear alumnos
for i in $(seq 1 15); do
  crear_usuario_con_dominio "alumno${i}"
done

# Crear profesor
crear_usuario_con_dominio "profesor"

echo
echo "=============================================="
echo "Preparación terminada."
echo "Salida generada en: ${OUTDIR}"
echo "CSV de credenciales: ${CREDCSV}"
echo "=============================================="
