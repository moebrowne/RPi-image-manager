
function checkImageHash() {

    local imageFilePath="$1"
    local imageHashCompare="$2"

    # Hash the downloaded image
    local IMAGE_HASH_ACTUAL=$(pv -paeWcN "Checking Hash (SHA1)" "$imageFilePath" | sha1sum |  grep -Eo "^([^ ]+)")

    # Check the hashes match
    if [ "$imageHashCompare" != "$IMAGE_HASH_ACTUAL" ]; then
        return 1
    else
        return 0
    fi
}