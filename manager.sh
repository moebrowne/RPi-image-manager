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

#Determine the right tool to decompress the archive with by matching the file extension
case "$IMAGE_FILENAME" in
  *.zip		)	IMAGE_DECOMP_WITH="unzip -qq -c" ;;
  *.tar.gz	)	IMAGE_DECOMP_WITH="tar -zxvf" ;;
  *.gz		)	IMAGE_DECOMP_WITH="gzip -d" ;;
  *.tar.bz2	)	IMAGE_DECOMP_WITH="tar -jxvf" ;;
  *.bz2		)	IMAGE_DECOMP_WITH="bzip2 -dk" ;;
  *			)	echo "UNKNOWN FILE TYPE '$IMAGE_FILENAME'"; exit
esac

$IMAGE_DECOMP_WITH "$IMAGE_FILE" | pv -cN "Extracting" > "$IMAGE_DIR/image.img"
