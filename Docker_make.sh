#!/usr/bin/bash

DOCKER_IMAGE_NAME=gnucash
DOCKER_RESET=0

SCRIPTPATH=.
SCRIPTPATH=$(dirname $(readlink -f $0))
#SCRIPTPATH=${SCRIPTPATH%/}

if [ "$DOCKER_RESET" == "1" ] || [ "$(docker image ls ${DOCKER_IMAGE_NAME} | grep ${DOCKER_IMAGE_NAME})" == "" ]
then
  echo "Deleting existing container '${DOCKER_IMAGE_NAME}'..."
  docker stop ${DOCKER_IMAGE_NAME}
  docker rm ${DOCKER_IMAGE_NAME}

  echo "Deleting existing image '${DOCKER_IMAGE_NAME}'..."
  docker image rm ${DOCKER_IMAGE_NAME}
  
  echo "Building image '${DOCKER_IMAGE_NAME}'..."
  docker build -t ${DOCKER_IMAGE_NAME} .
  
  echo "Running '${DOCKER_IMAGE_NAME}' image into '${DOCKER_IMAGE_NAME}' container..."
  docker run --volume ${SCRIPTPATH}:/${DOCKER_IMAGE_NAME} --name ${DOCKER_IMAGE_NAME} ${DOCKER_IMAGE_NAME} /bin/bash /${DOCKER_IMAGE_NAME}/make_appimage.sh
else
  echo "Running existing ${DOCKER_IMAGE_NAME} container..."
  docker start --attach ${DOCKER_IMAGE_NAME}
fi
