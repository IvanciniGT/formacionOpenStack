
export OS_AUTH_URL=https://keystone.ivanosuna.com/v3
export OS_IDENTITY_API_VERSION=3
export OS_USERNAME=profesor
export OS_PASSWORD='Pa$$w0rd'
export OS_USER_DOMAIN_NAME=dominio-profesor 
# Es el dominio donde existe ese usuario.
# Puedo tener usuarios con el mismo nombre en distintos dominios,
# por eso es importante indicar el dominio.

# CONTEXTO del token:

export OS_PROJECT_NAME=proyecto-profesor
export OS_PROJECT_DOMAIN_NAME=dominio-profesor
unset  OS_DOMAIN_NAME

#KeyStone, si no pongo contexto, trabaja por defecto con mi dominio.
