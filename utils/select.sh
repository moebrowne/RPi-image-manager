
function selectDistro() {

    local distros
    local distroSelected
    local distroName

    # Add a custom 'distro'
    distros+=("Local Image File")

    while read -r distroName; do
        distroName="${distroName/images/}"
        distroName="${distroName///}"
        distros+=("$distroName")
    done < <(ls -1d images/*/)

    echo "Select distro: " >&2

    select opt in "${distros[@]}"; do
        distroSelected="${distros[$(($REPLY-1))]}"

        if [[ "$distroSelected" = "" ]]; then
            echo "Invalid selection" >&2
        else
            break
        fi
    done

    echo "$distroSelected"
}

function selectDistroVersion() {

    local distroSelected="$1"
    local distroVersionName
    local distroVersions

    echo "Select $distroSelected version:" >&2

    while read -r distroVersionName; do
        distroVersionName="${distroVersionName/images\/$distroSelected/}"
        distroVersionName="${distroVersionName///}"
        distroVersions+=("$distroVersionName")
    done < <(ls -1d images/"$distroSelected"/*/)

    select opt in "${distroVersions[@]}"; do
        distroVersionSelected="${distroVersions[$(($REPLY-1))]}"

        if [[ "$distroVersionSelected" = "" ]]; then
            echo "Invalid selection" >&2
        else
            selectedPath="images/$distroSelected/$distroVersionSelected/"
            break
        fi
    done

    echo "$selectedPath"
}