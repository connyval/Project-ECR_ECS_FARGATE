# Se basa en dockefile del labortorio ECR-ECS
# Usar la imagen base de nginx para el servidor web
FROM nginx:alpine

# Copiar el archivo index.html (desde la ubicacion de este dir en proyecto) 
# al directorio donde nginx (configuracion x defecto de ngnix),  sirve archivos
COPY ./index.html /usr/share/nginx/html/index.html

# Exponer el puerto 80 para acceder al sitio
EXPOSE 80