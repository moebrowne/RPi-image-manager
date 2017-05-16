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

while read -r distroName; do
    distroName="${distroName/images/}"
    distroName="${distroName///}"
    distros+=("$distroName")
done < <(ls -1d images/*/)

echo "Select distro: "

select opt in "${distros[@]}"; do
    distroSelected="${distros[$(($REPLY-1))]}"

    if [[ "$distroSelected" = "" ]]; then
        echo "Invalid selection"
    else
        break
    fi
done

echo "Select $distroSelected version:"

while read -r distroVersionName; do
    distroVersionName="${distroVersionName/images\/$distroSelected/}"
    distroVersionName="${distroVersionName///}"
    distroVersions+=("$distroVersionName")
done < <(ls -1d images/"$distroSelected"/*/)

select opt in "${distroVersions[@]}"; do
    distroVersionSelected="${distroVersions[$(($REPLY-1))]}"

    if [[ "$distroVersionSelected" = "" ]]; then
        echo "Invalid selection"
    else
        selectedPath="images/$distroSelected/$distroVersionSelected/"
        break
    fi
done

# Get the path to download the image
IMAGE_URL=$(<"$selectedPath/URL")

# Check we could find the requested image
if [ "$IMAGE_URL" = "" ]; then
	echo "ERROR: Image download path empty?!";
	exit
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

CLI_PREFIX="$COLOUR_PUR$distroSelected ($distroVersionSelected):$COLOUR_RST"

echo -en "$CLI_PREFIX Fetching meta data..."

#Get the actual download URL of the image
IMAGE_URL=`curl -sIL "$IMAGE_URL" -o /dev/null -w %{url_effective}`

#Get the HTTP headers for the image
IMAGE_HEADERS=`curl -sI "$IMAGE_URL"`

#Get the HTTP response code
[[ $IMAGE_HEADERS =~ $regexHTTPCode ]]
IMAGE_RESPONSE_CODE="${BASH_REMATCH[1]}"
IMAGE_RESPONSE_MSG="${BASH_REMATCH[2]}"

if [ "$IMAGE_RESPONSE_CODE" != 200 ]; then
    echo " FAIL"
	echo -e "$CLI_PREFIX Download Error [HTTP $IMAGE_RESPONSE_CODE $IMAGE_RESPONSE_MSG]"
	exit
else
    echo " OK"
fi

#Get the image size
[[ $IMAGE_HEADERS =~ $regexSize ]]
IMAGE_SIZE="${BASH_REMATCH[1]}"

#Get the image name
[[ $IMAGE_HEADERS =~ $regexFileName ]]
IMAGE_FILENAME="${BASH_REMATCH[1]}"

# Check we could determine the image file name
if [ "$IMAGE_FILENAME" = "" ]; then
	# Default to a generic  name
	IMAGE_FILENAME="image"
fi

#Set the image paths
IMAGE_CACHE_DIR="$selectedPath/cache"
IMAGE_FILE="$IMAGE_CACHE_DIR/$IMAGE_FILENAME"

#Check if we already have this version
if [ ! -f "$IMAGE_FILE" ]; then
	#Make the directory to store the image
	mkdir -p "$IMAGE_CACHE_DIR"

	echo -e "$CLI_PREFIX Downloading image..."

	#Download the image
	curl -sL "$IMAGE_URL" | pv -s "$IMAGE_SIZE" -cN "Download" >  "$IMAGE_FILE"
else
	echo -e "$CLI_PREFIX Using cache"
fi

# Check the file was created
if [ ! -f "$IMAGE_FILE" ]; then
	echo -e "$CLI_PREFIX Something went wrong.. The image wasn't downloaded"
	exit
fi

# Check if a SHA1 hash has been defined for this image
IMAGE_HASH="$(<"$selectedPath/hash")"

if [ "$IMAGE_HASH" != "" ]; then

	# Hash the downloaded image
	IMAGE_HASH_ACTUAL=$(pv -paeWcN "Checking Hash (SHA1)" "$IMAGE_FILE" | sha1sum |  grep -Eo "^([^ ]+)")

	# Check the hashes match
	if [ "$IMAGE_HASH" != "$IMAGE_HASH_ACTUAL" ]; then
		echo -e "$CLI_PREFIX Hashes mismatch! [$IMAGE_HASH != $IMAGE_HASH_ACTUAL]"
		exit 1
	else
		echo -e "$CLI_PREFIX Hash OK"
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
	echo -e "$CLI_PREFIX Couldn't determine the file type of the image: '$IMAGE_TYPE_DATA'"
	exit
fi

# Check if the image is compressed
if [ "$IMAGE_ARCHIVE_TYPE" = "NONE" ]; then
	# No compression, write straight to disk
	pv -pabeWcN "Writing" "$IMAGE_FILE" | dd bs=4M of="$DEVICE_PATH" conv=fdatasync
else
	echo -e "$CLI_PREFIX The image is compressed"

	# Check if the command to extract the image is avaliable
	command_exists_exit "$IMAGE_ARCHIVE_TOOL"

	# The image is compressed, write it to the disk as we're decompressing it to save time
	pv -pabeWcN "Extracting $IMAGE_ARCHIVE_TYPE" "$IMAGE_FILE" | $IMAGE_ARCHIVE_TOOL | pv -pabeWcN "Writing" -s "$IMAGE_ARCHIVE_SIZE" | dd bs=4M of="$DEVICE_PATH" conv=fdatasync
fi

# Persist any buffers
sync

# Give a complete notice
echo -e "$CLI_PREFIX Image write complete!"
