command_exists () {
    if [ `which "$1"` ]; then
    	return 0
	else
		return 1
	fi
}

command_exists_exit () {
	if ! command_exists $1; then
		echo "ERROR: $1 can't be found"
		exit
	fi
}
