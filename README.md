```
             ##   ##
         ##     #     ##
       ##      # #      ##
     ##       #   #       ##
    ##       #     #       ##
   ##       #       #       ##
  ##       #   ###   #       ##
  ##      #  #     #  #      ##
  ##     #   #     #   #     ##
  ##    #      ###      #    ##
   ##  ###################  ##
    ##       Alchemy       ##
     ##       Linux       ##
       ##               ##
         ##           ##
             ##   ##
```

# What is alchemy Linux?

Alchemy Linux is a relatively small embedded Linux deployment designed to be PXE booted and run entirely from RAM, to operate on diskless nodes, and without affecting any existing systems installed on the host. 

Alchemy is meant to be a swiss army knife, it was inspired by "Invisible Touch" from Tumblr, as well as various system rescue images, StressLinux, and Breakin. 

Some of the intended uses of Alchemy Linux would be to:

+ Bootstrap new hardware, and add it to a Infrastructure Management System like Collins
+ Perform hardware burn-in and stress testing or benchmarking
+ Hardware diagnostics and inspection
+ Hardware initialization
+ System rescue, recovery, or repair
+ Network debugging and profiling

The motivation for developing Alchemy Linux is be able to easily customize a Linux image to automate baremetal datacenter tasks, to turn "baremetal into gold"

This repository contains the scripts necessary to build alchemy Linux.

# Technical details

## Distro

Alchemy Linux is built using [funtoo](http://www.funtoo.org), a gentoo derivative. A single stage3 tarbal is specified for the given architecture, but the rest of the process is entirely source driven. This makes alchemist extremely flexible, as it can leverage the power of the portage package manager and ebuild system for custom binaries. 

## Boot process

Alchemy will start /init by default, which is a shell script that can be used either on its own to do whatever is desired, or can do some tasks before calling the real /sbin/init.

## Kernel Drivers

Alchemy should work out of box with most server configurations tested, but the kernel may not have all modules needed to detect certain kinds of servers.

If this is the case, you'll need to determine what hardware is not detected, and add the missing config to the kernel.

## Files

```
├── README.md                 # This file
├── Rakefile                  # The 
├── bin                       # The output directory
│   ├── alchemy.img           # Output kernel image
│   └── alchemy.ramfs         # Output ramdisk
├── cache                     # Generated folder for caching to speed up builds
│   ├── packages              # Pre-built packages are pulled in from here
├── chroot                    # Files to be run inside the chroot to build the system
│   ├── README.md             # Documentation for this folder
│   ├── adminuser             # Script to make the admin user
│   ├── init                  # Default init script / init script wrapper
│   ├── methods               # Library for functions building inside chroot
│   └── setup.sh              # Actual chroot script that builds the system inside the chroot
├── config.yml.example        # Sample configuration file
├── distfiles                 # Distfiles directory
│   └── README.md             # Documentation for how to use distfiles
├── etc                       # etc directory tree that will be merged into system image
│   ├── README.md             # Documentation for this directory
│   ├── motd                  # Alchemy Linux motd
│   ├── portage               # Portage configuration during chroot
│   │   ├── make.conf         # Global build configurations
│   │   └── package.use       # Package specific use flags
│   └── tmux.conf             # A basic, sane tmux.conf ;)
├── kernels                   # Kernel config directory
│   ├── 3.14                  # Default kernel config for 3.14
│   └── README.md             # Documentation on kernel configuration
├── lib                       # libs for Rakefile build process
│   └── util.rb               # Rake tasks used by the build
├── overlays                  # Ovelarlay directory - overlays stored here will be merged
│   └── README.md             # Docs for overlay directory
└── packages                  # Directory containing package specs directory
    ├── README.md             # Documentation on how to use package specs
    ├── packages.benchmark    # Benchmark related packages
    ├── packages.breakin      # Packages from breakin
    ├── packages.core         # Core packages
    ├── packages.eula         # Packages that need a EULA / with a fetch restriction
    ├── packages.network      # Network related packages
    ├── packages.storage      # Storage related packages
    └── packages.util         # Generat utility packages
```

## System Requirements

+ At least 1GB of memory, alchemy uses about 900MB right now, but you'll also want some memory to work with
+ Hardware that is generally supported by Linux
+ PXE bootable NIC, alchemy currently doesn't come with any grub or lilo configs, but there's no reason why it wouldn't boot off them if configured.

## Build dependencies

+ Some sort of linux supporting chroot
+ xz (with lzma utility)
+ wget 
+ ruby
+ git
+ bc (better calculator - required by linux kernel build)
+ build-essential

# Usage

To build Alchemy Linux:
```
rake build:all[version] # the version specified will show up in lsb-release and uname, otherwise 'wip' if unspecified
```

# Kernel parameters

A few kernel parameters will be parsed by the preliminary initramfs:

+ net: Attempt to start all detected interfaces before starting /sbin/init
+ shell: Drop to a busybox shell
+ ssh: Start an ssh server inside busybox (useful for debugging)
+ lldpd: Start lldpd inside busybox
+ real\_init: If specified, the real init process to run (unset this if you need to debug /init for some reason to get to rescue shell)
+ ssh\_keys\_url: The URL containing ssh keys to add to the admin user.
+ command\_url: The URL containing the payload instructions. This url well be fetched an run as a script.


# What's working:

+ SSH
+ lldpd / lldpctl
+ lshw
+ dmidecode
+ ipmitool
+ burnin
 + stress
 + stressapptest
 + mprime torture
+ megacli - caveat, requires you to fetch the binary and agree to EULA

# TO DO:

+ Keep track of known supported hardware
+ Setup paths for /opt utils
+ Options to embed or separate initramfs (most of build time is kernel, which changes much less)

## Missing packages from stresslinux and wishlist

+ Create overlay with missing programs:
 + Nepim
 + Bandwidth
 + y-cruncher
 + areca-cli
 + sas2ircu
 + pcopy
 + breakin # from breakin
 + stuff from archlinux
  + https://aur.archlinux.org/packages/linpack/
  + https://aur.archlinux.org/packages/systester/

# FAQ

## Why Funtoo? Seems like a bit of a hipster distro

Funtoo was chosen over Gentoo due to a number of design improvements, and a strong believe in the [benevolent dictator](http://en.wikipedia.org/wiki/Daniel_Robbins_(computer_programmer)).

A Funtoo/Gentoo system was chosen over a Debian or RedHat derivative due to it's source-based nature and focus towards customizeability. Since this isn't meant to run as an enterprise server, a system that's very configuraeable OOB is much more important than a hardened server architecture. This also fully open sources the build process, so you can see exactly what you're running, and change anything you don't like, or need to improve.

# Other projects

Alchemy was built to work well with alchemist, ipxe, and collins.

# Acknowledgements

Alchemy is inspired by tumblr's "Invisible Touch", as well as projects like Stress linux, and Breakin, and the scripts contained in this project are based on a simple script shared by Box Inc.

# Further reading

* If you intend to do some hacking and you've never touched Gentoo, leaf through the venerable [gentoo handbook](http://www.gentoo.org/doc/en/handbook/handbook-amd64.xml?full=1), which is one of the best docs ever written for anything, anywhere.
+ Read about [USE flags](http://www.gentoo.org/doc/en/handbook/handbook-x86.xml?part=2&chap=2)
+ The gentoo [binary package guide](https://wiki.gentoo.org/wiki/Binary_package_guide) and [binary package support](https://www.gentoo.org/doc/en/handbook/handbook-ppc64.xml?part=2&chap=3#doc_chap4)
+ Gentoo [ebuild dev manual](http://devmanual.gentoo.org/) for custom overlays, and knitty gritty hacking
+ Gentoo [overlay docs](http://wiki.gentoo.org/wiki/Overlay)
+ Funtoo [launchpad](http://www.funtoo.org/Welcome)
+ An [overview of funtoo and comparison with gentoo](http://www.funtoo.org/Funtoo_Linux)

# References

* [Stress Linux example](https://www.linux.com/learn/tutorials/613523-stresslinux-torture-tests-your-hardware)
* [Totally stressed](http://www.admin-magazine.com/Articles/Totally-Stressed)
* [Advanced Clustering - Breakin](http://www.advancedclustering.com/software/breakin.html)
* [Initramfs packing](http://wiki.gentoo.org/wiki/Custom_Initramfs#Packaging_Your_Initramfs)
