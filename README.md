# Raspberry Pi Image Manager 

This tool makes it easier to download and write the latest version of an image to a device ready for use in a Raspberry Pi.
It has the added benefit as it also gives users a verbose output showing for example how long the write will take.

## Usage

This tool takes 2 parameters like so:

    ./manager.sh {IMAGE_NAME} {DEVICE_PATH}

Where `{IMAGE_NAME}` is one of the images listed below and `{DEVICE_PATH}` is the path to the block device you wish to write the image to

## Parameters

There is a single parameter the tool can take:

    -l or --list-images		List out all the images

## Supported Images

The following images can be installed just by using their names:

- Raspbian
- Ubuntu Snappy
- OPENELEC
- OSMC
- Pidora
- RISC OS
- Retro Pi (For RPi 1 & 2)