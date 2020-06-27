#!/bin/sh
# Joseph Chen <jocodoma@gmail.com>

if [ -z "$1" ]; then
    echo -e "\nUsage: source joco-setup-env-poky [build-dir]"
    return 1
fi

PROGNAME="sources/poky/oe-init-build-env"
BUILD_DIR="$1"

if [ ! -d "./${BUILD_DIR}" ]; then
    first='true'
fi

# Set up Joco Yocto build environment
. ./$PROGNAME $BUILD_DIR

if test $first; then
    BUILD_DIR=.

    # Update conf/bblayers.conf
    echo "" >> $BUILD_DIR/conf/bblayers.conf
    echo "# Joco Settings" >> $BUILD_DIR/conf/bblayers.conf
    echo "BBLAYERS += \"\${TOPDIR}/../sources/meta-openembedded/meta-oe\"" >> $BUILD_DIR/conf/bblayers.conf
    echo "BBLAYERS += \"\${TOPDIR}/../sources/meta-freescale\"" >> $BUILD_DIR/conf/bblayers.conf
    echo "BBLAYERS += \"\${TOPDIR}/../sources/meta-qt5\"" >> $BUILD_DIR/conf/bblayers.conf
    echo "BBLAYERS += \"\${TOPDIR}/../sources/meta-joco-imx\"" >> $BUILD_DIR/conf/bblayers.conf

    # Update conf/local.conf to reuse packages and sstate cache
    sed -i 's/package_rpm/package_ipk/' $BUILD_DIR/conf/local.conf
    echo "" >> $BUILD_DIR/conf/local.conf
    echo "# Joco Settings" >> $BUILD_DIR/conf/local.conf
    echo "MACHINE ??= \"qemuarm\"" >> $BUILD_DIR/conf/local.conf
    echo "DL_DIR ?= \"/workdir/yocto-share/downloads\"" >> $BUILD_DIR/conf/local.conf
    echo "SSTATE_DIR ?= \"/workdir/yocto-share/sstate-cache\"" >> $BUILD_DIR/conf/local.conf
    echo "SSTATE_MIRRORS ?= \"file://.* file:///workdir/yocto-share/sstate-cache/PATH \n\"" >> $BUILD_DIR/conf/local.conf
    echo "SSTATE_MIRRORS += \"file://.* http://sstate.yoctoproject.org/3.0/PATH;downloadfilename=PATH \n\"" >> $BUILD_DIR/conf/local.conf
    echo "SSTATE_MIRRORS += \"file://.* http://sstate.yoctoproject.org/3.0.1/PATH;downloadfilename=PATH \n\"" >> $BUILD_DIR/conf/local.conf
    echo "SSTATE_MIRRORS += \"file://.* http://sstate.yoctoproject.org/3.0.2/PATH;downloadfilename=PATH \n\"" >> $BUILD_DIR/conf/local.conf
    echo "SSTATE_MIRRORS += \"file://.* http://sstate.yoctoproject.org/dev/PATH;downloadfilename=PATH \n\"" >> $BUILD_DIR/conf/local.conf
fi

echo ""

unset first
unset PROGNAME
unset BUILD_DIR
