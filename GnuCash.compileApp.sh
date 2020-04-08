#! /bin/bash

#Global variables set by caller
#APP=Gnucash
#LOWERAPP=${APP,,} 
#APPDIR=$(readlink -f appdir)

#=== Compile googletest

git clone https://github.com/google/googletest.git
mkdir --parents googletest/mybuild
pushd googletest/mybuild
cmake -DBUILD_GMOCK=ON ..       #building gmock builds gtest by default
make                            # build the static libraries
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

export GNC_DBD_DIR="\${APPDIR}/usr/lib/dbd"
export LD_LIBRARY_PATH="\${APPDIR}/usr/lib:\${APPDIR}/usr/lib/gnucash:\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
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
