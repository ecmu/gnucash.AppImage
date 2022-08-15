#https://hub.docker.com/_/ubuntu/
# => 18.04 LTS
#FROM ubuntu:bionic
# => 20.04 LTS
FROM ubuntu:focal

#=== Install required packages for building App :

#Note:
# appstream is used by AppImageTool
RUN apt-get update \
&& apt-get install --yes apt-utils \
&& DEBIAN_FRONTEND=noninteractive apt-get install --yes wget locales appstream build-essential cmake pkg-config
