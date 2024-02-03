# vendor_pixeloverlays

## Basic usage

- If you just wanna use this repository, then you just need to include `config.mk`
- This is as simple as: `$(call inherit-product-if-exists, vendor/pixeloverlays/config.mk)`

## Advanced usage

### Initial setup
- Install `xmlstarlet`
  - `sudo apt install xmlstarlet`, `sudo pacman -S xmlstarlet`, etc. depending on your distribution.
- Install `apktool`, make sure its available in PATH
  - https://ibotpeaches.github.io/Apktool/install/
  - Run `apktool if framework-res.apk` to install framework for apktool this is necessary for proper extracting
    (generally found in /system/framework/)

### Extracting / updating extracted overlays

Basically the same as regular extract-files

```sh
./extract-files.sh /path/to/a/dump
```

### Removing certain overlays

- If certain overlay configs are not required, you can simply add them to `exclude-tag.txt`, those will be removed from the extracted overlays.

### Miscellaneous information

- The main changes here are the addition of `apktool` and `xmlstarlet`, to allow us to extract the necessary overlays from some RROs.
- Since the process does take a while, to speed it up, all extraction is done in the background. This might not be suitable for weaker systems if there is a very high number of overlays to be extracted.
