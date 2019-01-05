#! /bin/bash

#Global variables set by caller
#APP=Gnucash
#LOWERAPP=${APP,,} 
#APPDIR=$(readlink -f appdir)

#set -x
#set -e

#=== Get App source

URL=$(wget --quiet "https://github.com/Gnucash/gnucash/releases" -O - | grep -e "gnucash-.*\.tar\.gz" | head -n 1 | cut -d '"' -f 2)
wget --continue "https://github.com${URL}"
tar xf gnucash-*.tar.gz

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
