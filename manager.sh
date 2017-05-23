#!/bin/bash

# Get the source directory
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Set the library root path
LIBRARY_PATH_ROOT="$DIR/utils"

# Include the generic libraries
. "$LIBRARY_PATH_ROOT/generic.sh"
. "$LIBRARY_PATH_ROOT/colours.sh"
. "$LIBRARY_PATH_ROOT/download.sh"
. "$LIBRARY_PATH_ROOT/select.sh"
. "$LIBRARY_PATH_ROOT/hashCheck.sh"

#Regex
regexHTTPCode="HTTP/[0-9].[0-9] ([0-9]+) ([a-zA-Z0-9\. -]+)"
regexSize="Content-Range: bytes [0-9]+-[0-9]+/([0-9]+)"

# Check the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Get the device to write the image to
echo "Where do you want to write the image?"

while read -ep "Path: " devicePath; do
    # Check a device was specified
    if [ "$devicePath" = "" ]; then
        echo "Please specify a device path to write to";
        continue
    fi

    # Check if the device specified is a block device
    if [ ! -b  "$devicePath" ]; then
        echo "The specified path is not a block device"
        continue
    fi

    DEVICE_PATH="$devicePath"
    break
done

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

distroSelected=$(selectDistro)

if [[ "$distroSelected" == "Local File" ]]; then

    # Get the local path to the image file
    echo "Where is the image file located?"

    while read -ep "Path: " imageFilePath; do

        # Check a file was specified
        if [ ! -f "$imageFilePath" ]; then
            echo "Selected path doesn't appear to be a file";
            continue
        fi
        break
    done
else
    distroVersionSelected="$(selectDistroVersion "$distroSelected")"
    imageMetaPath="images/$distroSelected/$distroVersionSelected"
    imageCacheDir="$imageMetaPath/cache"
    imageFilePath="$imageCacheDir/image"

    # Check the cache directory exists
    if [[ ! -d "$imageCacheDir" ]]; then
        mkdir "$imageCacheDir"
    fi

    # Check if the image we want is already cached
    if [ ! -f "$imageFilePath" ]; then
        # Download the image
        download $(<"$imageMetaPath/URL") "$imageFilePath"
    fi

    if [[ $? == 1 ]]; then
        echo "Download failed"
        exit 1
    fi

    checkImageHash "$imageFilePath" $(<"$imageMetaPath/hash")

    if [[ $? == 1 ]]; then
        echo "Hash Mismatch"
        exit 1
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
	echo "Couldn't determine the file type of the image: '$IMAGE_TYPE_DATA'"
	exit
fi

# Check if the image is compressed
if [ "$IMAGE_ARCHIVE_TYPE" = "NONE" ]; then
	# No compression, write straight to disk
	pv -pabeWcN "Writing" "$IMAGE_FILE" | dd bs=4M of="$DEVICE_PATH" conv=fdatasync
else
	echo "The image is compressed"

	# Check if the command to extract the image is available
	command_exists_exit "$IMAGE_ARCHIVE_TOOL"

	# The image is compressed, write it to the disk as we're decompressing it to save time
	pv -pabeWcN "Extracting $IMAGE_ARCHIVE_TYPE" "$IMAGE_FILE" | $IMAGE_ARCHIVE_TOOL | pv -pabeWcN "Writing" -s "$IMAGE_ARCHIVE_SIZE" | dd bs=4M of="$DEVICE_PATH" conv=fdatasync
fi

# Persist any buffers
sync

# Give a complete notice
echo "Image write complete!"
