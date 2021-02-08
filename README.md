## SmartPXE

You probably deploy your OCP/OKD cluster through PXE/DHCP or static IPs with manual interactions. DHCP is the most convenient way to deploy nodes in an automated Way. But what about having to init a new environment without DHCP at all remotely? Suppose you have an OCP4/OKD cluster that you have to deploy, but there is no DHCP environment due to security constraints.

I want to show you a smart way to run pre-checks and install through lightweight iso image.

* BIOS - 1MB
* EFI - 2MB

Based on the iPXE network bootloader: https://github.com/ipxe/ipxe 

## Disclaimer

***This (iPXE) is not a supported by Red Hat***. Use it at your own please and risk!

## Why ?

Why not ?

## About

This project's primary goal is to automate Openshift/OKD cluster installation and run some pre-checks even before the OS deployment.

Available checks:

* Network connectivity - ping gateway
* Check DNS records such as api, api-int, *.apps, hostnames
* Check if the IP corresponds to the correct hostname. 
* Network device detection based on busdev (Good for labs, so far just VMware and libvirt)

Automation Workflow
---
1 - Ping Gateway

2 - Check dns - hostname: hostname.cluster.domainname

3 - Check dns - api : api.cluster.domainname

4 - Check dns - api-int : api-int.cluster.domainname

5 - Check dns - *.apps : *apps.cluster.domainname

6 - Try to detect net_interface based on busdev

 - ens192 0000:0b:00.0 ( vSphere nic 1)
 - ens224 0000:13:00.0 ( vSphere nic 2)
 - ens33 0000:02:01.0 (Vmware workstation nic 1)
 - ens38 0000:02:06.0 (Vmware workstation nic 2)
 - enp1s0 0000:01:00.0 (libvirt)

7 - Menu Selector based on Node Role if Auto Detection fails.
 -  Role (master,worker,bootstrap)
 
8 - Fetch OCP Images - kernel, initrd and rootfs

9 - Install CoreOS.

Configuration Parameters
---

The SmartPXE offers the following configuration parameters.


| Parameter | Description |
| -------- | -------- | 
| cluster_name    | OCP Cluster Name     | 
| domain_name    | Domain Name     | 
| fileserver    | Webserver:port that holds the master.ign,bootstrap.ign,worker.ig,kernel,initrd and rootfs images.    | 
| kernel    | The RHCOS live-kernel    | 
| initrd   | The RHCOS live-initrd     | 
| rootfs    | The RHCOS live-rootfs    | 
| install_drive    | Drive to install RHCOS on | 
| net_interface    | NIC device name | 
| gateway    | Default router IP     | 
| dns_server    | DNS server - For now, it supports just one.     |
| netmask   | Default netmask     |
| bootstrap_hostname     | Bootstrap Node hostname     |
| bootstrap_ip   | Bootstrap Node IP Address     |
| bootstrap_role    | Bootstrap Node Role(Mandatory) **It is obvious** - bootstrap      |
| master<X>_hostname    | Master Node hostname     |
| master<X>_ip    | Master Node IP Address     | 
| master<X>_role    | Master Role(Mandatory) **It is obvious** - master   |
| worker<Y>_hostname    | Worker Node hostname     |
| worker<Y>_ip    | Worker IP Address     |
| worker<Y>_role    | Worker Role(Mandatory) **It is obvious** - worker  |

> X is the number of the Master Node: From 1 to 3

> Y is the number of the Worker Node: From 2 to **Up to you**

Inventory File Example
---
```
cluster_name ocp4
domain_name example.com

fileserver 172.16.160.1:8080
kernel rhcos-live-kernel-x86_64
initrd rhcos-live-initramfs.x86_64.img
rootfs rhcos-live-rootfs.x86_64.img

install_drive /dev/sda
net_interface ens33

gateway 172.16.160.1
dns_server 172.16.160.1
netmask 255.255.255.0

bootstrap_hostname bootstrap
bootstrap_ip 172.16.160.20
bootstrap_role bootstrap

master1_role master
master1_hostname master001
master1_ip 172.16.160.21

master2_role master
master2_hostname master002
master2_ip 172.16.160.22

master3_hostname master003
master3_ip 172.16.160.23
master3_role master

worker1_hostname worker001
worker1_ip 172.16.160.30
worker1_role worker

worker2_hostname worker002
worker2_ip 172.16.160.31
worker2_role worker
.
.
.

worker<Y>_mac 00:50:56:2c:18:2e
worker<Y>_hostname worker002
worker<Y>_ip 172.16.160.31
worker<Y>_role worker

```

Generating the Images
---

```
git clone https://github.com/ralvares/smartpxe
cd smartpxe
vi inventory
podman build -t smartpxe -f Dockerfile .

podman create --name smartpxe smartpxe --entrypoint /
podman cp smartpxe:/ipxe/src/bin/ipxe.iso ipxe_bios.iso
podman cp smartpxe:/ipxe/src/bin-x86_64-efi/ipxe.iso ipxe_efi.iso
podman rm smartpxe
```

From now, you just need to boot up all the nodes using the iso image, select the respective node you want to install and go grab a Coffee :) 

SmartPXE menu selector preview:

![](https://i.imgur.com/XUEMleu.png)

Pending:
---
* Multiple DNS Servers
* VLAN Tagging
* Bonding interface
* Second Network Interface
