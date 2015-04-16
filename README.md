# Raspberry Pi Image Manager 

The aim of this tool is to make it easier to download and write the latest version of an image to an SD card ready for use in a Raspberry Pi and also to give a more user-friendly and verbose output; for example how long things are likely to take etc...

## Usage

This tool takes 2 parameters like so:

    ./manager.sh {IMAGE_NAME} {DEVICE_PATH}

Where `{IMAGE_NAME}` is one of the images listed below and `{DEVICE_PATH}` is the path to the block device you wish to write the image to

## Supported Images

The following images can be installed just by using their names:

- Raspbian
- Ubuntu Snappy
- OPENELEC
- OSMC
- Pidora
- RISC OS
- Retro Pi (For RPi 1 & 2)