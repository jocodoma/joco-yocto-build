# Setup TFTP and NFS for Kernel and RootFS Development
The idea is to save development time on kernel and root filesystem. Essentially, we set up TFTP and NFS (Network File System) on the host, so that we can load kernel image and rootfs from the host to the device. By doing so, zImage / dtb and rootfs will be still on the host. Hence, we can save time from flashing image using mfgtools.

TFTP is used for loading the kernel. NFS is used to mount the root filesystem remotely from the host machine.

## Last Updated
* Last updated: 2020/06/27 by Joseph Chen < <jocodoma@gmail.com> >
* First draft: 2020/04/22 by Joseph Chen < <jocodoma@gmail.com> >

## Setup DHCP
It would be better to set up a DHCP server with another ethernet card on your host, so that you can keep the internet access available.

* Install **isc-dhcp-server** on host:
  ```sh
  HOST$ sudo apt update && sudo apt install -y isc-dhcp-server
  ```

* Assuming HOST IP is **192.168.3.6**, HOST Ethernet Interface: **eno1**, ROOTFS PATH on HOST: **/workdir/nfs-rootfs**
  TARGET IP is **192.168.3.7**, TARGET MAC address: **00:04:9f:02:e3:48**

* Update DHCP config file at ***/etc/dhcp/dhcpd.conf*** on the host:
  ```sh
  subnet 192.168.3.0 netmask 255.255.255.0 {
      # default-lease-time        86400;
      # max-lease-time            86400;
      # option broadcast-address  192.168.3.255;
      # option ip-forwarding      off;
      # option routers            192.168.3.1;
      # option subnet-mask        255.255.255.0;
      # range                     192.168.3.8 192.168.3.20;

      interface                 eno1;

      host joco_device {
          fixed-address       192.168.3.7;
          hardware ethernet   00:04:9f:02:e3:48;
          option root-path    "/workdir/nfs-rootfs";
          filename            "zImage";
    }
  }
  ```

* Restart DHCP service:
  ```sh
  HOST$ sudo systemctl restart isc-dhcp-server
  ```

## Setup TFTP
* Install **tftpd-hpa** on host:
  ```sh
  HOST$ sudo apt update && sudo apt install -y tftpd-hpa
  ```

* Check if TFTP daemon is running (assuming you are using systemd):
  ```sh
  HOST$ systemctl status tftpd-hpa
  ```

* Setup TFTP directory:
  ```sh
  HOST$ sudo mkdir -p /workdir/tftp-boot
  HOST$ sudo chown -R $USER: /workdir/tftp-boot
  ```

* Change TFTP default directory at ***/etc/default/tftpd-hpa*** on the host as below:
  ```sh
  TFTP_DIRECTORY="/workdir/tftp-boot"
  ```

* Restart TFTP service:
  ```sh
  HOST$ sudo systemctl restart tftpd-hpa
  ```

## Setup NFS
* Install **nfs-kernel-server** on host:
  ```sh
  HOST$ sudo apt update && sudo apt install -y nfs-kernel-server
  ```

* Check if NFS daemon is running (assuming you are using systemd):
  ```sh
  HOST$ systemctl status nfs-kernel-server
  ```

* Setup NFS directory:
  ```sh
  HOST$ sudo mkdir -p /workdir/nfs-rootfs
  HOST$ sudo chown -R $USER: /workdir/nfs-rootfs
  ```

* Update NFS export file at ***/etc/exports*** on the host as below:
  ```sh
  /workdir/nfs-rootfs   192.168.*.*(rw,sync,no_root_squash,no_subtree_check)
  ```

* Restart NFS service:
  ```sh
  HOST$ sudo systemctl restart nfs-kernel-server
  ```

## Target Setup
Turn on the device and press any key to stop at u-boot stage.

* ethaddr
  Check if mac address is assigned and match with the settings above in DHCP on host.
  ```sh
  u-boot$ print ethaddr
  u-boot$ setenv ethaddr 00:04:9f:02:e3:48
  ```

* serverip
  Set serverip which is your host IP.
  ```sh
  u-boot$ print serverip
  u-boot$ setenv serverip 192.168.3.6
  ```

* nfsroot
  Set the path of nfsroot, which should match with the settings above in NFS on host.
  ```sh
  u-boot$ print nfsroot
  u-boot$ setenv nfsroot /workdir/nfs-rootfs
  ```

* image and fdt_file
  Set the file names for kernel image and dtb.
  ```sh
  u-boot$ print image
  u-boot$ setenv image zImage

  u-boot$ print fdt_file
  u-boot$ setenv fdt_file imx6q-sabresd.dtb
  ```
  Note: If it's for solo, change to **imx6dl-sabresd.dtb**.

* loadaddr and fdt_addr
  Set address for loading kernel and dtb.
  ```sh
  u-boot$ print loadaddr
  u-boot$ setenv loadaddr 0x12000000

  u-boot$ print fdt_addr
  u-boot$ setenv fdt_addr 0x18000000
  ```

* netboot
  Set netboot command for both kernel and rootfs (with TFTP/kernel):
  ```sh
  u-boot$ print netboot
  u-boot$ setenv netboot 'echo Booting from net ...; run netargs; if test ${ip_dyn} = yes; then setenv get_cmd dhcp; else setenv get_cmd tftp; fi; ${get_cmd} ${image}; if test ${boot_fdt} = yes || test ${boot_fdt} = try; then if ${get_cmd} ${fdt_addr} ${fdt_file}; then bootz ${loadaddr} - ${fdt_addr}; else if test ${boot_fdt} = try; then bootz; else echo WARN: Cannot load the DT; fi; fi; else bootz; fi;'
  ```

* devboot and netcmd
  Set devboot and netcmd commands for rootfs only (without TFTP/kernel):
  ```sh
  u-boot$ print devboot
  u-boot$ setenv devboot 'echo Booting rootfs from net ...; run netargs; if test ${boot_fdt} = yes || test ${boot_fdt} = try; then if run loadfdt; then bootz ${loadaddr} - ${fdt_addr}; else if test ${boot_fdt} = try; then bootz; else echo WARN: Cannot load the DT; fi; fi; else bootz; fi;'

  u-boot$ print netcmd
  u-boot$ setenv netcmd 'run findfdt;mmc dev ${mmcdev};if mmc rescan; then if run loadbootscript; then run bootscript; else if run loadimage; then run devboot; fi; fi; else run devboot; fi'
  ```

* Save all settings in u-boot
  ```sh
  u-boot$ saveenv
  ```

## Run netboot / netcmd / bootcmd
Turn on the device and press any key to stop at u-boot stage.

* To download **kernel** image and mount **rootfs** from host (**TFTP** + **NFS**):
  ```sh
  u-boot$ run netboot
  ```
  By running the above command, it will first get the IP from DHCP server, and then start downloading the kernel and dtb from the host via TFTP. After that, it will load kernel and boot up the system. Finally, it will mount the rootfs remotely from the host.

* To load kernel from device and mount **rootfs** remotely from host (**NFS**):
  ```sh
  u-boot$ run netcmd
  ```

* To start normal boot (load everything from device):
  ```sh
  u-boot$ run bootcmd
  ```

## References
  * Manifests
    * Boot I.MX6q SABRE over the Network using TFTP and NFS
      https://community.nxp.com/docs/DOC-340583
    * Boot from a TFTP/NFS Server
      https://developer.toradex.com/knowledge-base/boot-from-a-tftpnfs-server#Sample_DHCP_Configuration
    * Yocto NFS & TFTP boot
      https://community.nxp.com/docs/DOC-103717
