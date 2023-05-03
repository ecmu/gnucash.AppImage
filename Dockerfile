#https://hub.docker.com/_/ubuntu/
# => 20.04 LTS
#FROM ubuntu:focal
FROM ubuntu:22.04

#=== Install required packages for building App :

#Note:
# appstream is used by AppImageTool
RUN apt-get update \
&& apt-get install --yes apt-utils \
&& DEBIAN_FRONTEND=noninteractive apt-get install --yes sudo wget locales appstream build-essential cmake pkg-config \
&& useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo

#For convenience, allow fake user to use sudo without password.
RUN echo "docker ALL = NOPASSWD:ALL" >/etc/sudoers.d/docker
#Always log in with this fake user
USER docker
