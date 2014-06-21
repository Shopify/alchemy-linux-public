---
layout: default
title: Home
---

# Automate Baremetal Tasks

Simple put, the Alchemy Linux is a dumb job runner. It takes retrieves commands form kernel parameter, "command\_url", and runs them.

More generally, Alchemy Linux is a swiss-army knife, designed to run entirely in memory, and perform numerous tasks.

A key feature of Alchemy Linux is it is designed to be extremely easy to customize, as it is based on the Portage package manager, used by [CoreOS](https://coreos.com/) and [ChromeOS](http://en.wikipedia.org/wiki/Chrome_OS), as well as the [Gentoo](https://www.gentoo.org/) and [Funtoo](http://www.funtoo.org/Welcome) Linux distributions. Packgase are available from numerous official sources, as well as user contirbuted overlays.

Alchemy Linux is designed to be PXE booted, but should also support Syslinux or Grub (this has not been tested).

# Applications

Alchemy Linux is designed to perform the following operations:

+ Intake (currenty supporting [collins](http://shopify.github.io/collins/) via the [Alchemy Transmuter](http://shopify.github.io/alchemy-transmuter-public/)
+ Burnin, using tools like mprime, stress, stressapptest, and many more.
+ System recovery
+ System diagnostics
+ Automated job dispatching via [Alchemy Transmuter](http://shopify.github.io/alchemy-transmuter-public/)

In the worst case scenario, Alchemy Linux acts as a simple PXE based rescue CD.
