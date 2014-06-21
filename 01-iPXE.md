---
title: iPXE
modified: 2014-06-07 23-18-54
layout: page
tags: []
permalink: "ipxe.html"
comments: true
---

<section id='provision'>
# Scalable Provisioning

There are many ways to install an Operating System using physical media such as USB sticks or CD/DVD roms. In a datacenter, the only scalable way to provision servers is using [PXE](http://en.wikipedia.org/wiki/Preboot_Execution_Environment).

Almost any modern server's NICs should support PXE booting, but the stock PXE behavior is usually pretty terrible to work with. They are capable of speaking the PXE protocol to load selected images via TFTP into memory, but don't offer any sort of sophisticated capabilities.

Notably, stock PXE roms lack support for scripting, or even boot menus. 

PXE as a protocol is pretty stupid. It recieves DHCP BOOTP packets, which usually provide a reference to an image to boot via TFTP.

This means that PXE is alright if you want to have everything boot the same image, but it lacks the capability to make any decision making, or simple manual intervention.

<section id='ipxe-rescue'>
# iPXE to the rescue

[iPXE](http://ipxe.org/) is a custom boot firmware that provides a robust scripting and menu support that runs directly on the server-to-be-booted's NIC.

The Alchemy Transmuter uses iPXE as its interface to the baremetal. Since both the Alchemy Transmuter **and** iPXE speak HTTP, and iPXE talks to the hardware, iPXE adds as the middle-man for the Alchemy Transmuter to control the underlying hardware.

<section id='chain-ipxe'>
## Chainloading iPXE

One of the most notable features of iPXE is that it can be easily [chainloaded](http://ipxe.org/howto/chainloading), meaning that you can provide it as the single image advertised by your boot server via DHCP, and then have all of your servers chainload into iPXE without having to physically flash it to your NICs roms. This means that "installing" iPXE is as simple as configuring a DHCP server to advertise the iPXE image via DHCP BOOTP, and setting up a TFTP server to host the image.

<section id='server-id'>
## Server indentification

Another extremely powerful feature of iPXE is that it is able to read the SMBios of the server being booted. This gives us access to the system's serials, manufacturer, product code, and any other information encoded by the vendor.

Using the system's manufacturer and serial, we can build a unique ID, a "SKU", for each server. This is extremely powerful, as it allows servers to say "this is who I am" rather than be told "this is who you are", so the server itself is the ultimate Source of Truth on its own identity.

The way we recommend booting iPXE is with an [embedded script](http://ipxe.org/embed), calling back to the boot server to ask for further instructions. You can just grab [our fork](https://github.com/Shopify/ipxe), which has [an example](https://github.com/Shopify/ipxe/blob/master/src/bootstrap.ipxe) of such a script.

We run the Alchemy Transmuter on the DHCP boot server, so when iPXE calls back via HTTP, it's the Transmuter that it will be talking to. Alchemy Transmuter replies with [another iPXE script](https://github.com/Shopify/alchemy-transmuter-public/blob/master/views/boot.erb), requesting that the iPXE ROM call back again with the information that the Transmuter needs to identify the server being booted. This script could just be embedded, but we take advantage of chainloading to be able to dynamically update the logic of this boot script. For this reason, we keep the embedded script as simple as possible, so that we don't have to rebuild the iPXE image to make changes to the boot logic.

<section id='dynamic-decisions'>
## Dynamic decisions

Once iPXE has identified the server with the Alchemy Transmuter, the Transmuter can decide what to do with the server. It will check in if it has any active Spells being casted on this server, or if Collins wants it to cast a new spell.

The Transmuter responds with an iPXE boot menu, and automates the decision it wants to make by setting the menu defaults accordingly. If it has nothing to do for this server, the defaults are to just continue with the BIOS boot. If however, we want to load an OS, run a memtest, or anything else we need iPXE to boot, we simple set the menu default accordingly.

This is powerful, as it enables us to still have beautfully rendered boot menus if we need to manually override the boot process for a given server, but also gives us the ability to easily automate server boots by dynamically setting the default option, and booting it after a short timeout.

<section id='alternatives'>
# Alternatives to iPXE

## PXElinux 

PXELinux is a popular alternative to iPXE, based on the syslinux bootloader. PXELinux provides support for boot menus, but in our experience is much more difficult to configure. PXELinux also lacks client side scripting, making it  much more difficult to use for automation. PXELinux was designed to just load configuration files off a central server, and not for scripting or advanced flow control, such as conditionals and branching.
