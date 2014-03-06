# Adding overlays

There are two ways to add overlays to Alchemy Linux

All overlays will be installed to /usr/local/portage/OVERLAY, where OVERLAY is the name of the overlay.

## Adding a local overlay

Local overlays will *override* remote overlays of the same name. You can use this as a convenient means of tweaking an upstream overlay.

+ Place the overlay folder here. Any folder in here will be assumed to be an overlay and will be installed accordingly
 + Note that the root folder must be here, with all package atoms and eclasses beneath it.

## Adding a remote overlay

+ Specify the a git-clonable URL to the overlay in config.yml under 'overlays'.
