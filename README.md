# Joco Yocto Build
* Joco Yocto Build Repo Manifests
  * This repo is used to download manifests for Joco Yocto Build.
  * Specific instructions will reside in READMEs in each branch.

## Last Updated
* Last updated: 2020/06/27 by Joseph Chen < <jocodoma@gmail.com> >
* First draft: 2020/04/14 by Joseph Chen < <jocodoma@gmail.com> >

## Setup Yocto Build Environment
* Prerequisite 
  * To use this manifest repo, the ***repo*** tool must be installed first.
    ```sh
    HOST$ mkdir ~/bin
    HOST$ curl http://commondatastorage.googleapis.com/git-repo-downloads/repo  > ~/bin/repo
    HOST$ chmod a+x ~/bin/repo
    HOST$ PATH=${PATH}:~/bin
    ```

  * Set up share folder for **DL_DIR** and **SSTATE** to speed up incremental build.
    ```sh
    HOST$ sudo mkdir -p /workdir/yocto-share
    HOST$ sudo chown -R $USER: /workdir/
    ```

* Example 1 - FSL Community BSP Environment  
  Setup ***Joco*** Yocto Build with **FSL community** BSP environment based on Yocto Project **zeus** release
  ```sh
  HOST$ mkdir yocto-joco-fsl-zeus
  HOST$ cd yocto-joco-fsl-zeus
  HOST$ repo init -u https://github.com/jocodoma/joco-yocto-build -b zeus -m linux-fsl-community.xml
  HOST$ repo sync
  HOST$ . joco-setup-env build
  ```

* Example 2 - iMX Official BSP Environment  
  Setup ***Joco*** Yocto Build with **iMX official** BSP environment based on Yocto Project **zeus** release
  ```sh
  HOST$ mkdir yocto-joco-imx-zeus
  HOST$ cd yocto-joco-imx-zeus
  HOST$ repo init -u https://github.com/jocodoma/joco-yocto-build -b zeus -m linux-imx-5.4.3-1.0.0.xml
  HOST$ repo sync
  HOST$ . joco-setup-env build
  ```

* Example 3 - Poky Distro with Qemu Emulator  
  Setup ***Joco*** Yocto Build with **Poky** reference distribution environment based on Yocto Project **zeus** release
  ```sh
  HOST$ mkdir yocto-joco-poky-zeus
  HOST$ cd yocto-joco-poky-zeus
  HOST$ repo init -u https://github.com/jocodoma/joco-yocto-build -b zeus -m linux-poky-3.0.2.xml
  HOST$ repo sync
  HOST$ . joco-setup-env build
  ```

* To download new changes and update the working files in your local environment
  ```sh
  HOST$ repo sync
  ```

* Syntax
  ```sh
  HOST$ mkdir <release>
  HOST$ cd <release>
  HOST$ repo init \
        -u <mainfest repo url> \
        -b <branch name> \
        -m <release manifest>
  HOST$ repo sync
  HOST$ . joco-setup-env <build directory>
  ```

## Joco Environment Scripts
As you may notice that after issuing *repo sync* command, we need to source ***joco-setup-env*** script to set up the build environment. This section talks about what this script does.

If you look at manifest files, *[linux-fsl-community.xml](linux-fsl-community.xml)* and *[linux-imx-5.4.3-1.0.0.xml](linux-imx-5.4.3-1.0.0.xml)*, you can see that actually there are two scripts, one for **FSL community** and the other for **iMX official**, as shown below.

```xml
File: linux-fsl-community.xml
<linkfile dest="joco-setup-env" src="tools/scripts/joco-setup-env-fsl.sh"/>

File: linux-imx-5.4.3-1.0.0.xml
<linkfile dest="joco-setup-env" src="tools/scripts/joco-setup-env-imx.sh"/>
```

If you look at both scripts closely, you will find out that *[joco-setup-env-fsl](tools/scripts/joco-setup-env-fsl.sh)* is based on *[setup-environment](https://github.com/Freescale/fsl-community-bsp-base/blob/master/setup-environment)*, which is used by **FSL community** environment. Similarly, *[joco-setup-env-imx](tools/scripts/joco-setup-env-imx.sh)* is based on *[imx-setup-release.sh](https://source.codeaurora.org/external/imx/meta-imx/tree/tools/imx-setup-release.sh)*, which is used by **iMX official** environment.

Following are the things we added into the *joco-setup-env-xxx* scripts.

* **MACHINE and DISTRO**  
  By default, MACHINE and DISTRO are hardcoded in the scripts. MACHINE is set to *imx6qdlsabresd* and DISTRO is set to *Joco x11*. You can feel free to change them as needed.

* **BBLAYERS**  
  To add our meta layer to BBLAYERS, we need to update *conf/bblayers.conf* file. In addition, we also need to add *meta-qt5* to the BBLAYERS for **FSL community** environment.

  ```sh
  BBLAYERS += "${BSPDIR}/sources/meta-qt5"
  BBLAYERS += "${BSPDIR}/sources/meta-joco-imx"
  ```

* **DL_DIR and SSTATE**  
  * **DL_DIR** stands for download directory.
  * **SSTATE** stands for shared state cache.

  To speed up the build process (incremental build), sstate provides a cache mechanism, where sstate files from server/local can be reused to avoid build from scratch if the producer and consumer of the sstate have the same environment. With perfect case, we can achieve more than 80% time decreasing. 

  In our case, we will set **DL_DIR** and **SSTATE** properly for local use.

  ```sh
  DL_DIR ?= "/workdir/yocto-share/downloads"
  SSTATE_DIR ?= "/workdir/yocto-share/sstate-cache"
  SSTATE_MIRRORS ?= "file://.* file:///workdir/yocto-share/sstate-cache/PATH"
  SSTATE_MIRRORS += "file://.* http://sstate.yoctoproject.org/3.0/PATH;downloadfilename=PATH \n"
  SSTATE_MIRRORS += "file://.* http://sstate.yoctoproject.org/3.0.1/PATH;downloadfilename=PATH \n"
  SSTATE_MIRRORS += "file://.* http://sstate.yoctoproject.org/3.0.2/PATH;downloadfilename=PATH \n"
  ```

  ***Note:*** *The default path of share folder in the scripts is* ***/workdir***.
  ```sh
  # Set up share folder for DL_DIR and SSTATE to speed up incremental build
  HOST$ sudo mkdir -p /workdir/yocto-share
  HOST$ sudo chown -R $USER: /workdir/
  ```

* Docker (Optional)  
Here's the [Dockerfile](tools/docker/Dockerfile), which is based on **[crops/poky](https://github.com/crops/poky-container)** recommended by Yocto Project. For more information, please see [Setting Up to Use CROss PlatformS (CROPS)](https://www.yoctoproject.org/docs/current/dev-manual/dev-manual.html#setting-up-to-use-crops).

  To build the image from Dockerfile:
  ```sh
  HOST$ docker build --no-cache -t joco/yocto:latest .
  ```
  To run the container based on the image we just created:  
  (Linux)
  ```sh
  HOST$ docker run --rm -it -v /workdir:/workdir joco/yocto --workdir=/workdir
  ```
  (Mac)
  ```sh
  HOST$ docker run --rm -it -v myYoctoVolume:/workdir joco/yocto --workdir=/workdir
  ```
  To find out your custom volume name:
  ```sh
  HOST$ docker volume ls
  ```

## Poky Distro with Qemu Emulator
For the **Poky distribution**, MACHINE should be set to ***qemuarm*** by default. You may change it in *conf/local.conf* file.

Common commands to run emulator (in bitbake environment):
```sh
HOST$ runqemu                                      ## if there's only one architecture and one image
HOST$ runqemu qemuarm core-image-minimal           ## <MACHINE> <IMAGE>
HOST$ runqemu qemux86 core-image-x11 nographic     ## disable video console
HOST$ runqemu qemuarm core-image-sato serialstdio  ## enable a serial console regardless of graphics mode
```

For more information on Qemu, please see the official document: [Using the Quick EMUlator (QEMU)](https://www.yoctoproject.org/docs/current/dev-manual/dev-manual.html#dev-manual-qemu).

## References
  * Manifests
    * iMX Official BSP Manifest (zeus)  
      https://source.codeaurora.org/external/imx/imx-manifest/tree/?h=imx-linux-zeus
    * FSL Community BSP Manifest (zeus)  
      https://github.com/Freescale/fsl-community-bsp-platform/blob/zeus/default.xml
  * repo
    * repo - The Multiple Git Repository Tool  
      https://gerrit.googlesource.com/git-repo/
    * repo - README  
      https://gerrit.googlesource.com/git-repo/+/refs/heads/master/README.md
    * repo Manifest Format  
      https://gerrit.googlesource.com/git-repo/+/master/docs/manifest-format.md
    * Repo Command Reference  
      https://source.android.com/setup/develop/repo
  * Yocto
    * Shared State Cache (SSTATE)  
      https://www.yoctoproject.org/docs/current/overview-manual/overview-manual.html#shared-state-cache
    * The best way to build with Yocto Project and BitBake  
      http://linuxgizmos.com/the-best-way-to-build-with-yocto-project-and-bitbake/
    * Setting Up to Use CROss PlatformS (CROPS)  
      https://www.yoctoproject.org/docs/current/dev-manual/dev-manual.html#setting-up-to-use-crops
    * crops/poky  
      https://github.com/crops/poky-container
    * Using the Quick EMUlator (QEMU)  
      https://www.yoctoproject.org/docs/current/dev-manual/dev-manual.html#dev-manual-qemu
