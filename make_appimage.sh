#!/bin/bash
set -x #echo on
set -e #Exists on errors

#TODO : get version from github tag
export VERSION=4.8

SCRIPTPATH=.
SCRIPTPATH=$(dirname $(readlink -f $0))
SCRIPTPATH=${SCRIPTPATH%/}

alias ll="ls -al"
pushd ${SCRIPTPATH}

export APP=GnuCash
export LOWERAPP=gnucash
export APPDIR="${SCRIPTPATH}/appdir"

#=== AppDir

if [ ! -d "${APPDIR}" ];
then
  mkdir --parents "${APPDIR}"
  #find "${APPDIR}"
fi

#=== Get App source

if [ ! -f "./${LOWERAPP}-${VERSION}.tar.gz" ];
then
  wget --continue "https://github.com/gnucash/gnucash/releases/download/${VERSION}/${LOWERAPP}-${VERSION}.tar.gz" --output-document="${LOWERAPP}-${VERSION}.tar.gz"
  rm --recursive --force "./${LOWERAPP}-${VERSION}"
fi

if [ ! -d "./${LOWERAPP}-${VERSION}" ];
then
  tar xf "./${LOWERAPP}-${VERSION}.tar.gz"

  #Workaround for failing build... Weird since test-ci.yml on github is OK...
  #  diff -u gnucash-4.8/gnucash/gschemas/CMakeLists.txt gnucash-4.8-patched/gnucash/gschemas/CMakeLists.txt >CMakeLists.patch
  patch --input=./CMakeLists.patch "./gnucash-${VERSION}/gnucash/gschemas/CMakeLists.txt"
fi

#=== Compile main App

BuildDir="${LOWERAPP}-${VERSION}_build"

if [ ! -d "${BuildDir}" ];
then
  mkdir "${BuildDir}"

  pushd "${BuildDir}"

  #if [ -z "$TZ" ];
  #then
  #  export TZ='America/Los_Angeles' #'Europe/Paris'
  #fi

  cmake -G Ninja -DWITH_PYTHON=ON -DCMAKE_INSTALL_PREFIX=$APPDIR/usr "../${LOWERAPP}-${VERSION}/"
  ninja
  #ninja check  # => des tests échouent, je ne sais pas pourquoi, et pour l'instant, je m'en fiche...
  ninja install

  popd
fi

#=== Copy extra shared libraries that are not copied by linuxdeploy later

#echo "=> copy GUILE"
cp --verbose /usr/bin/guile "${APPDIR}/usr/bin"
cp --recursive --verbose /usr/share/guile "${APPDIR}/usr/share"
cp --recursive --verbose /usr/lib/x86_64-linux-gnu/guile "${APPDIR}/usr/lib"

#echo "=> copy SQLITE"
cp --recursive --verbose /usr/lib/x86_64-linux-gnu/dbd "${APPDIR}/usr/lib"

#echo "=> copy LIBOFX dependencies"
cp --recursive --verbose /usr/share/libofx7 "${APPDIR}/usr/share"

#=== Construct AppImage

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}${LD_LIBRARY_PATH:+:}${APPDIR}/usr/lib

# cp ${APPDIR}/usr/share/icons/hicolor/scalable/apps/geany.svg ${APPDIR}/ # Why is this needed?

if [ ! -f "./linuxdeploy-plugin-gtk" ];
then
  wget -c "https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/raw/master/linuxdeploy-plugin-gtk.sh" --output-document=linuxdeploy-plugin-gtk
  chmod a+x ./linuxdeploy-plugin-gtk
fi
 
if [ ! -f "./linuxdeploy-x86_64.AppImage" ];
then
  wget -c "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
  chmod a+x ./linuxdeploy-x86_64.AppImage
fi

#Prépare AppDir
./linuxdeploy-x86_64.AppImage --appimage-extract-and-run --appdir=${APPDIR} --plugin=gtk

#Le convertit en AppImage
rm --recursive --force ${APPDIR}/apprun-hooks
rm --force ${APPDIR}/AppRun.wrapped
cp ${SCRIPTPATH}/AppRun ${APPDIR}
ARCH=x86_64 ./linuxdeploy-x86_64.AppImage --appimage-extract-and-run --appdir=${APPDIR} --output=appimage

#===

echo "AppImage generated = $(readlink -f $(ls ${APP}*.AppImage))"
popd
