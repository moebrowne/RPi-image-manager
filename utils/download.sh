function download() {

    local imageDownloadURL="$1"
    local imageSavePath="$2"

    echo -n "Fetching meta data..."

    #Get the actual download URL of the image
    imageDownloadURL=`curl -sLr 0-0 "$imageDownloadURL" -o /dev/null -w %{url_effective}`

    #Get the HTTP headers for the image
    IMAGE_HEADERS=`curl -sir 0-0 "$imageDownloadURL"`

    #Get the HTTP response code
    [[ $IMAGE_HEADERS =~ $regexHTTPCode ]]
    IMAGE_RESPONSE_CODE="${BASH_REMATCH[1]}"
    IMAGE_RESPONSE_MSG="${BASH_REMATCH[2]}"

    if [ "$IMAGE_RESPONSE_CODE" -gt 300 ]; then
        echo " FAIL"
        echo "Download Error [HTTP $IMAGE_RESPONSE_CODE $IMAGE_RESPONSE_MSG]"
        exit
    else
        echo " OK"
    fi

    #Get the image size
    [[ $IMAGE_HEADERS =~ $regexSize ]]
    IMAGE_SIZE="${BASH_REMATCH[1]}"

    # Download the image
    if [[ ! "$IMAGE_SIZE" -gt 0 ]]; then
        echo "Unable to determine image size"
        curl -s "$imageDownloadURL" | pv -cN "Download" > "$imageSavePath"
    else
        curl -s "$imageDownloadURL" | pv -s "$IMAGE_SIZE" -cN "Download" > "$imageSavePath"
    fi

    # Check the file was created
    if [ ! -f "$imageSavePath" ]; then
        return 1
    fi

    # All okay!
    return 0

}
