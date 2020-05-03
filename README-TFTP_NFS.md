# Setup TFTP and NFS for Kernel and RootFS Development
The idea is to save development time on kernel and root filesystem. Essentially, we set up TFTP and NFS (Network File System) on the host, so that we can load kernel image and rootfs from the host to the device. By doing so, zImage / dtb and rootfs will be still on the host. Hence, we can save time from flashing image using mfgtools.

TFTP is used for loading the kernel. NFS is used to mount the root filesystem remotely from the host machine.

## Last Updated
* Last updated: 2020/05/02 by Joseph Chen < <jocodoma@gmail.com> >
* First draft: 2020/04/22 by Joseph Chen < <jocodoma@gmail.com> >

## Setup DHCP (optional)
DHCP is optional. If your network already has a DHCP server, you can skip this section. Or, you can setup a DHCP server with another ethernet card on your host, and follow the instructions below to do it.

* Install **isc-dhcp-server** on host:
  ```sh
  HOST$ sudo apt update && sudo apt install -y isc-dhcp-server
  ```

* Assuming HOST IP is **192.168.1.6**, and TARGET IP is **192.168.1.7**

* Update DHCP config file at ***/etc/dhcp/dhcpd.conf*** on the host:
  ```sh
  subnet 192.168.1.0 netmask 255.255.255.0 {
      # default-lease-time        86400;
      # max-lease-time            86400;
      # option broadcast-address  192.168.1.255;
      # option ip-forwarding      off;
      # option routers            192.168.1.1;
      # option subnet-mask        255.255.255.0;
      # range                     192.168.1.8 192.168.1.20;

      interface                 eno1;

      host joco_device {
          fixed-address         192.168.1.7;
          hardware ethernet     00:12:34:56:78:9a;
          option root-path      "/workdir/nfs-rootfs";
          filename              "zImage";
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
  u-boot$ setenv serverip 192.168.1.6
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

* loadaddr and fdt_addr  
  Set address for loading kernel and dtb.
  ```sh
  u-boot$ print loadaddr
  u-boot$ setenv loadaddr 0x12000000

  u-boot$ print fdt_addr
  u-boot$ setenv fdt_addr 0x18000000
  ```

* netboot  
  Set netboot command.
  ```sh
  u-boot$ print netboot
  u-boot$ setenv netboot 'netboot=echo Booting from net ...; run netargs; if test ${ip_dyn} = yes; then setenv get_cmd dhcp; else setenv get_cmd tftp; fi; ${get_cmd} ${image}; if test ${boot_fdt} = yes || test ${boot_fdt} = try; then if ${get_cmd} ${fdt_addr} ${fdt_file}; then bootz ${loadaddr} - ${fdt_addr}; else if test ${boot_fdt} = try; then bootz; else echo WARN: Cannot load the DT; fi; fi; else bootz; fi;'
  ```

* Save all settings in u-boot
  ```sh
  u-boot$ saveenv
  ```

* Start netboot  
  By running the following command, it will first of all get the IP from DHCP server, and then start downloading the kernel and dtb from the host via TFTP. After that, it will load kernel and boot up the system. Finally, it will mount the rootfs remotely from the host.
  ```sh
  u-boot$ run netboot
  ```

* Start normal boot
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
