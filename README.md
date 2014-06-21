```
############################ 
#           #  #           #
 #          #  #          #
  #        #    #        #
  #       ##    ##       #
   #      #      #      #
   #     #        #     #
    #    #        #    #
    ##  #          #  ##
     # ##          ## #
      ##   Alchemy   ##
      #  Transmuter   #
      ##             ##
     # ##          ## #
    ##  #          #  ##
    #    #        #    #
   #     #        #     #
   #      #      #      #
  #       ##    ##       #
  #        #    #        #
 #          #  #          #
#           #  #           #
############################

```

# What is Transmuter?

Alchemy Transmuter is a light-weight Sinatra app combined with event machine, that is designed to connect 4 major components:

+ Collins Source Of Truth
+ Alchemy Linux
+ Alchemy Spells
+ iPXE

As such, it's pretty closely coupled to these other projects. Transmuter is contacted by iPXE when a server boots via PXE. It will see what it knows about the server in Collins, then make a decision about what the server should do. Examples of such decisions might be:

+ Already bootstrapped? Continue with BIOS boot
+ New hardware? Send Alchemy Linux, with Burnin and Bootstrapp spells, and tell Collins we've got some fresh meat.
+ Collins knows about it, and has a specific job in mind? Send the spell for that job.

Transmuter might be thought of as a lightweight version of Cobbler (from what I'm told, but it's a pretty superficial comparison). Transmuter was inspired by "Phil" and "Visioner" from tumblr.

# Technical details

## Architecture

Transmuter listens on HTTP for requests from servers booting through iPXE. A few identifying details are passed to Transmuter, which it then uses to query Collins server through it's HTTP API. It then makes a decision about what to do with the server, and then consults it's Spellbook to send an appropriate iPXE configuration.

If the spell involves booting Alchemy Linux, Alchemy linux will call home and tell Transmuter how it's doing once in a while (assuming the spell dispatched tells it to do so). 

# Preseed nodes

Read up on the ubuntu [example preseeds](https://help.ubuntu.com/14.04/installation-guide/example-preseed.txt)

## Ubuntu 12.10 + 

Bootstraping ubuntu preseeds later that 12.10 requires you specify a [net-image](http://www.michaelm.info/blog/?p=1378). This is not really documented anywhere, but if it was it wouldn't be ubuntu 

## Ubuntu 14.04

There is a [bug](https://bugs.launchpad.net/ubuntu/+source/grub2/+bug/1274320) in grub that requires quick boot be disabled on LVM installs


