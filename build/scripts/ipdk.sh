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
# $1 = Base environment name to use
#
install() {
	# create ~/.ipdk directory
	mkdir -p ~/.ipdk

	# add empty ipdk.env file if not already there
	if [ -f "$HOME/.ipdk/ipdk.env" ]; then
		echo "User changable IPDK configuration file is already defined at "
		echo "'~/.ipdk/ipdk.env'."
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

	# change runtime environment if requested
	if [ "$1" != "" ] ; then
		case "$1" in
			default) # change to default environment
				remove_config_line "BASE_IMG" "$HOME/.ipdk/ipdk.env"
				remove_config_line "IMAGE_NAME" "$HOME/.ipdk/ipdk.env"
				remove_config_line "DOCKERFILE" "$HOME/.ipdk/ipdk.env"
				;;
			host) # change to host environment (Vagrant/other VM or bare metal)
				change_config_line "BASE_IMG" "BASE_IMG=host" "$HOME/.ipdk/ipdk.env"
				remove_config_line "IMAGE_NAME" "$HOME/.ipdk/ipdk.env"
				remove_config_line "DOCKERFILE" "$HOME/.ipdk/ipdk.env"
				;;
			*) # Select one of the pre defined container runtime environments
				# shellcheck disable=SC2153 # This is exception because RT_ENVS is sourced!
				local RT_ENV="${RT_ENVS[$1]}"
				if [ "${RT_ENV}" != "" ] ; then 
					IFS="," read -r -a ENV_ATTR <<< "${RT_ENV}"
					change_config_line "BASE_IMG" "BASE_IMG=${ENV_ATTR[0]}" "$HOME/.ipdk/ipdk.env"
					change_config_line "IMAGE_NAME" "IMAGE_NAME=${ENV_ATTR[1]}" "$HOME/.ipdk/ipdk.env"
					change_config_line "DOCKERFILE" "DOCKERFILE=${ENV_ATTR[2]}" "$HOME/.ipdk/ipdk.env"
					change_config_line "DOCKERBUILDDIR" "DOCKERBUILDDIR=${ENV_ATTR[3]}" "$HOME/.ipdk/ipdk.env"
				else
					# The user defined a unknown runtime environment
					echo "Unknown runtime environment reference!" >&2
					exit 1
				fi
				;;
		esac
		echo "Changed runtime environment to: $1"
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
		# create dynamic argument line and start with cache
		local ARGS=()
		if $NO_CACHE ; then
			ARGS+=("--no-cache")
		fi

		# add extra tags
		if [[ "$TAGS" != "" ]] ; then
			IFS="," read -r -a TAG_LIST <<< "${TAGS}"
			for i in "${TAG_LIST[@]}" ; do
				ARGS+=("--tag" "${i}")
			done
		fi

		# add labels
		if [[ "$LABELS" != "" ]] ; then
			IFS="," read -r -a LABEL_LIST <<< "${LABELS}"
			for i in "${LABEL_LIST[@]}" ; do
				ARGS+=("--label" "${i}")
			done
		fi
			
		# add build arguments
		if [[ "$PROXY" != "" ]] ; then
			ARGS+=("--build-arg" "HTTP_PROXY=$PROXY")
			ARGS+=("--build-arg" "HTTPS_PROXY=$PROXY")
		fi
		if $KEEP_SOURCE_CODE ; then
			ARGS+=("--build-arg" "KEEP_SOURCE_CODE=YES")
		else
			ARGS+=("--build-arg" "KEEP_SOURCE_CODE=NO")
		fi
		if $DEPLOYMENT_IMAGE ; then
			ARGS+=("--build-arg" "DEPLOYMENT_IMAGE=YES")
		else
			ARGS+=("--build-arg" "DEPLOYMENT_IMAGE=NO")
		fi
		ARGS+=("--build-arg" "BASE_IMG=$BASE_IMG")

		# create build command
		local BUILDCMD=()
		if check_buildx ; then
			echo "Use docker buildx build!"
			BUILDCMD+=("buildx" "build")

			if [ "$PLATFORM" != "" ] ; then
				BUILDCMD+=("--platform" "$PLATFORM")
				IFS="," read -r -a PLATFORM_LIST <<< "${PLATFORM}"
			else
				local PLATFORM_LIST=()
			fi

			# what to do with created image
			if $PUSH ; then
				# push to registry
				BUILDCMD+=("--push")
			elif [ "$TAR_EXPORT" != "" ] ; then
			  # export to tar file
				BUILDCMD+=("-o" "type=oci,dest=$TAR_EXPORT")
			elif [ ${#PLATFORM_LIST[@]} -le 1 ] ; then
				# push to local docker image store (recreate old docker behavior)
				BUILDCMD+=("--load")
			else
				echo "No '--push' or '--export' and more then one '--platform' requested!" >&2
				echo "This is not supported!" >&2
				exit 1
			fi

		elif [ "$PLATFORM" != "" ] || $PUSH || [ "$TAR_EXPORT" != "" ]; then
			echo "This host doesn't support docker buildx but '--platform', '--push', or '--export' option is requested" >&2
			echo "This is not supported!" >&2
			exit 1
		else
			echo "Use old docker build!" 
			BUILDCMD+=("build")
		fi

		# run image build process
		pushd "${DOCKERBUILDDIR}" || exit
		docker "${BUILDCMD[@]}" -t "${IMAGE_NAME}":"${TAG}" -f "${DOCKERFILE}" "${ARGS[@]}" .
		popd || exit

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

	local RUNCMD=()
	if check_buildx && [ "$PLATFORM" != "" ]; then
		echo "Using docker run --platform"
		RUNCMD+=("run")
		RUNCMD+=("--platform" "$PLATFORM")
	elif [ "$PLATFORM" == "" ]; then
		echo "Using docker run!" 
		RUNCMD+=("run")
	else
		echo "This host doesn't support ipdk start --platform"  >&2
		exit 1
	fi

	if [ "${IPDK_ULIMIT}" ] ; then
		ARGS+=("--ulimit" "memlock=$(( 131072*1024 )):$(( 131072*1024 ))")
	fi

	docker "${RUNCMD[@]}" \
		--name "${CONTAINER_NAME}" \
		--rm \
		--cap-add ALL \
		--privileged \
		-v "${VOLUME}":/tmp \
		-p 9339:9339 \
		-p 9559:9559 \
		"${ARGS[@]}" -it "${IMAGE_NAME}":"${TAG}" "${RUN_COMMAND[@]}"

	if [ "$LINK_NAMESPACE" ] ; then
		IPDK_NAMESPACE=$(docker inspect -f '{{.State.Pid}}' "$CONTAINER_NAME")
		sudo mkdir -p /var/run/netns
		sudo ln -sf "/proc/${IPDK_NAMESPACE}/ns/net" /var/run/netns/switch
	fi
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
	# Remove the namespace link
	if [ "$LINK_NAMESPACE" ] ; then
		sudo rm -f /var/run/netns/switch
	fi

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
# Tag the current working image
# $1 = tag to add to current working image
#
tag_image() {
	local SET_TAG=$1
	docker tag "${IMAGE_NAME}":"${TAG}" "${SET_TAG}"
}

#
# Export the current working image to a tarred+zipped file
# $1 FILENAME
#
export_image() {
	local FILENAME=$1
	docker save "${IMAGE_NAME}":"${TAG}" | gzip > "${FILENAME}"
}

#
# Push current IPDK image to a registry
# $1 = tag of image to push or none to push all set tags of current image
#
push_image() {
	local SET_TAG=$1
	if [ "${SET_TAG}" != "" ] ; then
		tag_image "${SET_TAG}"
		docker push "${SET_TAG}"
	else
		docker push --all-tags "${IMAGE_NAME}"
	fi
}

#
# Run a demo with two VM's connected to a running P4-OVS in host or container
#
run_demo() {
	# TODO Check if P4-OVS is running locally or in IPDK container and depending
	# on that start docker demo or host demo

	# Run P4-eBPF demo if using that image
	if [ "${IMAGE_NAME}" == "ghcr.io/ipdk-io/ipdk-ebpf-ubuntu2004-x86_64" ] ; then
		pushd "${DOCKERBUILDDIR}" || exit
		make start-demo
		popd || exit
	else
		start_docker_demo "$CONTAINER_NAME" "$VOLUME" "$KVM_GRAPHIC"
	fi
}

#
# Stop the demo from running
#
stop_demo() {
	# TODO Stop the P4-OVS demo

	if [ "${IMAGE_NAME}" == "ghcr.io/ipdk-io/ipdk-ebpf-ubuntu2004-x86_64" ] ; then
		pushd "${DOCKERBUILDDIR}" || exit
		make stop-demo
		popd || exit
	fi
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
# change configuration option
# $1 = option to change in '[key]=[value]' representation
#
config() {
	if [ "$1" != "" ] ; then
		IFS='=' read -ra OPTION <<< "$1"
		if [ "${OPTION[1]}" = "" ] ; then
			remove_config_line "${OPTION[0]}" "$HOME/.ipdk/ipdk.env"
		else
			change_config_line "${OPTION[0]}" "$1" "$HOME/.ipdk/ipdk.env"
		fi
	fi
}

#
# Show status
#
status() {
	echo ""

	# docker buildx supported?
	if check_buildx; then
		echo "This host supports docker buildx!"
		docker buildx ls
	else
		echo "This host doesn't support docker buildx!"
	fi
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
	printf '%-12s | %-15s | %-25s | %-30s\n' "RT_ENVS" "BASE_IMAGE" "IMAGE_NAME" "DOCKERFILE";
	echo '-------------------------------------------------------------------------------------------------------------------------' 
	# shellcheck disable=SC2153 # This is exception because RT_ENVS is sourced!
	for RT_ENV in "${!RT_ENVS[@]}" ; do
		IFS="," read -r -a ENV_ATTR <<< "${RT_ENVS[$RT_ENV]}"
		printf '%-12s | %-15s | %-25s | %-30s\n' "$RT_ENV" "${ENV_ATTR[@]}";
	done
	echo ""

	echo "build arguments:"
	echo "NO_CACHE=$NO_CACHE"
	echo "PROXY=$PROXY"
	echo "BASE_IMG=$BASE_IMG"
	echo "IMAGE_NAME=$IMAGE_NAME"
	echo "TAG=$TAG"
	echo "DOCKERFILE=$DOCKERFILE"
	echo "KEEP_SOURCE_CODE=$KEEP_SOURCE_CODE"
	echo "DEPLOYMENT_IMAGE=$DEPLOYMENT_IMAGE"
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
		   install [environment]
		     Create the ~/.ipdk directory and create a blank 'ipdk.env' file.
		     [Environment] can be used to set the environment to work in
		     (value can be: default, host, or available container base image names).
		     See the IPDK documentation for more information.
		   build
		     build the designated container image
		       --no-cache - without using the docker cache
		       --use-proxy
		         use the given proxy as defined in the PROXY environment variable
		       --keep-source-code 
		         keep the source code during build (Default is to remove the source code)
		       --deployment-image
		         keeps libraries and binaries in image required for running the stack
		       --platform <build platforms to use>
		         comma seperated list of platform architecture to build for.
		         'docker buildx build --platform [build platforms to use]' will be executed.
		       --tags
		         comma seperated list of image tags to apply to the build image
		       --labels
		         comma seperated list of image labels to apply to the build image
		       --push
		         push the image to the tags referencing registries
		       --export [filename]
		         export the build image to a tarred file
		   start
		     run P4OVS in a long running IPDK docker container
		       -d - run as daemon
		       -v/--volume - run with given volume path connected to /tmp
		       --name <container_name> 
		         the name to run the IPDK container with
		       --platform <platform to use>
		         platform architecture to run container on.
		         'docker run --platform [platform to use]' will be executed.
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
		   stop-demo
		     stop the IPDK demo
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
		   tag [tag]
		     add tag to the working container image
		   export [filename]
		     export the working container image to a tarred+zipped file
		   push [tag]
		     push the working container image to a registry with tag
		   config [option=value]
		     configure extra option in the user configuration file (~/.ipdk/ipdk.env)
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
		--platform)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				PLATFORM=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		--tags)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				TAGS=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		--labels)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				LABELS=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		--export)
			if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
				TAR_EXPORT=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		--push)
			PUSH=true
			shift
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
		--deployment-image)
			DEPLOYMENT_IMAGE=true
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
		--link-namespace)
			LINK_NAMESPACE=true
			shift
			;;
		--ulimit)
			IPDK_ULIMIT=true
			shift
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
	tag)
		tag_image "${COMMANDS[1]}"
		;;
	export)
		export_image "${COMMANDS[1]}"
		;;
	push)
		push_image "${COMMANDS[1]}"
		;;
	demo)
		run_demo
		;;
	stop-demo)
		stop_demo
		;;
	createvms)
		createvms
		;;
	startvms)
		startvms
		;;
	config)
		config "${COMMANDS[1]}"
		;;
	status)
		status
		;;
	install)
		install "${COMMANDS[1]}"
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
