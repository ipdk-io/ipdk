#!/bin/bash
# Copyright (C) 2022 Sander Tolsma
# SPDX-License-Identifier: Apache-2.0

# 
# Print a banner with red color
#
print_banner() {
	local RED='\033[0;31m'
	local NC='\033[0m' # No Color
	echo ""
	echo -e "${RED}${1}${NC}"
	echo ""
}


function version() {
	printf '%02d' "$(echo "$1" | tr . ' ' | sed -e 's/ 0*/ /g')" 2>/dev/null
}

#
# Check if docker buildx is usable
#
function check_buildx() {
	if ! command -v docker >/dev/null 2>&1; then
		echo "Can't find docker. Install first!!" >&2
		return 1
	fi

	docker_version="$(docker version --format '{{.Server.Version}}')"
	if [[ "$(version "$docker_version")" < "$(version '19.03')" ]]; then
		echo "docker $docker_version too old. Need >= 19.03"
		return 1
	fi

	docker_experimental="$(docker version --format='{{.Server.Experimental}}')"
	if [[ "$docker_experimental" != 'true' ]]; then
		export DOCKER_CLI_EXPERIMENTAL=enabled
	fi

	kernel_version="$(uname -r)"
	if [[ "$(version "$kernel_version")" < "$(version '4.8')" ]]; then
		echo "Kernel $kernel_version too old, need >= 4.8 to build with --platform." >&2
		return 1
	fi

	if [[ "$(mount | grep -c '/proc/sys/fs/binfmt_misc')" == '0' ]]; then
		echo "/proc/sys/fs/binfmt_misc not mounted." >&2
		return 1
	fi

	distro=$(grep "^ID=" < /etc/os-release | cut -d= -f2)
	if [[ "$distro" = "fedora" ]]; then
		if ! systemctl is-active --quiet systemd-binfmt ; then
			echo "Service systemd-binfmt is not started"
			return 1
		fi
	elif [[ "$distro" = "ubuntu" ]]; then
		if ! command -v update-binfmts >/dev/null 2>&1; then
			echo "Can't find update-binfmts." >&2
			return 1
		fi

		binfmt_version="$(update-binfmts --version | awk '{print $NF}')"
		if [[ "$(version "$binfmt_version")" < "$(version '2.1.7')" ]]; then
			echo "update-binfmts $binfmt_version too old. Need >= 2.1.7" >&2
			return 1
		fi
	fi

	if [[ ! -e '/proc/sys/fs/binfmt_misc/qemu-aarch64' ]]; then
		# Skip this test if QEMU isn't registered with binfmt_misc. It might
		# come from a docker image rather than the host file system.
		if [[ ! -e '/usr/bin/qemu-aarch64-static' ]]; then
			echo "Missing QEMU."  >&2
			return 1
		fi
	fi
	if [[ ! -e '/proc/sys/fs/binfmt_misc/qemu-aarch64' ]]; then
		echo "QEMU not registered in binfmt_misc." >&2
		return 1
	fi
	flags="$(grep 'flags:' /proc/sys/fs/binfmt_misc/qemu-aarch64 | cut -d' ' -f2)"
	if [[ "$(echo "$flags" | grep -c F)" == '0' ]]; then
		echo "QEMU not registered in binfmt_misc with fix-binary (F) flag." >&2
		return 1
	fi
}

#
# Replace configuration line with new line and if not exist add
# $1 = SEARCH_FOR
# $2 = NEW_LINE
# $3 = FILE - filepath to replace/add line in/to
#
change_config_line() {
	local SEARCH_FOR=$1; shift
	local NEW_LINE=$1; shift
	local FILE=$1
	local NEW

	# escape correctly for use in sed
	NEW=$(echo "${NEW_LINE}" | sed 's/\//\\\//g')
	# create file if not exist...
	touch "${FILE}"
	# shellcheck disable=SC2016 # Errored part needs to be between single quotes
	sed -i '/'"${SEARCH_FOR}"'/{s/.*/'"${NEW}"'/;h};${x;/./{x;q100};x}' "${FILE}"
	if [[ $? -ne 100 ]] && [[ ${NEW_LINE} != '' ]]
	then
		echo "${NEW_LINE}" >> "${FILE}"
	fi
}

#
# Remove configuration line if exist
# $1 = SEARCH_FOR
# $3 = FILE - filepath to remove from
#
remove_config_line() {
	local SEARCH_FOR=$1; shift
	local FILE=$1

	sed -i '/'"${SEARCH_FOR}"'/d' "${FILE}"
}

# 
# Get latest ubuntu cloud image from distribution server
# $1 = RELEASE
# $2 = IMAGE_LOCATION
#
get_distro_image() {
	# Inspired by this gist:
	# https://gist.github.com/smoser/635897f845f7cb56c0a7ac3018a4f476
	local RELEASE=$1
	local IMAGE_LOCATION=$2
	local BASE_URL="https://cloud-images.ubuntu.com/daily/server"
	local ORIGIN_FNAME="$RELEASE-server-cloudimg-amd64.img"
	local DEST_FNAME="$IMAGE_LOCATION/$ORIGIN_FNAME"

	# trusty and xenial have a '-disk1.img' while
	# other releases have just 'disk.img'
	case "$RELEASE" in
		precise|trusty|xenial) ORIGIN_FNAME="$RELEASE-server-cloudimg-amd64-disk1.img";;
	esac

	# download file to given destination if not already there
	if [ ! -f "$DEST_FNAME" ]; then
		local URL="$BASE_URL/$RELEASE/current/$ORIGIN_FNAME"
		echo "downloading $URL to $DEST_FNAME"
		wget -nc "$URL" -O "$DEST_FNAME.tmp" &&
			mv "$DEST_FNAME.tmp" "$DEST_FNAME" || exit
	fi
}

#
# Create two pre configured QEMU/KVM images on given location
# $1 = IMAGE_LOCATION
#
create_images() {
	# input arguments
	local IMAGE_LOCATION=$1
	local DIST_FNAME="focal-server-cloudimg-amd64.img"

	print_banner "Get Ubuntu focal base image"

	mkdir -p "${IMAGE_LOCATION}"
	get_distro_image focal "${IMAGE_LOCATION}"
	echo "Distribution image: $DIST_FNAME"

	print_banner "Create requested VM images"

	# remove old vm distribution images and seed images
	rm -f "$IMAGE_LOCATION/"vm*.qcow2
	rm -f "$IMAGE_LOCATION/"seed*.img

	# create new vm distribution images
	cp "$IMAGE_LOCATION/$DIST_FNAME" "$IMAGE_LOCATION/vm1.qcow2"
	cp "$IMAGE_LOCATION/$DIST_FNAME" "$IMAGE_LOCATION/vm2.qcow2"

	print_banner "Configuring VM1 networking and create cloud-init image"

	cat <<- EOF >> "$IMAGE_LOCATION/network-config-v1.yaml"
		version: 1
		config:
		  - type: physical
		    name: interface0
		    mac_address: "52:54:00:34:12:aa"
		    subnets:
		      - type: static
		        address: 1.1.1.1
		        netmask: 255.255.255.0
		        gateway: 1.1.1.254
		  - type: route
		    destination: 2.2.2.0/24
		    gateway: 1.1.1.1
		EOF

	cat <<- EOF >> "$IMAGE_LOCATION/meta-data"
		instance-id: 506f2788-9741-4ed8-af53-c6a21383d09a
		local-hostname: vm1
		EOF

	cat <<-EOF >> "$IMAGE_LOCATION/user-data"
		#cloud-config
		password: IPDK
		chpasswd: { expire: False }
		ssh_pwauth: True
		runcmd:
		  - [ sudo, ip, route, add, "2.2.2.0/24", via, "1.1.1.1", dev, interface0 ]
		  - [ sudo, ip, neigh, add, dev, interface0, '2.2.2.2', lladdr, '52:54:00:34:12:bb' ]
		EOF

	# if cloud-localds doesn't exist then 'sudo apt install cloud-image-utils'
	cloud-localds -v \
		--network-config="$IMAGE_LOCATION/network-config-v1.yaml" \
		"$IMAGE_LOCATION/seed1.img" \
		"$IMAGE_LOCATION/user-data" \
		"$IMAGE_LOCATION/meta-data"
	rm -f "$IMAGE_LOCATION/network-config-v1.yaml" \
		"$IMAGE_LOCATION/meta-data" \
		"$IMAGE_LOCATION/user-data"

	cat <<-EOF >> "$IMAGE_LOCATION/network-config-v1.yaml"
		version: 1
		config:
		  - type: physical
		    name: interface0
		    mac_address: "52:54:00:34:12:bb"
		    subnets:
		      - type: static
		        address: 2.2.2.2
		        netmask: 255.255.255.0
		        gateway: 2.2.2.254
		  - type: route
		    destination: 1.1.1.0/24
		    gateway: 2.2.2.2
		EOF

	cat <<-EOF >> "$IMAGE_LOCATION/meta-data"
		instance-id: 606f2788-9741-4ed8-af53-c6a21383d09b
		local-hostname: vm2
		EOF

	cat <<-EOF >> "$IMAGE_LOCATION/user-data"
		#cloud-config
		password: IPDK
		chpasswd: { expire: False }
		ssh_pwauth: True
		runcmd:
		  - [ sudo, ip, route, add, "1.1.1.0/24", via, "2.2.2.2", dev, interface0 ]
		  - [ sudo, ip, neigh, add, dev, interface0, '1.1.1.1', lladdr, '52:54:00:34:12:aa' ]
		EOF

	cloud-localds -v \
		--network-config="$IMAGE_LOCATION/network-config-v1.yaml" \
		"$IMAGE_LOCATION/seed2.img" \
		"$IMAGE_LOCATION/user-data" \
		"$IMAGE_LOCATION/meta-data"
	rm -f "$IMAGE_LOCATION/network-config-v1.yaml" \
		"$IMAGE_LOCATION/meta-data" \
		"$IMAGE_LOCATION/user-data"
}

#
# Start two predefined QEMU/KVM images from given location
# $1 = IMAGE_LOCATION
# $2 = INTF_LOCATION
# $3+ = extra parameters to add to kvm command like -nographic
#
start_vms() {
	local IMAGE_LOCATION="$1"
	local INTF_LOCATION="$2"
	# clean for extra parameters in ${@}
	shift 2

	print_banner "Starting VM1_TAP_DEV with serial port# 6551"

	sudo kvm -smp 1 -m 256M \
		-boot c -cpu host --enable-kvm \
		-name VM1_TAP_DEV \
		-hda "$IMAGE_LOCATION"/vm1.qcow2 \
		-drive file="$IMAGE_LOCATION"/seed1.img,id=seed,if=none,format=raw,index=1 \
		-device virtio-blk,drive=seed \
		-object memory-backend-file,id=mem,size=256M,mem-path=/mnt/huge,share=on \
		-numa node,memdev=mem \
		-mem-prealloc \
		-chardev socket,id=char1,path="$INTF_LOCATION"/vhost-user-0 \
		-netdev type=vhost-user,id=netdev0,chardev=char1,vhostforce \
		-device virtio-net-pci,mac=52:54:00:34:12:aa,netdev=netdev0 \
		-serial telnet::6551,server,nowait \
		"${@}" &

	print_banner "Waiting 5 seconds before starting second VM"
	for i in {1..5}
	do
		sleep 1
		echo -n "."
		if [ "$(( i % 30 ))" == "0" ]
		then
				echo ""
		fi
	done

	print_banner "Starting VM2_TAP_DEV with serial port# 6551"

	sudo kvm -smp 1 -m 256M \
		-boot c -cpu host --enable-kvm \
		-name VM2_TAP_DEV \
		-hda "$IMAGE_LOCATION"/vm2.qcow2 \
		-drive file="$IMAGE_LOCATION"/seed2.img,id=seed,if=none,format=raw,index=1 \
		-device virtio-blk,drive=seed \
		-object memory-backend-file,id=mem,size=256M,mem-path=/mnt/huge,share=on \
		-numa node,memdev=mem \
		-mem-prealloc \
		-chardev socket,id=char2,path="$INTF_LOCATION"/vhost-user-1 \
		-netdev type=vhost-user,id=netdev1,chardev=char2,vhostforce \
		-device virtio-net-pci,mac=52:54:00:34:12:bb,netdev=netdev1 \
		-serial telnet::6552,server,nowait \
		"${@}" &
}

#
# Connect to a commandline on the IPDK docker
# $1 = CONTAINER_NAME
# #2 = WORKING_DIR - Working directory to execute command in
#
docker_connect() {
	local CONTAINER_NAME=$1
	local WORKING_DIR=$2
	shift 2
	docker exec -it -w "${WORKING_DIR}" "${CONTAINER_NAME}" \
		/bin/bash --rcfile /root/scripts/start.sh
}

#
# Execute given commandline on IPDK docker
# $1 = CONTAINER_NAME
# #2 = WORKING_DIR - Working directory to execute command in
# #3+ all arguments of the commandline to execute 
docker_execute() {
	local CONTAINER_NAME=$1
	local WORKING_DIR=$2
	shift 2
	docker exec -it -w "${WORKING_DIR}" "${CONTAINER_NAME}" \
		/root/scripts/start.sh execute "${@}"
}

#
# Execute gnmi-cli command on host
# $1 = COMMAND gnmi-cli command
# $2 = PARAMETER gnmi-cli command parameter
#
gnmi_cli_local() {
	local COMMAND=$1
	local PARAMETER=$2

	gnmi-cli "$COMMAND" "$PARAMETER"
}

#
# Execute gnmi-cli command on running IPDK docker container
# $1 = CONTAINER_NAME container name to run in
# $2 = COMMAND gnmi-cli command
# $3 = PARAMETER gnmi-cli cammand parameter
#
gnmi_cli_docker() {
	local CONTAINER_NAME=$1
	local COMMAND=$2
	local PARAMETER=$3

	docker_execute "${CONTAINER_NAME}" /root gnmi-cli "$COMMAND" "$PARAMETER"
}

#
# Build the simple_l3 pipeline files by using local p4c & builder
# $1 = SOURCE directory
# $2 = DESTINATION directory
#
generate_pipeline_files_local() {
	local SOURCE=$1

	print_banner "Generating pipeline files from P4C and OVS pipeline builder"

	p4c --arch psa --target dpdk --output "$SOURCE/pipe" --p4runtime-files \
		"$SOURCE/p4Info.txt" --bf-rt-schema "$SOURCE/bf-rt.json" \
		--context "$SOURCE/pipe/context.json" "$SOURCE/simple_l3.p4"

	pushd "$SOURCE" || exit
		ovs_pipeline_builder --p4c_conf_file=simple_l3.conf \
			--bf_pipeline_config_binary_file=simple_l3.pb.bin
	popd || exit
}

#
# Build the simple_l3 pipeline files by using docker p4c & builder
# $1 = CONTAINER_NAME container name to run in
# $2 = SOURCE directory
#
generate_pipeline_files_docker() {
	local CONTAINER_NAME=$1
	local SOURCE=$2

	docker_execute "${CONTAINER_NAME}" "${SOURCE}" p4c --arch psa --target dpdk --output "$SOURCE/pipe" --p4runtime-files "$SOURCE/p4Info.txt" --bf-rt-schema "$SOURCE/bf-rt.json" --context "$SOURCE/pipe/context.json" "$SOURCE/simple_l3.p4"

	docker_execute "${CONTAINER_NAME}" "${SOURCE}" ovs_pipeline_builder --p4c_conf_file=simple_l3.conf --bf_pipeline_config_binary_file=simple_l3.pb.bin
}

#
# Add the created forwarding pipeline programm
#
program_pipeline_local() {
	print_banner "Programming P4-OVS pipeline"

	ovs-p4ctl set-pipe br0 /root/examples/simple_l3/simple_l3.pb.bin \
		/root/examples/simple_l3/p4Info.txt
}

#
# Add the created forwarding pipeline programm to the running IPDK container
# $1 = CONTAINER_NAME container name to run in
#
program_pipeline_docker() {
	local CONTAINER_NAME=$1

	docker_execute "${CONTAINER_NAME}" /root ovs-p4ctl set-pipe br0 /root/examples/simple_l3/simple_l3.pb.bin /root/examples/simple_l3/p4Info.txt
}

#
# add the table rules using local ovs-p4ctl
#
add_table_rules_local() {
	print_banner "Add table rules to the pipeline"

	ovs-p4ctl add-entry br0 ingress.ipv4_host \
		"hdr.ipv4.dst_addr=1.1.1.1,action=ingress.send(0)"
	ovs-p4ctl add-entry br0 ingress.ipv4_host \
		"hdr.ipv4.dst_addr=2.2.2.2,action=ingress.send(1)"
}

#
# add the table rules using docker ovs-p4ctl
# $1 = CONTAINER_NAME container name to run in
#
add_table_rules_docker() {
	local CONTAINER_NAME=$1

	docker_execute "${CONTAINER_NAME}" /root ovs-p4ctl add-entry br0 ingress.ipv4_host "hdr.ipv4.dst_addr=1.1.1.1,action=ingress.send(0)"

	docker_execute "${CONTAINER_NAME}" /root ovs-p4ctl add-entry br0 ingress.ipv4_host "hdr.ipv4.dst_addr=2.2.2.2,action=ingress.send(1)"
}

#
# Start the bare host/vagrant based demo
# $1 = VOLUME_LOCATION
# $2 = KVM_GRAPHIC (true / false)
#
start_host_demo() {
	# input arguments
	local VOLUME_LOCATION=$1
	local KVM_GRAPHIC=$2
	local IMAGE_LOCATION="$VOLUME_LOCATION/images"
	local INTF_LOCATION="$VOLUME_LOCATION/intf"
	local PIPE_LOCATION="$VOLUME_LOCATION/pipe"

	create_images "$IMAGE_LOCATION"

	print_banner "Setting hugepages"

	"$SCRIPT_DIR"/set_hugepages.sh

	print_banner "Creating vhost-user ports"

	gnmi_cli_local set "device:virtual-device,name:net_vhost0,host:host1,device-type:VIRTIO_NET,queues:1,socket-path:$INTF_LOCATION/vhost-user-0,port-type:LINK"
	gnmi_cli_local set "device:virtual-device,name:net_vhost1,host:host1,device-type:VIRTIO_NET,queues:1,socket-path:$INTF_LOCATION/vhost-user-1,port-type:LINK"

	generate_pipeline_files_local "$PIPE_LOCATION" "/root/examples/simple_l3/"

	local KVM_ARGS=()
	if ! "$KVM_GRAPHIC" ; then
		KVM_ARGS+=("-nographic")
	fi
	start_vms "$IMAGE_LOCATION" "$INTF_LOCATION" "${KVM_ARGS[@]}"

	program_pipeline_local

	print_banner "Do some test!!!"
}

#
# Start the IPDK docker based demo
# $1 = CONTAINER_NAME
# $2 = VOLUME_LOCATION
# $3 = KVM_GRAPHIC (true / false)
#
start_docker_demo() {
	# input arguments
	local CONTAINER_NAME=$1
	local VOLUME_LOCATION=$2
	local KVM_GRAPHIC=$3
	local IMAGE_LOCATION="$VOLUME_LOCATION/images"
	local INTF_LOCATION="/tmp/intf"
	local PIPE_LOCATION="/root/examples/simple_l3" #"/tmp/pipe"

	create_images "$IMAGE_LOCATION"

	print_banner "Setting hugepages"
	"$SCRIPT_DIR"/set_hugepages.sh

	print_banner "Creating vhost-user ports"
	gnmi_cli_docker "$CONTAINER_NAME" set "device:virtual-device,name:net_vhost0,host:host1,device-type:VIRTIO_NET,queues:1,socket-path:$INTF_LOCATION/vhost-user-0,port-type:LINK"
	gnmi_cli_docker "$CONTAINER_NAME" set "device:virtual-device,name:net_vhost1,host:host1,device-type:VIRTIO_NET,queues:1,socket-path:$INTF_LOCATION/vhost-user-1,port-type:LINK"

	print_banner "Generating simple_l3 pipeline package with P4C and OVS pipeline builder"
	generate_pipeline_files_docker "$CONTAINER_NAME" "$PIPE_LOCATION" "/root/examples/simple_l3"

	print_banner "Programming P4-OVS pipeline"
	program_pipeline_docker "$CONTAINER_NAME" 

	print_banner "Add table rules to the pipeline"
	add_table_rules_docker "$CONTAINER_NAME" 

	local KVM_ARGS=()
	if ! "$KVM_GRAPHIC" ; then
		KVM_ARGS+=("-nographic")
	fi
	start_vms "$IMAGE_LOCATION" "$VOLUME_LOCATION/intf" "${KVM_ARGS[@]}"

	print_banner "Demo setup is executed and ready to be used. Do some test!!!"
}
