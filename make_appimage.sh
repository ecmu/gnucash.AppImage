#!/usr/bin/env bash
set -x #echo on
set -e #Exists on errors

#alias ll="ls -al"

SCRIPTPATH=$(cd $(dirname "$BASH_SOURCE") && pwd)
echo "SCRIPTPATH = $SCRIPTPATH"
pushd ${SCRIPTPATH}

export APP=GnuCash
export LOWERAPP=${APP,,}
export APPDIR="${SCRIPTPATH}/appdir"

#=== Dependencies versions

PYTHON_VERSION=3.11.4
JQ_VERSION=1.7

#=== Define App version to build

#Workaround for build outside github: "env" file should then contain exports of github variables.
if [ -f "./env" ];
then
  source ./env
fi

if [ "$GITHUB_REF_NAME" = "" ];
then
	echo "Please define tag for this release (GITHUB_REF_NAME)"
	exit 1
fi

#Get App version from tag, excluding suffixe "-Revision" used only for specific AppImage builds...
export VERSION=$(echo $GITHUB_REF_NAME | cut -d'-' -f1)

#=== Package installations for building

# #For gwenhywfar:
# sudo DEBIAN_FRONTEND=noninteractive apt-get install --yes libgcrypt20-dev libgnutls28-dev libtool-bin

sudo DEBIAN_FRONTEND=noninteractive apt-get install --yes patchelf librsvg2-dev libxslt-dev xsltproc libboost-all-dev libgtk-3-dev guile-3.0-dev libgwengui-gtk3-dev libaqbanking-dev libofx-dev libdbi-dev libdbd-sqlite3 libwebkit2gtk-4.0-dev googletest swig language-pack-en language-pack-fr gettext

#=== Add JQ (JSON parser)

JQ_BIN=${SCRIPTPATH}/jq-linux64

if [ ! -f "${JQ_BIN}" ];
then
  wget --continue "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux64"
  chmod +x "${JQ_BIN}"
fi

#=== Get App source

if [ ! -f "./${LOWERAPP}-${VERSION}.tar.gz" ];
then
	JSON=$(wget -q -O - https://api.github.com/repos/Gnucash/gnucash/releases)
	URL=$(echo $JSON | ./jq-linux64 '.[] | select(.tag_name == env.VERSION) | .assets[] | select(.content_type == "application/gzip" and (.browser_download_url | contains("docs") | not)) | .browser_download_url')
  wget --continue $(echo $URL | tr -d "'" | tr -d '"') --output-document="${LOWERAPP}-${VERSION}.tar.gz"
  rm --recursive --force "./${LOWERAPP}-${VERSION}"
fi

if [ ! -d "./${LOWERAPP}-${VERSION}" ];
then
  tar --extract --file="./${LOWERAPP}-${VERSION}.tar.gz"
fi

#=== Compile main App

APP_BuildDir="${LOWERAPP}-${VERSION}_build"

if [ ! -d "${APP_BuildDir}" ];
then
	#Force uninstalled:
  rm --recursive "${APPDIR}"

  mkdir "${APP_BuildDir}"
  pushd "${APP_BuildDir}"

  #if [ -z "$TZ" ];
  #then #dpkg-reconfigure tzdata
  #  export TZ='America/Los_Angeles' #'Europe/Paris'
  #fi

  cmake -DWITH_PYTHON=ON -DCMAKE_INSTALL_PREFIX=${APPDIR}/usr "../${LOWERAPP}-${VERSION}/"
  make -j$(nproc)

  popd
fi

#=== Install main application into AppDir

if [ ! -d "${APPDIR}" ];
then
	#=== AppDir

	#if [ ! -d "${APPDIR}/usr" ];
	#then
		mkdir --parents "${APPDIR}/usr"
	#fi

	export PATH="${APPDIR}/usr/bin:$PATH"
	export LD_LIBRARY_PATH="${APPDIR}/usr"/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

	#=== Add python

	PYTHON_ZIP=python_binaries-${PYTHON_VERSION}.tar.gz

	if [ ! -f "${SCRIPTPATH}/${PYTHON_ZIP}" ];
	then
		wget --continue "https://github.com/ecmu/Python-linux-binaries/releases/download/${PYTHON_VERSION}/${PYTHON_ZIP}"
	fi

	tar --directory="${APPDIR}/usr" --extract --file="${SCRIPTPATH}/${PYTHON_ZIP}"

	if [ ! -h "${APPDIR}/usr/bin/python" ]; then
		pushd "${APPDIR}/usr/bin"
		ln --symbolic python3 python
		popd
	fi

	#TODO: set complete python environment for these installs...
	#PyGObject == 'gi' module used in GnuCash
	#python3 -m pip install PyGObject
	# apt download python3-gi
	# dpkg-deb --extract python3-gi_3.42.1-0ubuntu1_amd64.deb ./appdir/

  pushd "${APP_BuildDir}"
  make install
  popd
fi

#=== Extra shared libraries from distribution packages
#Get dependencies packages for runtime (I couldn't use linuxdeploy the way I wanted so this is workaround using AppImageTool directly...)

APP_DEPDIR="${SCRIPTPATH}/${LOWERAPP}-dependencies"

if [ ! -d "${APP_DEPDIR}" ]; then
  mkdir --parents "${APP_DEPDIR}"

	#--- Downloading gnucash dependencies packages...

	pushd "${APP_DEPDIR}"

	##Initial source = gnucash package description for ubuntu 20.04 LTS (https://packages.ubuntu.com/jammy/gnucash)
	#apt-get download guile-3.0 guile-3.0-libs libaqbanking44 libboost-filesystem1.71.0 libboost-locale1.71.0 libboost-program-options1.71.0 libboost-regex1.71.0 libcairo2 libcrypt-ssleay-perl libdate-manip-perl libdbd-sqlite3 libdbi1 libfinance-quote-perl libjavascriptcoregtk-4.0-18 libgdk-pixbuf2.0-0 libgtk-3-0 libgwengui-gtk3-0 libgwenhywfar79 libharfbuzz-icu0 libhtml-tableextract-perl libhtml-tree-perl libicu66 libkeyutils1 libofx7 libpango-1.0-0  libpangoft2-1.0-0 libpangocairo-1.0-0 libsecret-1-0 libwebkit2gtk-4.0-37 libwww-perl libxml2 perl zlib1g
	#apt-get download libosp5 libffi7 libboost-thread1.71.0 libboost-date-time1.71.0 libwebp6

	#For linux distribution:
	apt-get download guile-3.0 guile-3.0-libs libaqbanking44 
	apt-get download libboost-filesystem1.74.0 libboost-locale1.74.0 libboost-program-options1.74.0 libboost-regex1.74.0 libboost-thread1.74.0 libboost-date-time1.74.0 \
	 libcairo2 libcrypt-ssleay-perl libdate-manip-perl libdbd-sqlite3 libdbi1 libfinance-quote-perl libjavascriptcoregtk-4.0-18 libgdk-pixbuf-2.0-0 libgtk-3-0 \
	 libgwengui-gtk3-79 libgwenhywfar79 libharfbuzz-icu0 libhtml-tableextract-perl libhtml-tree-perl \
	 libicu70 libkeyutils1 libofx7 libpango-1.0-0  libpangoft2-1.0-0 libpangocairo-1.0-0 libsecret-1-0 libwebkit2gtk-4.0-37 libwww-perl libxml2 perl zlib1g \
	 libosp5 libffi7 libwebp7 \
	 libunistring2
	#dependencies for pixbuf:
	apt-get download libjpeg-turbo8 libtiff5

	#Extracting gnucash dependencies packages...
	for f in $(ls *.deb); do dpkg-deb -x ./$f "${APP_DEPDIR}/appdir/"; done
	cp --recursive --remove-destination appdir/lib/   appdir/usr/ && rm --recursive appdir/lib
	cp --recursive --remove-destination appdir/lib64/ appdir/usr/ && rm --recursive appdir/lib64

	popd

	#Some missing elements:
	if [ ! -f "${APP_DEPDIR}/appdir/usr/bin/guile" ]; then
		if [ -d "${APP_DEPDIR}/appdir/usr/bin" ]; then
			pushd "${APP_DEPDIR}/appdir/usr/bin"
			ln --symbolic guile-3.0 guile
			popd
		fi
	fi
fi

#Copying dependent libraries in final AppDir
cp --preserve --recursive "${APP_DEPDIR}"/appdir "${SCRIPTPATH}"

#=== Extra libraries from build environment to be embedded into AppDir

mkdir --parents "${APPDIR}"/usr/lib/x86_64-linux-gnu
cp --preserve --recursive /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 "${APPDIR}"/usr/lib/x86_64-linux-gnu

#=== Complete AppDir (useful here for execution tests directly from AppDir)

APPIMAGE_STOP=0

pushd ${APPDIR}

cp --preserve "${SCRIPTPATH}"/AppRun .
chmod +x ./AppRun

if [ ! -f ./gnucash.desktop ];
then
	if [ -f ./usr/share/applications/gnucash.desktop ];
	then
		ln --symbolic ./usr/share/applications/gnucash.desktop ./gnucash.desktop
	else
		echo "ERROR - missing desktop file: ./usr/share/applications/gnucash.desktop"
		APPIMAGE_STOP=1
	fi
fi
if [ ! -f ./gnucash-icon.svg ];
then
	if [ -f ./usr/share/icons/hicolor/scalable/apps/gnucash-icon.svg ];
	then
		ln --symbolic ./usr/share/icons/hicolor/scalable/apps/gnucash-icon.svg ./gnucash-icon.svg
	else
		echo "ERROR - missing desktop file: ./usr/share/icons/hicolor/scalable/apps/gnucash-icon.svg"
		APPIMAGE_STOP=1
	fi
fi

popd

if [ "$APPIMAGE_STOP" == "1" ];
then
	exit 1
fi

#=== Construct AppImage

#This tool is freezed with release to be able to reproduce AppImage if needed since this is a "continuous" tool.
if [ ! -f "./appimagetool-x86_64.AppImage" ];
then
	wget "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
	chmod a+x appimagetool-x86_64.AppImage
fi

export VERSION=$GITHUB_REF_NAME
ARCH=x86_64 ./appimagetool-x86_64.AppImage --appimage-extract-and-run --no-appstream --verbose "${APPDIR}"

#===

echo "AppImage generated = $(readlink -f $(ls ${APP}*.AppImage))"
popd
