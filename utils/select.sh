
function selectDistro() {
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
}

function selectDistroVersion() {
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
}