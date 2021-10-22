#Copyright (C) 2021 Intel Corporation
#SPDX-License-Identifier: Apache-2.0
#
# When using sample configurations from 'examples' folder, do the following to get your P4-OVS container up and running:
# make build
# make volume
#

# Import variables needed by this Makefile
env_var ?= docker.env
include $(env_var)
export $(shell sed 's/=.*//' $(env_var))

.PHONY: help

## List all available commands
help:;@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
#awk '/^#/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print substr($$1,1,index($$1,":")),c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t

# DOCKER COMMANDS 
## Build the docker image
build: ;docker build -t ${IMAGE_NAME}:${TAG} -f Dockerfile . \
--build-arg http_proxy=${PROXY} \
--build-arg https_proxy=${PROXY} \
--build-arg OS_VERSION=${OS_VERSION}

## Build the container without caching. To be used when cloning from GIT repo.
build-nc: ;docker build --no-cache -t ${IMAGE_NAME}:${TAG} -f Dockerfile . \
--build-arg http_proxy=${PROXY} \
--build-arg https_proxy=${PROXY} \
--build-arg OS_VERSION=${OS_VERSION}

## Run the container
run: ;docker run --rm --cap-add ALL --privileged -it ${IMAGE_NAME}:${TAG}

## Stop running container
stop: ;docker stop ${IMAGE_NAME}:${TAG}

rm: stop ;docker rm ${IMAGE_NAME}:${TAG}

## Push container image
push: ;docker push ${IMAGE_NAME}:${TAG}

## Remove all unused containers, images, networks and volumes
prune: ;docker system prune

## Create a volume and then configure the container to use it.
volume: ;docker volume create shared; docker run --rm --cap-add ALL --privileged -v shared:/tmp -it ${IMAGE_NAME}:${TAG}
