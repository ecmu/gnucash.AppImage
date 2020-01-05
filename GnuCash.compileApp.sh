#! /bin/bash

#Global variables set by caller
#APP=Gnucash
#LOWERAPP=${APP,,} 
#APPDIR=$(readlink -f appdir)

#set -x
#set -e

#=== Compile googletest

git clone https://github.com/google/googletest.git
pushd googletest
mkdir mybuild
pushd mybuild
cmake -DBUILD_GMOCK=ON ..       #building gmock builds gtest by default
make                            # build the static libraries
popd
popd

# the following commands will create environment variables which if set and installed shared or static libraries are not detected will allow CMake to locate the sources and compile them into the prject build.
# These environment variables can be made permanent by copying these commands into $HOME/.profile
export GTEST_ROOT=$(pwd)/googletest/googletest
export GMOCK_ROOT=$(pwd)/googletest/googlemock

#=== Compile gnucash

cd gnucash-*/
mkdir build
cd build
cmake -DWITH_OFX=ON -DWITH_AQBANKING=OFF -DCMAKE_INSTALL_PREFIX="${APPDIR}/usr" ..
make
make install

echo ""
echo "=== Copy extra shared libraries that are not copied by linuxdeploy later"
echo ""

echo "=> copy GUILE"
cp --recursive --verbose /usr/share/guile "${APPDIR}/usr/share"
cp --recursive --verbose /usr/lib/x86_64-linux-gnu/guile "${APPDIR}/usr/lib"

echo "=> copy SQLITE"
cp --recursive --verbose /usr/lib/x86_64-linux-gnu/dbd "${APPDIR}/usr/lib"

echo "=> copy LIBOFX dependencies"
cp --recursive --verbose /usr/share/libofx6 "${APPDIR}/usr/share"

echo ""
echo "=== Create AppRun main program"
echo ""

cat << EOF > ${APPDIR}/AppRun
#!/usr/bin/env bash
echo "APPDIR = \${APPDIR}"
echo "APPIMAGE = \${APPIMAGE}"
echo "ARGV0 = \${ARGV0}"

HERE="$(dirname "$(readlink -f "${0}")")"
echo "HERE = \${HERE}"

#=======================================================================

APP_STOP_NOW="false"

#APP_HOME="\${ARGV0}.home"
#echo "APP_HOME = \${APP_HOME}"
#if [ -d \${APP_HOME} ]; then
#  echo "  => directory exists : \${APP_HOME}"
#else
#  APP_STOP_NOW="true"
#  if [ -d "\${HERE}/${APP}.home" ]; then
#    echo "  => link : \${APP_HOME} => \${HERE}/${APP}.home"
#    ln -s "${APP}.home" "\${APP_HOME}"
#  else
#    echo "  => create local home directory"
#    exec "${ARGV0}" --appimage-portable-home
#  fi  
#fi

#APP_CONFIG="\${ARGV0}.config"
#echo "APP_CONFIG = \${APP_CONFIG}"
#if [ -d \${APP_CONFIG} ]; then
#  echo "  => directory exists : \${APP_CONFIG}"
#else
#  APP_STOP_NOW="true"
#  if [ -d "\${HERE}/${APP}.config" ]; then
#    echo "  => link : \${APP_CONFIG} => \${HERE}/${APP}.config"
#    ln -s "${APP}.config" "\${APP_CONFIG}"
#  else
#    echo "  => create local config directory"
#    exec "${ARGV0}" --appimage-portable-config
#  fi  
#fi

#if [ "\${APP_CONFIG}" == "true" ]; then
#  echo
#  echo "=> Relancer l'AppImage pour prendre en compte les nouveaux répertoires HOME et CONFIG..."
#  echo
#  exit
#fi

#=======================================================================

export GNC_DBD_DIR="\${APPDIR}/usr/lib/dbd"
export LD_LIBRARY_PATH="\${APPDIR}/usr/lib:\${APPDIR}/usr/lib/gnucash:\$LD_LIBRARY_PATH"
export OFX_DTD_PATH="\${APPDIR}/usr/share/libofx6/libofx/dtd"

echo "PATH = \${PATH}"
echo "GNC_DBD_DIR = \${GNC_DBD_DIR}"
echo "LD_LIBRARY_PATH = \${LD_LIBRARY_PATH}"
echo "OFX_DTD_PATH = \${OFX_DTD_PATH}"
echo "XDG_CONFIG_HOME = \${XDG_CONFIG_HOME}"

#Traite les arguments spécifiques à cette AppImage
THIS_APP_ARGV=()
while [ \$1 ]; do
  case \$1 in
    '--help' | '-h' )
      echo "Usage: \${ARGV0} [OPTIONS]"
      echo
      echo 'OPTIONS:'
      echo '  -h, --help: Show this help screen'
      echo
      THIS_APP_ARGV+=(\$1)
      #exit
      ;;
    *)
      THIS_APP_ARGV+=(\$1)
      ;;
  esac

  shift
done

exec "\${APPDIR}/usr/bin/gnucash" "\${THIS_APP_ARGV}"
EOF

chmod a+x ${APPDIR}/AppRun
