#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
#

.PHONY: help

## List all available commands
help:;@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
#awk '/^#/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print substr($$1,1,index($$1,":")),c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t

shellcheck: ;../networking/scripts/run-shellcheck.sh

.PHONY: demo-start

start-demo:
	ipdk start -d --link-namespace --ulimit
	sudo cp -f ~/go/src/ipdk-plugin/ipdk.json /etc/docker/plugins/
	sudo ~/go/src/ipdk-plugin/ipdk-plugin &
	sleep 10
	docker network create -d=ipdk --ipam-driver=ipdk --subnet=192.168.27.0/24 --gateway=192.168.27.1 ipdk_net
	docker run --net=ipdk_net --ip=192.168.27.2 --name "hasipdk1" --cap-add NET_ADMIN -itd wbitt/network-multitool sh
	docker run --net=ipdk_net --ip=192.168.27.3 --name "hasipdk2" --cap-add NET_ADMIN -itd wbitt/network-multitool sh
	docker exec -it hasipdk1 ping -c 5 192.168.27.3
	docker exec -it hasipdk2 ping -c 5 192.168.27.2

.PHONY: demo-stop

stop-demo:
	docker rm -f hasipdk2
	docker rm -f hasipdk1
	docker network rm ipdk_net
	sudo killall ipdk-plugin
	ipdk stop
