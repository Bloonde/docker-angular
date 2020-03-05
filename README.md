# Docker Angular

Create .env

    $ cd docker-angular
    $ cp .env.example .env

Edit .env (Docker-angular)

    -PROJECT_NAME=project_name
    -IMAGE_NAME=angular // Not edited

Start:

    $ cd docker-angular
    $ ./start.sh
    
Run container and composer project

    $ docker exec -it project_name bash
    $ su docker
    
