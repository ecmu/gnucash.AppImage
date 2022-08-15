#!/usr/bin/env bash
#set -x #echo on
#set -e #Exists on errors

DOCKER_IMAGE_NAME=gnucash
DOCKER_RESET=0

SCRIPTPATH=$(cd $(dirname "$BASH_SOURCE") && pwd)
pushd "$SCRIPTPATH"

if [ "$DOCKER_RESET" == "1" ] || [ "$(docker image ls ${DOCKER_IMAGE_NAME} | grep ${DOCKER_IMAGE_NAME})" == "" ]
then
  echo "Deleting existing container '${DOCKER_IMAGE_NAME}'..."
  docker stop ${DOCKER_IMAGE_NAME}
  docker rm ${DOCKER_IMAGE_NAME}

  echo "Deleting existing image '${DOCKER_IMAGE_NAME}'..."
  docker image rm ${DOCKER_IMAGE_NAME}
  
  echo "Building image '${DOCKER_IMAGE_NAME}'..."
  docker build --tag ${DOCKER_IMAGE_NAME} .

  echo "Running '${DOCKER_IMAGE_NAME}' image into '${DOCKER_IMAGE_NAME}' container..."
  docker run --interactive --tty \
  --volume /etc/timezone:/etc/timezone --volume /etc/localtime:/etc/localtime --volume ${SCRIPTPATH}:/${DOCKER_IMAGE_NAME} \
  --env LANG=fr_FR.UTF-8 --env LC_ALL=fr_FR.UTF-8 \
  --name ${DOCKER_IMAGE_NAME} ${DOCKER_IMAGE_NAME} \
  /usr/bin/bash /${DOCKER_IMAGE_NAME}/make_appimage.sh
else
  echo "Running existing ${DOCKER_IMAGE_NAME} container..."
  docker start --attach ${DOCKER_IMAGE_NAME}
fi

popd
