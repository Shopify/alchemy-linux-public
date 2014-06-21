---
layout: default
title: Home
---


# Automate Baremetal Operations

Simple put, the Alchemy Transmuter is a tool to dynamically render [iPXE](http://ipxe.org/) menus, to carry out various tasks on baremetal servers.

Tasks are implemented as "Alchemy Spells", which is ruby code following a simple template.

The modular architecture of the Alchemy Transmuter enables you to write simple ruby code, erb templates, and yaml configurations for each task you need to perform.

The Alchemy Transmuter HTTP interface is documented [here](doc/TransmuterHTTP.html).

# Applications

Alchemy Transmuter is designed to perform the following operations:

+ Intake (currenty supporting [collins](http://shopify.github.io/collins/), but it should be relative easy to add other Sources of Truth)
+ Burnin - inspired by [stresslinux](http://www.stresslinux.org/sl/) and [breakin](http://www.advancedclustering.com/software/breakin.html)
+ OS installs 
 + Ubuntu via dynamically rendered preseeds
 + CoreOS via dynamically rendered CloudConfig
 + RHEL support could be added by dynamically rendering Kickstart configs
+ Chef / Puppet bootstrapping
+ Health / diagnostics via Memtest.
+ Execute arbitrary scripts on servers with no OS.

All of the above are implemented as spells, which can be chained into one another. This allows you to flow from Intake, into Burnin, into an OS install, and finally a base bootstrapp via a configuration management system like Chef or Puppet.

