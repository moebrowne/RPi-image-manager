#!/bin/bash

declare -A Images

Images['Raspbian']="http://downloads.raspberrypi.org/raspbian_latest"
Images['OpenELEC']="http://releases.openelec.tv/OpenELEC-RPi.arm-5.0.8.img.gz"

#Regex
regexETag="ETag: \"([a-z0-9\-]+)\""
regexSize="Content-Length: ([0-9]+)"
regexType="Content-Type: ([a-zA-Z0-9\/-]+)"

#Determine which image to download
IMAGE_NAME="$1"
IMAGE_URL="${Images[$IMAGE_NAME]}"
IMAGE_URL=`curl -sIL "$IMAGE_URL" -o /dev/null -w %{url_effective}`

#Get the HTTP headers for the image
IMAGE_HEADERS=`curl -sI "$IMAGE_URL"`

#Get the ETag
[[ $IMAGE_HEADERS =~ $regexETag ]]
IMAGE_ETAG="${BASH_REMATCH[1]}"

#Get the image size
[[ $IMAGE_HEADERS =~ $regexSize ]]
IMAGE_SIZE="${BASH_REMATCH[1]}"

#Get the image type
[[ $IMAGE_HEADERS =~ $regexType ]]
IMAGE_TYPE="${BASH_REMATCH[1]}"

IMAGE_DIR="images/$IMAGE_NAME/$IMAGE_ETAG"
IMAGE_FILE="$IMAGE_DIR/image.img.zip"

#Check if we already have this version
if [ ! -f $IMAGE_FILE ]; then
	#Make the directory to store the image
	mkdir -p "$IMAGE_DIR"
	
	#Download the image
	curl -sL "$IMAGE_URL" | pv -s "$IMAGE_SIZE" -cN "Download" >  "$IMAGE_FILE"
fi



