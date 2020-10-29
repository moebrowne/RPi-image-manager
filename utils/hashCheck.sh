
function checkImageHash() {

    local imageFilePath="$1"
    local imageHashFile="$2"

    local algorithm="sha1sum"
    local algorithmName="SHA1"
    local imageHashCompare=$imageHashFile

    if [[ "$imageHashFile" =~ sha256:(.*)\n? ]]; then
      algorithmName="SHA256"
      algorithm="sha256sum"
      imageHashCompare=`echo ${BASH_REMATCH[1]}`
    elif [[ "$imageHashFile" =~ sha1:(.*)\n? ]]; then
      algorithmName="SHA1"
      algorithm="sha1sum"
      imageHashCompare=`echo ${BASH_REMATCH[1]}`
    elif [[ "$imageHashFile" =~ md5:(.*)\n? ]]; then
      algorithmName="MD5"
      algorithm="md5sum"
      imageHashCompare=`echo ${BASH_REMATCH[1]}`
    fi

    # Hash the downloaded image
    local IMAGE_HASH_ACTUAL=$(pv -paeWcN "Checking Hash ($algorithmName)" "$imageFilePath" | $algorithm |  grep -Eo "^([^ ]+)")

    # Check the hashes match
    if [ "$imageHashCompare" != "$IMAGE_HASH_ACTUAL" ]; then
        return 1
    else
        return 0
    fi
}
