---
title: 'Smart PXE'
disqus: hackmd
---

Smart PXE
===

## Table of Contents

[TOC]

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
* Check DNS records such as api,api-int,*.apps, hostnames)
* Check if the IP corresponds to the correct hostname. 
* Network device detection based on busdev (Good for labs, so far just VMware and libvirt)

Automation Workflow
---
1 - Ping Gateway
2 - Check dns(fqdn): hostname.cluster.domainname 
3 - Check dns record: api.cluster.domainname
4 - Check dns record: api-int.cluster.domainname
5 - Check dns record: *apps.cluster.domainname
6 - Try to detect net_interface based on busdev

 - ens192 0000:0b:00.0 ( vSphere nic 1)
 - ens224 0000:13:00.0 ( vSphere nic 2)
 - ens33 0000:02:01.0 (Vmware workstation nic 1)
 - ens38 0000:02:06.0 (Vmware workstation nic 2)
 - enp1s0 0000:01:00.0 (libvirt)

7 - Auto Detect node based on:
 -  Mac Address
 -  Asset Tag

8 - Menu Selector based on Node Role if Auto Detection fails.
 -  Role (master,worker,bootstrap)
 
9 - Fetch OCP Images - kernel, initrd and rootfs
10 - Install CoreOS.

Configuration Parameters
---

The SmartPXE offers the following configuration parameters.


| Parameter | Description |
| -------- | -------- | 
| cluster_name    | OCP Cluster Name     | 
| domain_name    | Domain Name     | 
| fileserver    | Webserver:port that holds the Ignition file,kernel,initrd and rootfs images.    | 
| kernel    | The RHCOS live-kernel    | 
| initrd   | The RHCOS live-initrd     | 
| rootfs    | The RHCOS live-rootfs    | 
| install_drive    | Drive to install RHCOS on | 
| net_interface    | NIC device name | 
| gateway    | Default router IP     | 
| dns_server    | DNS server - For now, it supports just one.     |
| netmask   | Default netmask     |
| bootstrap_mac    | Bootstrap Node Mac address     |
| bootstrap_tag    | Bootstrap Node Asset tag(Optional)     |
| bootstrap_hostname     | Bootstrap Node hostname     |
| bootstrap_ip   | Bootstrap Node IP Address     |
| bootstrap_role    | Bootstrap Node Role(Optional) **It is obvious**      |
| master<X>_mac    | Master Node Mac address     |
| master<X>_tag    | Master Node Asset tag(Optional)     |
| master<X>_hostname    | Master Node hostname     |
| master<X>_ip    | Master Node IP Address     | 
| master<X>_role    | Master Role(Optional) **It is obvious**     |
| worker<Y>_mac    | Worker Node Mac address     | 
| worker<Y>_tag    | Worker Asset tag(Optional)     |
| worker<Y>_hostname    | Worker Node hostname     |
| worker<Y>_ip    | Worker IP Address     |
| worker<Y>_role    | Worker Role(Optional) **It is obvious**   |

> X is the number of the Master Node: From 1 to 3
> Y is the number of the Worker Node: From 2 to **Up to you**

Config File Example
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

bootstrap_mac 00:0c:29:c5:d3:8b
bootstrap_tag bootstrap_node_001
bootstrap_hostname bootstrap
bootstrap_ip 172.16.160.20
bootstrap_role bootstrap

master1_mac 00:0c:29:e2:c6:fa
master1_role master
master1_tag master_node_001
master1_hostname master001
master1_ip 172.16.160.21

master2_mac 00:0c:29:e2:c6:fb
master2_role master
master2_hostname master002
master2_ip 172.16.160.22

master3_mac 00:0c:29:e2:c6:fc
master3_hostname master003
master3_ip 172.16.160.23
master3_role master

worker1_mac 00:50:56:2c:18:1e
worker1_hostname worker001
worker1_ip 172.16.160.30
worker1_role worker

worker2_mac 00:50:56:2c:18:2e
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

git clone REPO
cd REPO

podman build -t smartpxe -f Dockerfile .


Pending:
---
* Multiple DNS Servers
* VLAN Tagging
* Bonding interface
* Second Network Interface
