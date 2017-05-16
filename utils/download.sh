function download() {

    local IMAGE_URL="$1"

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

    # Return the path to the image file
    IMAGE_FILE_PATH="$IMAGE_FILE"

}
