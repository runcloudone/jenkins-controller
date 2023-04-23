VERSION        ?= 2.401
BASE_IMAGE_TAG ?= jenkins/jenkins:$(VERSION)-jdk11
BUILD_NUMBER   ?= $(shell git rev-parse --short HEAD)

MAKEFILE_LOCAL_BUILD ?= false
DOCKER_REGISTRY      ?= 787096050701.dkr.ecr.us-east-1.amazonaws.com
DOCKER_IMAGE_NAME    := $(DOCKER_REGISTRY)/jenkins-controller
DOCKER_IMAGE_TAG     := $(shell printf '%s.%s' $(VERSION) $(BUILD_NUMBER) | tr A-Z a-z)
DOCKERFILE           := $(if $(filter $(MAKEFILE_LOCAL_BUILD),true),Dockerfile.local,Dockerfile)
REQUIRED_ENV_VARS    := JENKINS_ADMIN_USERNAME JENKINS_ADMIN_PASSWORD JENKINS_ADMIN_EMAIL JENKINS_PIPELINE_COMMONS_REPO JENKINS_GITHUB_KEY
CONTAINER_NAME       := jenkins
COLOR_FORMAT         := "\033[36m%-30s\033[0m %s\n"

.PHONY: help info build push shell run-local

.DEFAULT_GOAL := help

help: ## This help.
	@printf $(COLOR_FORMAT) 'Target' 'Description'
	@printf $(COLOR_FORMAT) '------' '-----------'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf $(COLOR_FORMAT), $$1, $$2}' $(MAKEFILE_LIST)

clean: ## Removes the container if it exists
	@printf $(COLOR_FORMAT) '--- Cleaning Up ---'
	docker rm -f $(CONTAINER_NAME) || true

info: ## Information about build
	@printf $(COLOR_FORMAT) '--- Build Environment ---'
	@printf 'JENKINS_VERSION: %s\n' $(VERSION)
	@printf 'BUILD_NUMBER: %s\n' $(BUILD_NUMBER)
	@printf 'DOCKER_IMAGE_NAME: %s\n' $(DOCKER_IMAGE_NAME)
	@printf 'DOCKER_IMAGE_TAG: %s\n' $(DOCKER_IMAGE_TAG)

build: info ## Building image
	@printf $(COLOR_FORMAT) '--- Building Image ---'
	docker build --rm --build-arg BASE_IMAGE_TAG=$(BASE_IMAGE_TAG) -t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) -f $(DOCKERFILE) .

push: build ## Publish image
	@printf $(COLOR_FORMAT) '--- Pushing Image ---'
	docker push $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

shell: clean build ## Creates a shell inside the container for debug purposes
	@printf $(COLOR_FORMAT) '--- Running Container ---'
	docker run --rm --name $(CONTAINER_NAME) -it $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) /bin/bash

run-local: clean build ## Runs the container locally
	@printf $(COLOR_FORMAT) '--- Running Container ---'
	$(foreach var,$(REQUIRED_ENV_VARS),$(if $(value $(var)),,$(error Environment variable $(var) is not set)))
	docker run -d --rm --name $(CONTAINER_NAME) -p 8080:8080 \
	$(foreach var,$(REQUIRED_ENV_VARS), \
	-e $(var)="$(if $(filter JENKINS_GITHUB_KEY,$(var)),$$(cat $(value $(var))),$(value $(var)))") \
	$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
