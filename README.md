# Raspberry Pi Image Manager 

This tool makes it easier to download and write the latest version of an image to a device ready for use in a Raspberry Pi.
It has the added benefit as it also gives users a verbose output showing for example how long the write will take.

## Install

Installation is easy:

```bash
# Clone this repo
git clone https://github.com/moebrowne/RPi-Image-Manager

# Change directory
cd RPi-Image-Manager
```

## Usage

This tool is completely interactive so just needs executing:

```bash
# Execute!
./manager.sh
```

## Images

You can either write a file from your local disk or download one of the inbuilt ones:

- Raspbian Jessie
- Raspbian Jessie Lite
- Minbian
- Ubuntu Snappy
- OpenELEC
- LibreELEC
- OSMC
- Pidora
- RISC OS
- MATE
- Weather Station
- RetroPie

## Dependencies

There is only a single package required which is non-standard; pv. It's easily installed whatever Distro you're using:

```
# Ubuntu / Debian
apt-get install pv

# RHEL / CentOS
yum install pv
```
