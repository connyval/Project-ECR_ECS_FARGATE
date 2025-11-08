## Website deployed in Docker with AWS ECS-Fargate Service and image Register in ECR  

### Objetive:
Se despliega un sitio web con Docker, su imagen de registra en Docker Hub para desplegar y configurar a travez de AWS, servicio administrado ECS - Fargate. 

### Architecture:

- Static Website (html) 
- Dockerfile
- AWS ECR Registry
- Service AWS  ECS - Fargate services
- OrbStack console (Docker Engine)
- Developer Tool as VSCode IDE


### Technical Implementation:

*** 1.  Se crea archivo INDEX.HTML,  DOCKERFILE y la IMAGEN ***

- Se crea una carpeta para crer el proyecto en VSCODE
- Se crea un archivo index.html personalizado
- Se Crea archivo Dockerfile, creo comentarios 
- En maquina local, activo OrbStack como el Engine o motor de Docker
- En VScode,  se abre una terminal para trabajar desde allí los comandos de docker 
- Ubicarse en la carpeta del proyecto, (confirmar con **pwd**)

Index.html
```
<!DOCTYPE html>
<html lang="es-CO">
<head>
  <title>Sitio Web con Docker, registrado a ECR y desplegado en ECS</title>
</head>
<body>
  <div>
      <h1>Version 2.0</h1>
      <h1>¡Bienvenido a mi sitio web en Docker en ECR-ECS!</h1>
      <h2>Laboratorio ECR-ECS Connyval</h2>
  </div>
</body>
</html>
```
dockerfie
```
# Se basa en dockefile del labortorio ECR-ECS
# Usar la imagen base de nginx para el servidor web
FROM nginx:alpine

# Copiar el archivo index.html (desde la ubicacion de este dir en proyecto) 
# al directorio donde nginx (configuracion x defecto de ngnix),  sirve archivos
COPY ./index.html /usr/share/nginx/html/index.html

# Exponer el puerto 80 para acceder al sitio
EXPOSE 80
```

- Para construir la imagen en base al dockerfile construido. 
  Con comando ***docker build -t IMAGEN (mi-sitio-web)  UBICACION ( . ) ***
 
```
docker build -t mi-sitio-web .   
```
Con éste comando, **crea una nueva imagen a partir de Ngnix** donde incluye el index.html del sitio web y se expone por puerto 80

- Se comprueba creación de imagen, queda peso de 152 MB, aprox
```
docker images
```

- Siguiente comando para **correr el contenedor en base a la imagen creada (mi-sitio-web)**, que expone el contenedor por puerto interno 80 y hacia el host en 8080
```
 docker run -d -p 8080:80 mi-sitio-web
```
Se comprueba con ```docker ps```

- A nivel del ORbStack, también queda mostrándose la imagen

***2. Cargar IMAGEN en repositorio en AWS-ECR de cuenta AWS**

- Mediante **AWS CLI**, configuro las credenciales para a cuenta AWS

- Usando comando ```aws configure```,  se configura ***usuario, accesskey, region (usuario creado previamente en IAM con permisos)**

Ejecuto siguiente comando para conectar **AWS-ECR**
```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin xxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com
```
Como resultado Indica:  **login exists**

- Siguiente comando etiqueta (en local) la imagen con nombre mi-sitio-web-repo:v1.0
```
docker tag mi-sitio-web:latest xxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/mi-sitio-web-repo:v1.0
```
En **AWS_ECR**, se crea un **repositorio privado** llamado mi-sitio-web-repo

Comando para Subir a AWS-ECR en mi cta AWS, se da comando:
```
docker push xxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/mi-sitio-web-repo:v1.0
```

*** 3.Desplegar la imagen en ECS ***

- Crear cluster (fargate): mi-cluster-web con monitoreo

- Crear task definition: mi-task-definition

- Launch type: AWS Fargate

- Operating system/Architecture: Linux/X86_64
- Task size: 0.5 vCPU y 1 GB Memory
- Task role & Task execution role: Default

 **Container details**
 -  Name: mi-sitio-web
 -  Imagen URI: Del ECR, se selecciona la Imagen cargada (imagen en ECR) o se toma la URI
 -  puerto: 80

- Se crea la **task definition**
- Se va a **cluster** a crear un **servicio**, que queda con la revision 1 y en base a la task definition
- Se escoge tipo de **lanzamiento FARGATE**

***Crear y ejecutar el servicio:**
 -  Ir a services y configurarlo con Fargate: mi-sitio-web-service
 -  Desired task: 1
 -  Configurar en una subred publica
 -  Configurar el SG del service: mi-sitio-web-service-sg, http (80) entrada
 -  Activar la IP publica

- Elegir el cluster y la task definition
- Posterior, a nivel de task ya queda creada 

*** 4. Exponer y navegar el sitio web ***

A nivel de la task en networking, aparece la IP publica para navegarla
Se navega a puerto 80 en dir publica y navega el sitio con fargate.
Tener en cuenta el **SecurityGroup** abierto el puerto correspondiente 
Actualizar el service con 2 tareas


*** 5. En caso de ajustes, se crea una nueva versión (REVISION)***

Al  realizar cambios  en el proyecto, es necesario crear la imagen nuevamente y etiquetarla con Version 2 . Para  luego subiría al repositorio ECR, nuevamente 

- Editar el HTML, construir la imagen, etiquetarla y subirla a ECR

- Se vuelve a re-construir la imagen ```docker build -t mi-sitio-web .  ```
- Creo imagen con etiqueta con vr 2
- Subo a ECR la imagen con vr 2

Luego a nivel de TASK DEFINITION para cambiar en producción, se crea una nueva version de la task definition, actualizando la version de la imagen vr 2 y se guarda 

- Se crea una nueva revision de la task 

- Se va a cluster y se actualiza el service,  para forzar el deployment y seleccionando el task definition, revision 2

Así mismo, se debe cambiar en  2 replicas, se verifica los cambios  en la  en ficha task

Donde esta aprovisionando, 2 contenedores basado en el ultimo task definition, revision 2.  El servicio estará actualizando y reemplazando los contenedores con vr anterior, gradualmente.

Quedando,  al final 2 contenedores (según capacidad deseada) y con la ultima version actualizada

- Finalmente, se verifica, navegando la dirección publica nueva, para comprobar la actualización de los 2 contenedores. Quedando activa la solución.

Posteriormente, al borrar el cluster, borrara todos los servicios y configuraciones realizadas.  

### Technical Desing:

![Technical Desing](https://ocvpprofessional.cloud/wp-content/uploads/2025/11/WP-docker-Orbstack-AwsQ.png)

Gracias a la guia de: https://github.com/Jona-Baez/Sitio-web-con-Docker-ECR-y-ECS/blob/main/Dockerfile