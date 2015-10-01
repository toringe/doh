#!/bin/bash
################################################################################
##                                                                            ##
## DigitalOcean Harbormaster                                                  ##
##                                                                            ##
## Automate Tugboat processes to start and stop droplets. This makes it very  ##
## easy to minimize the amount of idle time for your droplets. When you stop  ##
## you droplet, it will halt, then create a snapshot, and finally the droplet ##
## is destroyed.                                                              ##
##                                                                            ##
##                                    Source: https://github.com/toringe/doh  ##
################################################################################

# Define some colors
red=$( tput setaf 1 )
grn=$( tput setaf 2 )
yel=$( tput setaf 3 )
wht=$( tput setaf 6 )
rst=$( tput sgr0 )

print_usage() {
	echo "DigitalOcean Harbormaster v.1"
	echo "Usage: $( basename $0 ) start|stop <name>"
  exit 1
}

# Information message
iout() {
	echo "${wht}INFO${rst} $@"
}

# Error message
eout() { 
	echo "${red}ERROR${rst} $@" >&2 
}

# Warning message
wout() { 
	echo "${yel}WARNING${rst} $@" 
}

# Critical message (will terminate)
cout() { eout $@; exit 1 }

# Set snapshot name
setname() {
	if [ -z "$1" ]; then
		eout "Missing name of snapshot"
		print_usage
	else
		name=$1
	fi
}

# Check if program is installed
installed() {
	hash $1 2>/dev/null || cout "$1 not installed!"
}

# Execution wrapper that exits if non-zero exit code
run() {
	eval $@
	if [ $? -ne 0 ]; then
		cout "Command failed"
	fi
}

# Find image ID of snapshot
setimageid() {
	images=$( tugboat images | grep -i $name )
	regex="id: ([0-9]+)"
	[[ $images =~ $regex ]]
	imgid=${BASH_REMATCH[1]}
}

# Find key ID for this host
setkeyid() {
	key=$( tugboat keys | grep -i $( hostname -s ) )
	regex="id: ([0-9]+)"
	[[ $key =~ $regex ]]
	keyid=${BASH_REMATCH[1]}
	if [ -z "$keyid" ]; then
		cout "No ssh key for this host. Please upload one on digitalocean.com."
	fi
}

# Terminate if droplet already exists
exit_if_exists() {
	tugboat info $name &>/dev/null
	if [ $? -eq 0 ]; then
		cout "$name already exists"
	fi
}

# Restore snapshot
restore() {
	setimageid
	setkeyid
	if [ -z "$imgid" ]; then
		wout "No existing snapshots with this name"	
		read -n 1 -p " > Do you want to create a new [y/N]? " response
		echo
		case $response in
			[yY])
				run tugboat create -k $keyid $name
				newdroplet=true
				;;
			*)
				iout "Ok, bye!"
				exit
		esac
	else
		run tugboat create -i $imgid -k $keyid $name  
	fi
	run tugboat wait $name
	run tugboat info $name
	iout "Waiting for ssh daemon..."
	sleep 5
	if [ "$newdroplet" == true ]; then
		run tugboat ssh -u root $name
	else
		run tugboat destroy_image --confirm $name-snapshot
		run tugboat ssh $name
	fi
}

# Wait for snapshot to be created
snapshot_created() {
	echo -n "Waiting:"
	i=0
	sec=10
	until $( tugboat images | grep -c $name-snapshot > /dev/null ); do
		echo -n .
		if [ $i -gt 10 ]; then
			sec=$(( sec * 2 % 60 + i ))
			i=0
		fi
		sleep $sec 
		((i++))
	done
	echo "${grn}done${rst}"
}

# Require tugboat
installed 'tugboat'

case "$1" in
	start)	
					setname $2
					iout "Trying to restore $name"
					exit_if_exists
					restore $name
					;;
	stop)		
					setname $2
					run tugboat halt $name
					run tugboat wait -s off $name
					run tugboat snapshot $name-snapshot $name
					snapshot_created
					run tugboat destroy --confirm $name
					;;
	*)			print_usage
					;;
esac
