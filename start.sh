#!/bin/bash
IMAGE="$(cat .env | grep IMAGE_NAME | cut -d "=" -f2)"

if [[ "$(docker images -q $IMAGE 2>/dev/null)" == "" ]]; then
  docker build -t $IMAGE .
fi

docker-compose up
