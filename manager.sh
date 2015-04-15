#!/bin/bash

echo "-----------------------------------------"
echo "Raspberry Pi Image Manager (RIM)"
echo ""
echo "v0.1"
echo "-----------------------------------------"

declare -A Images

Images['Raspbian']="http://downloads.raspberrypi.org/raspbian_latest"
Images['OpenELEC']="http://releases.openelec.tv/OpenELEC-RPi.arm-5.0.8.img.gz"

#Regex
regexETag="ETag: \"([a-z0-9\-]+)\""
regexSize="Content-Length: ([0-9]+)"
regexLastMod="Last-Modified: ([a-zA-Z0-9\/ :,-]+)"
regexFileName="Content-Disposition: attachment; filename=([a-zA-Z0-9\.-]+)"

#Determine which image to download
IMAGE_NAME="$1"
IMAGE_URL="${Images[$IMAGE_NAME]}"

echo "Determining if we have the latest version of $IMAGE_NAME"

#Get the actual download URL of the image
IMAGE_URL=`curl -sIL "$IMAGE_URL" -o /dev/null -w %{url_effective}`

#Get the HTTP headers for the image
IMAGE_HEADERS=`curl -sI "$IMAGE_URL"`

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

#Set the image paths
IMAGE_DIR="images/$IMAGE_NAME/$IMAGE_LASTMOD"
IMAGE_FILE="$IMAGE_DIR/$IMAGE_FILENAME"

#Check if we already have this version
if [ ! -f "$IMAGE_FILE" ]; then
	#Make the directory to store the image
	mkdir -p "$IMAGE_DIR"

	echo "Downloading $IMAGE_NAME ($IMAGE_FILENAME)"

	#Download the image
	curl -sL "$IMAGE_URL" | pv -s "$IMAGE_SIZE" -cN "Download" >  "$IMAGE_FILE"
else
	echo "We have the latest version $IMAGE_NAME ($IMAGE_FILENAME)"
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

pv -WcN "Extracting" "$IMAGE_FILE" | $IMAGE_ARCHIVE_TOOL | pv -WcN "Writing" -s "$IMAGE_ARCHIVE_SIZE" | dd bs=4M of=/dev/null 2> /dev/null # > "$IMAGE_DIR/image.img"
