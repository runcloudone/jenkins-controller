VERSION           ?= 2.401
JENKINS_TAG       ?= $(VERSION)-jdk11
BUILD_NUMBER      ?= UNKNOWN

LOCAL             ?= false
DOCKER_REGISTRY   ?= 787096050701.dkr.ecr.us-east-1.amazonaws.com
DOCKER_IMAGE_TAG  ?= $(VERSION)-$(BUILD_NUMBER)
DOCKER_IMAGE_TAG  := $(shell echo $(DOCKER_IMAGE_TAG) | tr A-Z a-z)
DOCKER_IMAGE_NAME := $(DOCKER_REGISTRY)/jenkins-controller

ifeq ($(LOCAL),true)
	DOCKERFILE := Dockerfile.local
	DOCKER_IMAGE_TAG := $(addsuffix -local, $(DOCKER_IMAGE_TAG))
else
	DOCKERFILE := Dockerfile
endif

.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

info: ## Information about build
	@echo "--- Build Environment ---"
	@echo "JENKINS_VERSION: $(VERSION)"
	@echo "BUILD_NUMBER: $(BUILD_NUMBER)"
	@echo "DOCKER_IMAGE_NAME: $(DOCKER_IMAGE_NAME)"
	@echo "DOCKER_IMAGE_TAG: $(DOCKER_IMAGE_TAG)"

build: ## Building image 
	@echo "--- Building Image ---"
	docker build --rm --build-arg JENKINS_TAG=$(JENKINS_TAG) --tag $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) --file $(DOCKERFILE) .
	docker tag $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) $(DOCKER_IMAGE_NAME):latest
	@echo ""

push: build ## Publish image
	@echo "--- Pushing Image ---"
	docker push $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
	docker push $(DOCKER_IMAGE_NAME):latest
	@echo ""

shell: ## Creates a shell inside the container for debug purposes
	@echo "--- Running Container ---"
	docker run --interactive --tty $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) /bin/sh
	@echo ""
