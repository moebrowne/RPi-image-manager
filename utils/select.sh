
function selectDistro() {

    local distros # The array of distro names
    local distroSelected # The name of the distro the user selects
    local distroName

    # Add a custom 'distro'
    distros+=("Local File")

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

    local distroName="$1" # Which distro to get the versions for
    local distroVersions # The array of versions available for this distro
    local distroVersion
    local distroVersionSelected

    echo "Select $distroName version:" >&2

    while read -r distroVersion; do
        distroVersion="${distroVersion/images\/$distroName/}"
        distroVersion="${distroVersion///}"
        distroVersions+=("$distroVersion")
    done < <(ls -1d images/"$distroName"/*/)

    select opt in "${distroVersions[@]}"; do
        distroVersionSelected="${distroVersions[$(($REPLY-1))]}"

        if [[ "$distroVersionSelected" = "" ]]; then
            echo "Invalid selection" >&2
        else
            break
        fi
    done

    echo "$distroVersionSelected"
}