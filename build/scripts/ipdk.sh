#!/bin/bash
# Copyright (C) 2022 Sander Tolsma
# SPDX-License-Identifier: Apache-2.0

# Initialize the environment of this script
initialize() {
	# Get the current directory location of this file
	SOURCE=${BASH_SOURCE[0]}
	while [ -h "$SOURCE" ]; do 
		# resolve $SOURCE until the file is no longer a symlink
		SCRIPT_DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
		SOURCE=$(readlink "$SOURCE")
		[[ $SOURCE != /* ]] && SOURCE=$SCRIPT_DIR/$SOURCE # if $SOURCE was a
		#relative symlink, we need to resolve it relative to the path where the
		# symlink file was located
	done
	SCRIPT_DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

	# Import default repository settings
	[ -f "$SCRIPT_DIR/ipdk_default.env" ] && {
		# shellcheck source=/dev/null
		. "$SCRIPT_DIR/ipdk_default.env"
		echo "Loaded $SCRIPT_DIR/ipdk_default.env"
	}

	# Import user specific settings
	[ -f "$HOME/.ipdk/ipdk.env" ] && {
		# shellcheck source=/dev/null
		. "$HOME/.ipdk/ipdk.env"
		echo "Loaded $HOME/.ipdk/ipdk.env"
	}

	# Import function library
	[ ! -f "$SCRIPT_DIR/ipdk-lib.sh" ] && {
		echo "ipdk-lib.sh script library could not be found!" >&2 
		exit 1
	}
	# shellcheck source=/dev/null
	. "$SCRIPT_DIR/ipdk-lib.sh"
}

#
# Perform ipdk installation tasks like adding scripts to path and creating 
# user ipdk.env configuration file
#
install() {
	# create ~/.ipdk directory
	mkdir -p ~/.ipdk

	# add empty ipdk.env file if not already there
	if [ -f "$HOME/.ipdk/ipdk.env" ]; then
		echo "User changable IPDK configuration file is already defined at "
		echo "'~/.ipdk/ipdk.env'. Remove this file when new install is required!"
	else
		cat <<- EOF >> "$HOME"/.ipdk/ipdk.env
			# 
			# IPDK CLI configuration file
			# See for more information https://github.com/ipdk-io/ipdk/blob/main/build/IPDK_Container/README_DOCKER.md#CLI-configuration-settings
			#
			# $SCRIPT_DIR contains the location of the 'sourcing' ipdk script when read.
			#
			EOF
	fi

	# Install a symlink in $HOME/.local/bin, $HOME/bin if in PATH
	local DEST_LINK=""
	# shellcheck disable=SC2076 # This is exception because want literally search!
	if [[ "$PATH" =~ "$HOME/.local/bin:" ]] ; then
		DEST_LINK="$HOME/.local/bin"
	elif [[ "$PATH" =~ "$HOME/bin:" ]] ; then
		DEST_LINK="$HOME/bin"
	fi

	if [ "$DEST_LINK" != "" ] ; then
		# create or update symlink
		mkdir -p "${DEST_LINK}"
		ln -sf "$SCRIPT_DIR/ipdk.sh" "$DEST_LINK/ipdk"
		echo "IPDK CLI is installed!"
	else
		# Show manual path message
	  # TODO add to .bashrc for new terminals and restarted systems ???
		local EXECUTE_DIR 
		EXECUTE_DIR=$(dirname "$SCRIPT_DIR")
		echo ""
		echo "As last step execute:"
		echo "  export PATH=${EXECUTE_DIR}:\$PATH"
		echo "to add the IPDK CLI to your path in the running environment!"
	fi
}

#
# Build the docker image
#
build_image() {
	pushd "${SCRIPT_DIR}/.." || exit
		# build dynamic argument line
		local ARGS=()
		if $NO_CACHE ; then
			ARGS+=("--no-cache")
		fi
		if [[ "$PROXY" != "" ]] ; then
			ARGS+=("--build-arg" "HTTP_PROXY=$PROXY")
			ARGS+=("--build-arg" "HTTPS_PROXY=$PROXY")
		fi
		if $KEEP_SOURCE_CODE ; then
			ARGS+=("--build-arg" "KEEP_SOURCE_CODE=YES")
		else
			ARGS+=("--build-arg" "KEEP_SOURCE_CODE=NO")
		fi
		ARGS+=("--build-arg" "BASE_IMG=$BASE_IMG")
		ARGS+=("--build-arg" "OS_VERSION=$OS_VERSION")

		# run image build process
		docker build -t "${IMAGE_NAME}":"${TAG}" -f "${DOCKERFILE}" "${ARGS[@]}" .
	popd || exit
}

#
# Start the P4-OVS container with local volume
#
start_container() {
	# Check if container is already running
	if [ "$(docker ps -q -f name="${CONTAINER_NAME}")" ]; then
		echo "Container with name:$CONTAINER_NAME is already started" >&2
		exit 1
	fi

	# Not running but does it exist? then remove
	if [ "$(docker ps -aq -f status=exited -f name="$CONTAINER_NAME")" ]; then
		docker rm "$CONTAINER_NAME"
	fi

	# clear interfaces and logs
	rm -rf "${VOLUME}"/logs
	rm -rf "${VOLUME}"/intf
	mkdir -p "${VOLUME}"/logs
	mkdir -p "${VOLUME}"/intf

	# what to startup?
	local RUN_COMMAND=()
	local ARGS=()
	if $AS_DAEMON ; then
		# run as daemon setup
		ARGS+=("-d")
		ARGS+=("--entrypoint" "/root/scripts/start.sh")
		RUN_COMMAND+=("rundaemon")
	else
		# run to commandline after setting environment vars
		ARGS+=("--entrypoint" "/bin/bash")
		RUN_COMMAND+=("--rcfile" "/root/scripts/start.sh")
	fi

	docker run \
		--name "${CONTAINER_NAME}" \
		--rm \
		--cap-add ALL \
		--privileged \
		-v "${VOLUME}":/tmp \
		-p 9339:9339 \
		-p 9559:9559 \
		"${ARGS[@]}" -it "${IMAGE_NAME}":"${TAG}" "${RUN_COMMAND[@]}"
}

#
# Connect to the P4-OVS running container daemon
#
connect() {
	WORKING_DIR="/root/scripts"
	if [[ ${COMMANDS[1]} != "" ]] ; then
		WORKING_DIR=${COMMANDS[1]}
	fi

	docker_connect "${CONTAINER_NAME}" "${WORKING_DIR}"
}

#
# Execute command on running container daemon
#
execute() {
	WORKING_DIR="/root/scripts"
	if [[ ${COMMANDS[1]} != "" ]] ; then
		WORKING_DIR=${COMMANDS[1]}
	fi

	docker_execute "${CONTAINER_NAME}" "${WORKING_DIR}" "${@}"
}

#
# Show the log file of the container
#
log_container() {
	docker logs "${CONTAINER_NAME}"
}

#
# Stop the running P4-OVS container
#
stop_container() {
	docker stop "${CONTAINER_NAME}"
	rm -rf "${VOLUME}"/intf
}

#
# Remove existing container
#
rm_container() {
	stop_container 
	docker rm "${CONTAINER_NAME}"
	rm -rf "${VOLUME}"/logs
}

#
# Push IPDK image to registry
#
push_image() {
	docker push "${IMAGE_NAME}":"${TAG}"
}

#
# Run a demo with two VM's connected to a running P4-OVS in host or container
#
run_demo() {
	# TODO Check if P4-OVS is running locally or in IPDK container and depending
	# on that start docker demo or host demo

	start_docker_demo "$CONTAINER_NAME" "$VOLUME" "$KVM_GRAPHIC"
}

#
# create two demo VM images as seperate step
#
createvms() {
	local IMAGE_LOCATION="$VOLUME/images"
	create_images "$IMAGE_LOCATION"
}

#
# start created VMs as seperate step
#
startvms() {
	local KVM_ARGS=()
	if ! $KVM_GRAPHIC ; then
		KVM_ARGS+=("-nographic")
	fi
	start_vms "$VOLUME/images" "$VOLUME/intf" "${KVM_ARGS[@]}"
}

#
# Show status
#
status() {
	echo ""

	# Container running?
	if [ "$(docker ps -q -f name="${CONTAINER_NAME}")" ]; then
		echo "Container with name:$CONTAINER_NAME is started"
	else
		echo "Container with name:$CONTAINER_NAME is not started"
	fi
	echo ""

	# show long status ?
	if [ "${COMMANDS[1]}" != "long" ] ; then
		exit
	fi

	echo "Commands:"
	for i in "${!COMMANDS[@]}"; do
		echo "Command $i is ${COMMANDS[$i]}"
	done
	echo ""

	echo "generic variables:"
	echo "PWD=$PWD"
	echo "SCRIPT_DIR=$SCRIPT_DIR"
	echo ""

	echo "build arguments:"
	echo "NO_CACHE=$NO_CACHE"
	echo "PROXY=$PROXY"
	echo "OS_VERSION=$OS_VERSION"
	echo "IMAGE_NAME=$IMAGE_NAME"
	echo "TAG=$TAG"
	echo "DOCKERFILE=$DOCKERFILE"
	echo "KEEP_SOURCE_CODE=$KEEP_SOURCE_CODE"
	echo ""

	echo "start arguments:"
	echo "AS_DAEMON=$AS_DAEMON"
	echo "CONTAINER_NAME=$CONTAINER_NAME"
	echo "VOLUME=$VOLUME"
	echo ""

	echo "addintf arguments:"
	echo "NAME=$NAME"
	echo "HOST=$HOST"
	echo "TYPE=$TYPE"
	echo "SOCKET=$SOCKET"
}

#
# Show help text
#
help() {
	cat <<- EOF
		
		Generic options:
		  -e/--env  Point to environment file to use on top of default
		    'ipdk_default.env' & '~/.ipdk/ipdk.env'
		 
		Available commands are:
		   install
		     Create the ~/.ipdk directory and create a blank 'ipdk.env' file.
		   build
		     build the designated container image
		       --no-cache - without using the docker cache
		       --use-proxy
		         use the given proxy as defined in the PROXY environment variable
		       --keep-source-code 
		         keep the source code during build (Default is to remove the source code)
		   start
		     run P4OVS in a long running IPDK docker container
		       -d - run as daemon
		       -v/--volume - run with given volume path connected to /tmp
		       --name <container_name> 
		         the name to run the IPDK container with
		   connect [working dir]
		     start a commandline in the running IPDK container
		       --name <container_name> 
		         the name of the container
		   execute [working dir] ---
		     run a command depicted after --- in the running IPDK container
		       --name <container_name> 
		         the name of the IPDK container
		   demo
		     run the IPDK VM traffic switching demo
		       --graphic - start KVM VMs with X-Window
		       --name <container_name> 
		         the name of the IPDK container
		   createvms
		     create two demo KVM VMs
		   startvms
		     start the two KVM VMs
		       --graphic - start KVM VMs with X-Window
		   addintf
		     add a interface (name, host, port type, socket name)
		       -i/--ifname - name of the interface 
		       -h/--host - host to put the interface in
		       -t/--type - type of the interface: LINK / TAP
		       -s/--socket
		         name of the virtio-host socket put in $VOLUME/intf directory
		       --name <container_name> 
		         the name of the IPDK container
		   log
		     show the log of the running or stopped IPDK container
		   stop
		     stop the long running IPDK container
		   rm
		     stop and remove the long running IPDK container
		   status [long]
		     show the current status of the IPDK environment
		     long shows all global variables
		   help
		     this help text
		EOF
}

# ==============================================================================
# Start of IPDK script execution
# ==============================================================================

# load the environment to run in
initialize

# process the command line
COMMANDS=()
OPTION_POSITION=1
while (( "$#" )); do
	case "$1" in
		-e|--env)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ] && ((OPTION_POSITION == 1)) ; then
				DEFAULT_ENV=$2
				# Import commandline specific settings
				[ -f "$DEFAULT_ENV" ] && {
					# shellcheck source=/dev/null
					source "$DEFAULT_ENV"
					echo "Loaded $DEFAULT_ENV"
				}
				shift 2
			else
				echo "Error: $1 is not the first option or argument is missing!" >&2
				exit 1
			fi
			;;
		--no-cache)
			NO_CACHE=true
			shift
			;;
		--use-proxy)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				PROXY=$2
				shift
			fi
			shift
			if [[ "$PROXY" = "" ]] ; then
				echo "Error: no proxy endpoint defined in option or PROXY environment variable!" >&2
				exit 1
			fi
			;;
		-k|--keep-source-code)
			KEEP_SOURCE_CODE=true
			shift
			;;
		--tag)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				TAG=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		--name)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				CONTAINER_NAME=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		-d)
			AS_DAEMON=true
			shift
			;;
		-v|--volume)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				VOLUME=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		--graphic)
			KVM_GRAPHIC=true
			shift
			;;
		-i|--ifname)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				NAME=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		-h|--host)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				HOST=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		-t|--type)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				TYPE=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		-s|--socket)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				SOCKET=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		--help)
			help
			exit
			;;
		---) # extra arguments separator for other use 
			shift
			break
			;;
		-*) # unsupported flags
			echo "Error: Unsupported flag $1" >&2
			exit 1
			;;
		*) # preserve positional arguments
			COMMANDS+=("$1")
			((OPTION_POSITION-=1))
			shift
			;;
	esac
	((OPTION_POSITION+=1))
done 

# set the command to execute
COMMAND="help"
if [[ ${COMMANDS[0]} != "" ]] ; then
	COMMAND=${COMMANDS[0]}
fi

case $COMMAND in
	build)
		build_image
		;;
	start)
		start_container
		;;
	connect)
		connect
		;;
	execute)
		execute "${@}"
		;;
	log)
		log_container
		;;
	stop)
		stop_container
		;;
	rm)
		rm_container
		;;
	push)
		push_image
		;;
	demo)
		run_demo
		;;
	createvms)
		createvms
		;;
	startvms)
		startvms
		;;
	status)
		status
		;;
	install)
		install
		;;
	help)
		help
		;;
	*)
		echo ""
		echo "Unknown command $COMMAND" >&2
		echo ""
		help
		exit 1
		;;
esac
