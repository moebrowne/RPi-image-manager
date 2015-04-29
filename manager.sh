#!/bin/bash

echo "-----------------------------------------"
echo "  Raspberry Pi Image Manager (RIM) v0.3"
echo "-----------------------------------------"

# Get the source directory
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Set the library root path
LIBRARY_PATH_ROOT="$DIR/utils"

# Include the generic libraries
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

Images['Raspbian']="http://downloads.raspberrypi.org/raspbian_latest"
Images['Snappy']="http://downloads.raspberrypi.org/ubuntu_latest"
Images['OpenELEC']="http://releases.openelec.tv/OpenELEC-RPi.arm-5.0.8.img.gz"
Images['RaspBMC']="http://edge.samnazarko.co.uk/raspbmc/raspbmc-final-25032015.img.gz"
Images['Pidora']="http://pidora.ca/pidora/releases/20/images/Pidora-2014-R3.zip"
Images['RISCOS']="https://www.riscosopen.org/zipfiles/platform/raspberry-pi/riscos-2015-02-17.14.zip"
Images['RetroPi2']="http://downloads.petrockblock.com/images/retropie-v2.6.0-rpi2.img.gz"
Images['RetroPi']="http://downloads.petrockblock.com/images/retropie-v2.6.0-rpi1.img.gz"

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
	echo "Could not find an image with the name '$IMAGE_NAME'";
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

# Check if the image is compressed
if [ "$IMAGE_ARCHIVE_TYPE" = "NONE" ]; then
	# No compression, write straight to disk
	pv -pabeWcN "Writing" "$IMAGE_FILE" | dd bs=4M of="$DEVICE_PATH" conv=fdatasync
else
	# The image is compressed, write it to the disk as we're decompressing it to save time
	pv -pabeWcN "Extracting" "$IMAGE_FILE" | $IMAGE_ARCHIVE_TOOL | pv -pabeWcN "Writing" -s "$IMAGE_ARCHIVE_SIZE" | dd bs=4M of="$DEVICE_PATH" conv=fdatasync
fi

# Persist any buffers
sync

# Give a complete notice
echo -e "$COLOUR_PUR$IMAGE_NAME:$COLOUR_RST Image write complete!"
