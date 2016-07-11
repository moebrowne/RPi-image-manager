#!/bin/bash

echo "-----------------------------------------"
echo " Raspberry Pi Image Manager (RIM) v0.3.4 "
echo "-----------------------------------------"

# Get the source directory
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Set the library root path
LIBRARY_PATH_ROOT="$DIR/utils"

# Include the generic libraries
. "$LIBRARY_PATH_ROOT/generic.sh"
. "$LIBRARY_PATH_ROOT/colours.sh"

# Set default options
IMAGE_LIST=false

# Get any params defined
for i in "$@"
do
case $i in
        -l|--list-images)	IMAGE_LIST=true ;;
        -*)					echo "UNKNOWN PARAMETER ${i#*=}"; exit ;;
esac
done

declare -A Images

Images['Raspbian-Whezzy']="https://downloads.raspberrypi.org/raspbian/images/raspbian-2015-05-07/2015-05-05-raspbian-wheezy.zip"
Images['Raspbian-Jessie']="https://downloads.raspberrypi.org/raspbian/images/raspbian-2016-05-31/2016-05-27-raspbian-jessie.zip"
Images['Raspbian-Jessie-Lite']="https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2016-05-31/2016-05-27-raspbian-jessie-lite.zip"
Images['Minbian']="http://downloads.sourceforge.net/project/minibian/2016-03-12-jessie-minibian.tar.gz"
Images['Snappy']="http://cdimage.ubuntu.com/ubuntu-snappy/15.04/stable/latest/ubuntu-15.04-snappy-armhf-raspi2.img.xz"
Images['OpenELEC']="http://releases.openelec.tv/OpenELEC-RPi.arm-6.0.3.img.gz"
Images['OpenELECPi2']="http://releases.openelec.tv/OpenELEC-RPi2.arm-6.0.3.img.gz"
Images['LibreELEC']="http://releases.libreelec.tv/LibreELEC-RPi.arm-7.0.2.img.gz"
Images['LibreELECPi2']="http://releases.libreelec.tv/LibreELEC-RPi.arm-7.0.2.img.gz"
Images['OSMC']="http://download.osmc.tv/installers/diskimages/OSMC_TGT_rbp1_20160621.img.gz"
Images['OSMCPi2']="http://download.osmc.tv/installers/diskimages/OSMC_TGT_rbp2_20160621.img.gz"
Images['Pidora']="http://pidora.ca/pidora/releases/20/images/Pidora-2014-R3.zip"
Images['RISCOS']="https://www.riscosopen.org/zipfiles/platform/raspberry-pi/riscos-2015-02-17.14.zip"
Images['RetroPi']="https://github.com/RetroPie/RetroPie-Setup/releases/download/3.6/retropie-v3.6-rpi1_zero.img.gz"
Images['RetroPi2']="https://github.com/RetroPie/RetroPie-Setup/releases/download/3.6/retropie-v3.6-rpi2_rpi3.img.gz"
Images['MATE']="https://ubuntu-mate.r.worldssl.net/raspberry-pi/ubuntu-mate-15.10.3-desktop-armhf-raspberry-pi-2.img.xz"
Images['Weather-Station']="https://downloads.raspberrypi.org/weather_station/images/weather_station-2016-03-24/WeatherStation.zip"


declare -A ImagesSHA1

ImagesSHA1['Raspbian-Whezzy']="cb799af077930ff7cbcfaa251b4c6e25b11483de"
ImagesSHA1['Raspbian-Jessie']="64c7ed611929ea5178fbb69b5a5f29cc9cc7c157"
ImagesSHA1['Raspbian-Jessie-Lite']="03b6ea33efc3bb4d475f528421d554fc1ef91944"
ImagesSHA1['Minbian']="43558a173420108408bb8c1c6731ed5812c06971"
ImagesSHA1['Snappy']="2d32d93e0086593fe34b8c07d4af7227c79addd3"
ImagesSHA1['OpenELEC']="4dbcabd10d92f046c090f8fb68c0b5edcc78cd60"
ImagesSHA1['OpenELECPi2']="31082d36c369f49a6223776f776db967b6c48a48"
ImagesSHA1['LibreELEC']="aab1e74c764bd9321ecba19f27411edd3a0e841b"
ImagesSHA1['LibreELECPi2']="06f15c73029ee676007234ddf4409a6dec8ae9fb"
ImagesSHA1['OSMC']="6e22abb05d7713d5b078ddfa3823293ee28d610f"
ImagesSHA1['OSMCPi2']="e1c40d35e723c9815e4058b44a079921a874e71f"
ImagesSHA1['Pidora']="00f85ca01a6555d4b0843054090c222239898b7c"
ImagesSHA1['RISCOS']="9c28ce57a23692cd70e90cfe9fa24e2014501a05"
#ImagesSHA1['RetroPi']=""
#ImagesSHA1['RetroPi2']=""
ImagesSHA1['MATE']="58565911bef09d95734b2e971833452a50f536a4"
ImagesSHA1['Weather-Station']="9eed5f9f5366faa1f2757c0e7ca81107a81ce249"

# If the list flag has been raised, list the images
if [ $IMAGE_LIST = true ]; then
	echo "Images:"
	for i in "${!Images[@]}"
	do
		echo -e "- $COLOUR_PUR$i$COLOUR_RST"
	done
	exit
fi

#Regex
regexETag="ETag: \"([a-z0-9\-]+)\""
regexSize="Content-Length: ([0-9]+)"
regexLastMod="Last-Modified: ([a-zA-Z0-9\/ :,-]+)"
regexFileName="Content-Disposition: attachment; filename=([a-zA-Z0-9\.-]+)"
regexHTTPCode="HTTP/[0-9].[0-9] ([0-9]+) ([a-zA-Z0-9\. -]+)"

# Check the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Define the image name
IMAGE_NAME="$1"

# Check a image name was specified
if [ "$IMAGE_NAME" = "" ]; then
	echo "Please specify an image name";
	exit
fi

#Determine which image to download
IMAGE_URL="${Images[$IMAGE_NAME]}"

# Check we could find the requested image
if [ "$IMAGE_URL" = "" ]; then
	echo "Could not find an image with the name '$IMAGE_NAME'. Use the --list-images flag for a list.";
	exit
fi

#Get the device to write the image to
DEVICE_PATH="$2"

# Check a device was specified
if [ "$DEVICE_PATH" = "" ]; then
	echo "Please specify a device to write to";
	exit
fi

#Check if the device specified is a block device
if [ ! -b  "$DEVICE_PATH" ]; then
	echo "$DEVICE_PATH: Not a block device"
	exit
fi

#Check if the device is mounted
if [ `mount | grep -c "$DEVICE_PATH"` -gt 0 ]; then
	echo "$DEVICE_PATH: Unmounting all partitions"
	umount "$DEVICE_PATH"*
fi

# Check if the device is still mounted
if [ `mount | grep -c "$DEVICE_PATH"` -gt 0 ]; then
	echo "$DEVICE_PATH: Still mounted"
	exit
fi

echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST Determining if we have the latest version"

#Get the actual download URL of the image
IMAGE_URL=`curl -sIL "$IMAGE_URL" -o /dev/null -w %{url_effective}`

#Get the HTTP headers for the image
IMAGE_HEADERS=`curl -sI "$IMAGE_URL"`

#Get the HTTP response code
[[ $IMAGE_HEADERS =~ $regexHTTPCode ]]
IMAGE_RESPONSE_CODE="${BASH_REMATCH[1]}"
IMAGE_RESPONSE_MSG="${BASH_REMATCH[2]}"

if [ "$IMAGE_RESPONSE_CODE" != 200 ]; then
	echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST Download Error [HTTP $IMAGE_RESPONSE_CODE $IMAGE_RESPONSE_MSG]"
	exit
fi

#Get the date this image was last modified
[[ $IMAGE_HEADERS =~ $regexLastMod ]]
IMAGE_LASTMOD="${BASH_REMATCH[1]}"
IMAGE_LASTMOD=`date --date="$IMAGE_LASTMOD" +%s`

#Get the image size
[[ $IMAGE_HEADERS =~ $regexSize ]]
IMAGE_SIZE="${BASH_REMATCH[1]}"

#Get the image type
[[ $IMAGE_HEADERS =~ $regexType ]]
IMAGE_TYPE="${BASH_REMATCH[1]}"

#Get the image name
[[ $IMAGE_HEADERS =~ $regexFileName ]]
IMAGE_FILENAME="${BASH_REMATCH[1]}"

#Check we could found a file name
if [ "$IMAGE_FILENAME" = "" ]; then
	#default to the requested name
	IMAGE_FILENAME="$IMAGE_NAME"
fi

#Set the image paths
IMAGE_DIR="images/$IMAGE_NAME/$IMAGE_LASTMOD"
IMAGE_FILE="$IMAGE_DIR/$IMAGE_FILENAME"

#Check if we already have this version
if [ ! -f "$IMAGE_FILE" ]; then
	#Make the directory to store the image
	mkdir -p "$IMAGE_DIR"

	echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST Downloading $IMAGE_FILENAME"

	#Download the image
	curl -sL "$IMAGE_URL" | pv -s "$IMAGE_SIZE" -cN "Download" >  "$IMAGE_FILE"
else
	echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST We have the latest version of $IMAGE_FILENAME"
fi

# Check the file was created
if [ ! -f "$IMAGE_FILE" ]; then
	echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST Something went wrong.. The image wasn't downloaded"
	exit
fi

# Check if a SHA1 hash has been defined for this image
IMAGE_HASH="${ImagesSHA1[$IMAGE_NAME]}"

if [ "$IMAGE_HASH" != "" ]; then

	echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST Checking image hash"

	# Hash the downloaded image
	IMAGE_HASH_ACTUAL=$(sha1sum "$IMAGE_FILE" |  grep -Eo "^([^ ]+)")

	# Check the hashes match
	if [ "$IMAGE_HASH" != "$IMAGE_HASH_ACTUAL" ]; then
		echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST Hash mismatch! [$IMAGE_HASH != $IMAGE_HASH_ACTUAL]"
		exit 1;
	else
		echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST Image hash OK [$IMAGE_HASH]"
	fi
fi

#Get the images file type data
IMAGE_TYPE_DATA=`file "$IMAGE_FILE"`

if [[ $IMAGE_TYPE_DATA =~ "Zip archive data" ]]; then

	#Set the archive type
	IMAGE_ARCHIVE_TYPE="ZIP"

	#Set the tool used to decompress this type of archive
	IMAGE_ARCHIVE_TOOL="funzip"

	#Determine the decompressed size of the archive
	REGEX="([0-9]+)[ ]+"
	[[ `unzip -l "$IMAGE_FILE"` =~ $REGEX ]]
	IMAGE_ARCHIVE_SIZE="${BASH_REMATCH[1]}"
fi

if [[ $IMAGE_TYPE_DATA =~ "gzip compressed data" ]]; then

	#Set the archive type
	IMAGE_ARCHIVE_TYPE="GZIP"

	#Set the tool used to decompress this type of archive
	IMAGE_ARCHIVE_TOOL="zcat"

	#Determine the decompressed size of the archive
	REGEX="[ ]+[0-9]+[ ]+([0-9]+)"
	[[ `zcat -l "$IMAGE_FILE"` =~ $REGEX ]]
	IMAGE_ARCHIVE_SIZE="${BASH_REMATCH[1]}"
fi

if [[ $IMAGE_TYPE_DATA =~ "boot sector" ]]; then

	#Set the archive type
	IMAGE_ARCHIVE_TYPE="NONE"

	#Set the tool used to decompress this type of archive
	IMAGE_ARCHIVE_TOOL="NONE"
fi

# Check if were able to determine what type of file the image is
if [[ "$IMAGE_ARCHIVE_TYPE" = "" ]]; then
	echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST Couldn't determine the file type of the image: '$IMAGE_TYPE_DATA'"
	exit
fi

# Check if the image is compressed
if [ "$IMAGE_ARCHIVE_TYPE" = "NONE" ]; then
	# No compression, write straight to disk
	pv -pabeWcN "Writing" "$IMAGE_FILE" | dd bs=4M of="$DEVICE_PATH" conv=fdatasync
else
	echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST The image is compressed"

	# Check if the command to extract the image is avaliable
	command_exists_exit "$IMAGE_ARCHIVE_TOOL"

	# The image is compressed, write it to the disk as we're decompressing it to save time
	pv -pabeWcN "Extracting $IMAGE_ARCHIVE_TYPE" "$IMAGE_FILE" | $IMAGE_ARCHIVE_TOOL | pv -pabeWcN "Writing" -s "$IMAGE_ARCHIVE_SIZE" | dd bs=4M of="$DEVICE_PATH" conv=fdatasync
fi

# Persist any buffers
sync

# Give a complete notice
echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST Image write complete!"
