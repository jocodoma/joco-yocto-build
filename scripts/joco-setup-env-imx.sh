#!/bin/sh
# Joseph Chen <jocodoma@gmail.com>

if [ -z "$1" ]; then
    echo -e "\nUsage: source joco-setup-env [build-dir]"
    echo -e "\nBy default, MACHINE=imx6qdlsabresd DISTRO=joco-imx-x11\n"
    return 1
fi

PROGNAME="imx-setup-release.sh"
BUILD_DIR="$1"

# Default settings for MACHINE and DISTRO
MACHINE='imx6qdlsabresd'
DISTRO='joco-imx-x11'

# Set up Joco Yocto build environment
MACHINE=$MACHINE DISTRO=$DISTRO . ./$PROGNAME -b $BUILD_DIR

BUILD_DIR=.

# Update conf/bblayers.conf
echo "" >> $BUILD_DIR/conf/bblayers.conf
echo "# Joco Settings" >> $BUILD_DIR/conf/bblayers.conf
echo "BBLAYERS += \"\${BSPDIR}/sources/meta-joco-imx\"" >> $BUILD_DIR/conf/bblayers.conf

# Update conf/local.conf to reuse packages and sstate cache
sed -i 's/package_rpm/package_ipk/' $BUILD_DIR/conf/local.conf
sed -i '/DL_DIR/d' $BUILD_DIR/conf/local.conf
echo "" >> $BUILD_DIR/conf/local.conf
echo "# Joco Settings" >> $BUILD_DIR/conf/local.conf
echo "DL_DIR ?= \"/workdir/yocto-share/downloads\"" >> $BUILD_DIR/conf/local.conf
echo "SSTATE_DIR ?= \"/workdir/yocto-share/sstate-cache\"" >> $BUILD_DIR/conf/local.conf
echo "SSTATE_MIRRORS ?= \"file://.* file:///workdir/yocto-share/sstate-cache/PATH \n\"" >> $BUILD_DIR/conf/local.conf
echo "SSTATE_MIRRORS += \"file://.* http://sstate.yoctoproject.org/3.0/PATH;downloadfilename=PATH \n\"" >> $BUILD_DIR/conf/local.conf
echo "SSTATE_MIRRORS += \"file://.* http://sstate.yoctoproject.org/3.0.1/PATH;downloadfilename=PATH \n\"" >> $BUILD_DIR/conf/local.conf
echo "SSTATE_MIRRORS += \"file://.* http://sstate.yoctoproject.org/3.0.2/PATH;downloadfilename=PATH \n\"" >> $BUILD_DIR/conf/local.conf

echo ""

unset PROGNAME
unset MACHINE
unset DISTRO
unset BUILD_DIR
