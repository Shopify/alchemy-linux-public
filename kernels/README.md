# Configuring kernels

Place the kernel config here. The name of the kernel file is how you reference it in config.yml.

**note** kernel modules should be compiled in ('y' and not 'm'). This offers much better compression, and is much simpler than trying to manage module loading.

Avoid separate modules wherever possible, but if you do need to use modules (blacklisting for instance), then don't forget to depmod.
