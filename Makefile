.PHONY: help
$(VERBOSE).SILENT:

ifndef PROJECT_NAME
PROJECT_NAME=vtex-mirror
endif

ifndef PROJECT_VERSION
PROJECT_VERSION=0.0.1
endif

ifndef API_IMAGE_NAME
API_IMAGE_NAME=$(PROJECT_NAME)-api
endif

ifndef TOOLBOX_NAME
TOOLBOX_NAME=$(PROJECT_NAME)-toolbox
endif

ifndef DATABASE_NAME
DATABASE_NAME=$(PROJECT_NAME)-db
endif

ifndef AWS_REPO
AWS_REPO=????.dkr.ecr.us-east-1.amazonaws.com
endif

# Function and macros
input=read -p "$(1)" $(2)
safe_input=read -s -p "$(1)" $(2) && echo ''
build_image=docker image build -t $(1) $(2) 
tag_image=docker image tag $(1):latest $(1):$(2)
push_image=docker image push $(1):$(2)

# Self-Documented Makefile
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -E '^(\w|-)+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.DEFAULT_GOAL := help

# ======================================================================================================
### Project 
# ======================================================================================================

build-toolbox: ## Build Alpine based minimal docker container with project utils
	echo "Building toolbox..." && docker image build -t $(TOOLBOX_NAME) toolbox

compose: ## Manage project using correct ambient's docker-compose file
	$(call input,Compose file ambient: ,AMBIENT) && \
	$(call input,docker-compose -f docker-compose.$$AMBIENT.yml: ,CMD) && \
	docker-compose -f docker-compose.$$AMBIENT.yml $$CMD

setup-database: build-toolbox ## Run initial configuration on the indicated Postgres database
	$(call input,DB Host: ,DB_HOST) && \
	$(call input,DB Port: ,DB_PORT) && \
	$(call input,DB Username: ,DB_USER) && \
	$(call safe_input,DB Password: ,DB_PWD) && \
	echo "Initializing database..." && \
	docker run --rm --net host -it \
		-v $$PWD/toolbox/database:/tmp/database \
		$(TOOLBOX_NAME) sh -c " \
		PGPASSWORD=$$DB_PWD psql -U $$DB_USER -p $$DB_PORT -h $$DB_HOST -c 'create database \"$(DATABASE_NAME)\";' && \
		PGPASSWORD=$$DB_PWD psql -U $$DB_USER -p $$DB_PORT -h $$DB_HOST -d $(DATABASE_NAME) -f /tmp/database/scripts/initdb.sql"

# ======================================================================================================
### AWS 
# ======================================================================================================

aws-cli-register-profile: ## Register AWS CLI profile (Ask the project responsible for the needed credentials)
	aws configure --profile $(AWS_CLI_PROFILE)

aws-ecr-push-images: build-api build-new-patients-importer build-s3-cleanup-worker ## Push all images to ECR
	aws ecr get-login-password --profile $(AWS_CLI_PROFILE) | docker login --username AWS --password-stdin $(AWS_REPO)

	$(call tag_image,$(AWS_REPO)/$(API_IMAGE_NAME),$(PROJECT_VERSION))
	$(call push_image,$(AWS_REPO)/$(API_IMAGE_NAME),latest)
	$(call push_image,$(AWS_REPO)/$(API_IMAGE_NAME),$(PROJECT_VERSION))

	$(call tag_image,$(AWS_REPO)/$(NEW_PATIENTS_IMPORTER_IMAGE_NAME),$(PROJECT_VERSION))
	$(call push_image,$(AWS_REPO)/$(NEW_PATIENTS_IMPORTER_IMAGE_NAME),latest)
	$(call push_image,$(AWS_REPO)/$(NEW_PATIENTS_IMPORTER_IMAGE_NAME),$(PROJECT_VERSION))

	$(call tag_image,$(AWS_REPO)/$(S3_CLEANUP_WORKER_IMAGE_NAME),$(PROJECT_VERSION))
	$(call push_image,$(AWS_REPO)/$(S3_CLEANUP_WORKER_IMAGE_NAME),latest)
	$(call push_image,$(AWS_REPO)/$(S3_CLEANUP_WORKER_IMAGE_NAME),$(PROJECT_VERSION))

build-api: ## Build API image
	$(call build_image,$(AWS_REPO)/$(API_IMAGE_NAME),./api)

build-new-patients-importer: ## Build New Patients Importer image
	$(call build_image,$(AWS_REPO)/$(NEW_PATIENTS_IMPORTER_IMAGE_NAME),./new_patients_importer)

build-s3-cleanup-worker: ## Build S3 Cleanup Worker image
	$(call build_image,$(AWS_REPO)/$(S3_CLEANUP_WORKER_IMAGE_NAME),./s3_cleanup_worker)
