#https://hub.docker.com/_/ubuntu/
# => 18.04 LTS
FROM ubuntu:bionic

#=== Install required packages for building App :

RUN apt-get update

#Note:
#	- wget subversion => for getting sources.
# - patchelf				=> for linuxdeploy-plugin-gtk
# - librsvg2-dev		=> for bundling GTK3 (linuxdeploy-plugin-gtk)
# - <others>				=> for app building (see: https://github.com/Gnucash/gnucash/blob/maint/.github/workflows/ci-tests.yml)
RUN apt-get --reinstall install --yes wget patchelf librsvg2-dev cmake libxslt-dev xsltproc ninja-build libboost-all-dev libgtk-3-dev guile-2.2-dev libgwengui-gtk3-dev libaqbanking-dev libofx-dev libdbi-dev libdbd-sqlite3 libwebkit2gtk-4.0-dev googletest swig language-pack-en language-pack-fr
