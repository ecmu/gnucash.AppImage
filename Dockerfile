#https://hub.docker.com/_/ubuntu/
FROM ubuntu:22.04

#=== Install required packages for building App :

#Note:
# appstream is used by AppImageTool
RUN apt-get update \
&& apt-get install --yes apt-utils \
&& DEBIAN_FRONTEND=noninteractive apt-get install --yes sudo wget locales build-essential cmake pkg-config appstream \
&& useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo

#For convenience, allow fake user to use sudo without password.
RUN echo "docker ALL = NOPASSWD:ALL" >/etc/sudoers.d/docker
#Always log in with this fake user
USER docker
