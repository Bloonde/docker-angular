# imagen base con Node
FROM node:12.2.0

# anstalar chrome para protractor tests
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
RUN apt-get update && apt-get install -yq google-chrome-stable

RUN useradd -rm -d /home/docker -s /bin/bash -g root -G sudo -u 1000 docker

 # directorio de trabajo en el contenedor
WORKDIR /app

 # añadir `/app/node_modules/.bin` a $PATH
ENV PATH /app/node_modules/.bin:$PATH

ADD entrypoint.sh /root/entrypoint.sh
RUN chmod 777 /root/entrypoint.sh
ENTRYPOINT /root/entrypoint.sh
