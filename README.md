# Container con aplicación Angular

Instrucciones para crear un contenedor con una aplicación Angular construida con CLI conectada a un directorio de desarrollo en nuestra máquina con hot-reloading.

Requisitos:

- [Docker](#Docker)

- [Angular CLI](#Angular-CLI)



## Docker

### Linux (Debian/Ubuntu)

1. Instalar [Docker](https://www.digitalocean.com/community/tutorials/como-instalar-y-usar-docker-en-ubuntu-18-04-1-es) desde Terminal.
2. Verificar instalación ejecutando `docker run hello-world` en Terminal.

[Documentación oficial](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

### Mac

1. Descargar e instalar [Docker Desktop](https://hub.docker.com/?overlay=onboarding).
2. Verificar instalación ejecutando `docker run hello-world` en Terminal.

[Documentación oficial](https://docs.docker.com/docker-for-mac/install/)

### Windows (Home)

Windows Home no viene con hypervisor nativo, vamos a necesitar VirtualBox para poder usar Docker.

1. Asegurarse de que Windows es 64-bit y que la virtualización está activada en la BIOS.
2. Descargar e instalar la última versión de [Docker Toolbox](https://github.com/docker/toolbox/releases), que contiene Docker QuickStart Terminal, Kitematic y Oracle VM VirtualBox.
3. Verificar instalación abriendo Docker QuickStart Terminal y ejecutando `docker run hello-world`. El terminal de Docker usa Bash, **no usar CMD nativo de Windows**, que no soporta comandos estándar de Unix necesarios para trabajar con Docker.

[Documentación oficial](https://docs.docker.com/toolbox/toolbox_install_windows/)

### Windows (Pro/Enterprise)

1. Asegurarse de que [Hyper-V y Windows Containers](https://docs.microsoft.com/es-es/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v) están activados.
2. Descargar e instalar [Docker Desktop](https://hub.docker.com/?overlay=onboarding).
3. Verificar instalación ejecutando `docker run hello-world` en PowerShell.

[Documentación oficial](https://docs.docker.com/docker-for-windows/install/)



## Angular CLI

1. Se necesita Node y npm (atención a las versiones y su compatibilidad con CLI).
2. Instalar CLI globalmente con: `npm install -g @angular/cli`
3. Crear proyecto en nuestro directorio de desarrollo: `ng new angular-app`
4. Acceder al proyecto: `cd angular-app`

[Documentación oficial](https://angular.io/cli)



## Container de desarrollo

Desde raíz del proyecto (`pwd`):

1. Añadir un archivo Dockerfile (sin extensión y con D mayúscula) con el editor que queráis (ejemplo `nano Dockerfile`) con el siguiente contenido:

   ```
    # imagen base con Node
    FROM node:12.2.0
   
    # anstalar chrome para protractor tests
    RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
    RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
    RUN apt-get update && apt-get install -yq google-chrome-stable
   
    # directorio de trabajo en el contenedor
    WORKDIR /app
   
    # añadir `/app/node_modules/.bin` a $PATH
    ENV PATH /app/node_modules/.bin:$PATH
   
    # copiar configuración e instalar dependencias
    COPY package.json /app/package.json
    RUN npm install
    RUN npm install -g @angular/cli
   
    # copiar directorio actual en directorio de trabajo
    COPY . /app
   
    # ejecutar servidor de desarrollo
    CMD ng serve --host 0.0.0.0
   ```


2. Añadir un archivo .dockerignore para que Docker ignore los directorios git y node_modules y agilizar el proceso posterior de levantar el contenedor:

   ```
   node_modules
   .git
   .gitignore
   ```

3. Construir la imagen: `docker build -t angular-app:dev .`

   [^1]: Si al instalar el CLI entra en un bucle, añadir el flag `--unsafe` a la linea `RUN npm install -g @angular/cli` ([issue](https://github.com/angular/angular-cli/issues/7389)).
   [^2]: Va a tardar porque la imagen va a pesar alrededor de 1.8GB.

4. Verificar que la imagen existe: `docker images` (en el listado debe aparecer una imagen angular-app con el tag dev).

5. Crear un contenedor a partir de la imagen con las siguientes opciones:

   - Dos volúmenes: uno en `/app` unido al directorio raíz del proyecto (${PWD}) y otro anónimo `/app/node_modules` que hace que la aplicación tire de node_modules de dentro del contenedor que ha construido en la imagen y no lo sobreescriba de nuevo durante el run.
   - Dos puertos: 4200 para interconexión con otros contenedores en la misma red enlazado a 4201 como host para acceder desde nuestra máquina.
   - `—rm`elimina el contenedor y los volúmenes cuando se para el contenedor.
   - `:dev` es un flag para identificar que el contenedor está en modo desarrollo en el listado de `docker ps`, estamos haciendo `serve`, no `build`.
   - `angular-app:dev` es la imagen con la que vamos a levantar el contenedor.

   ```
   docker run -v ${PWD}:/app -v /app/node_modules -p 8081:8080 --rm angular-app:dev
   ```

6. Verificar abriendo [http://localhost:4201](http://localhost:4201) en el navegador y que con `docker ps` aparece un contenedor levantado con la imagen que hemos creado antes `angular-app:dev`.

7. Para verificar el hot-reloading modifica un componente en la aplicación (`src/app/app.component.html` por ejemplo), el navegador debe recargarse con los cambios.

8. El proceso `run` se queda ejecutandose en la terminal (podemos añadir el flag -d para que se ejecute en background pero no recibes feedback) se puede parar con `ctrl+c` o abrir otro terminal y ejecutar `docker stop {container id}`


### Testing (opcional)

Para realizar tests unitarios, una vez levantado el contenedor, actualizar archivos de configuración de Karma y Protractor.

`src/karma.conf.js`:

```javascript
module.exports = function (config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine', '@angular-devkit/build-angular'],
    plugins: [
      require('karma-jasmine'),
      require('karma-chrome-launcher'),
      require('karma-jasmine-html-reporter'),
      require('karma-coverage-istanbul-reporter'),
      require('@angular-devkit/build-angular/plugins/karma')
    ],
    client: {
      clearContext: false
    },
    coverageIstanbulReporter: {
      dir: require('path').join(__dirname, '../coverage/example'),
      reports: ['html', 'lcovonly', 'text-summary'],
      fixWebpackSourcePaths: true
    },
    reporters: ['progress', 'kjhtml'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: true,
    // updated
    browsers: ['ChromeHeadless'],
    // new
    customLaunchers: {
      'ChromeHeadless': {
        base: 'Chrome',
        flags: [
          '--no-sandbox',
          '--headless',
          '--disable-gpu',
          '--remote-debugging-port=9222'
        ]
      }
    },
    singleRun: false,
    restartOnFileChange: true
  });
};
```

`E2e/protractor.conf.js`:

```javascript
const { SpecReporter } = require('jasmine-spec-reporter');

exports.config = {
  allScriptsTimeout: 11000,
  specs: [
    './src/**/*.e2e-spec.ts'
  ],
  capabilities: {
    'browserName': 'chrome',
    // new
    'chromeOptions': {
      'args': [
        '--no-sandbox',
        '--headless',
        '--window-size=1024,768'
      ]
    }
  },
  directConnect: true,
  baseUrl: 'http://localhost:4200/',
  framework: 'jasmine',
  jasmineNodeOpts: {
    showColors: true,
    defaultTimeoutInterval: 30000,
    print: function() {}
  },
  onPrepare() {
    require('ts-node').register({
      project: require('path').join(__dirname, './tsconfig.e2e.json')
    });
    jasmine.getEnv().addReporter(new SpecReporter({ spec: { displayStacktrace: true } }));
  }
};
```

Para ejecutar los test unitarios y e2e:

```bash
docker exec -it foo ng test --watch=false
docker exec -it foo ng e2e --port 4202
```



### Docker compose

Para no tener que acordarse de las opciones de run podemos usar docker-compose y meter toda la configuración en un archivo `docker-compose.yml` en raíz del proyecto:

```yaml
version: '3'

services:

  angular-app:
    container_name: angular-app
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - '.:/app'
      - '/app/node_modules'
    ports:
      - '4201:4200'

```

Ahora levantamos el contenedor con: `docker-compose up -d`. 

Hay que tener en cuenta que si usamos docker-compose va a crear la imagen a partir del Dockerfile, no necesitamos ejecutar `build` primero, y luego va a ejecutar `run` con las opciones de volúmenes y puertos igual que con el comando `run`.

Con `docker-compose` podemos añadir más servicios (contenedores) como bases de datos, servidor, app para backoffice, etc. e interconectarlos.

Para parar el contendor: `docker-compose stop`



## Aplicación prexistente

Para crear un contenedor desde una aplicación existente se sigue las mismas instrucciones pero adaptando las opciones de versiones a las de la aplicación (CLI, imagen base de Node, etc.), al fin y al cabo en este ejemplo también hemos creado el contenedor después de crear la aplicación.
