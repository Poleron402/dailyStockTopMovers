.PHONY: prepare_save prepare_fetch load_and_plan load_infra load_react

.ONESHELL:
SHELL := /bin/bash

# Prepare `be-save` for deployment by running
prepare_save:
	cd be-save && \
	rm -rf lambda && \
	mkdir lambda && \
	cp script.py lambda/script.py && \
	pip install -r requirements.txt -t lambda/

# Prepare `be-fetch` for deployment by running
prepare_fetch:
	cd be-fetch && \
	rm -rf lambda && \
	mkdir lambda && \
	cp script.py lambda/script.py && \
	pip install -r requirements.txt -t lambda/

# Load all the environment variables and check the planned changes by running
load_and_plan:
	cd infra && \
	source .env && \
	terraform plan

load_infra:
	cd infra && \
	terraform apply --auto-approve

load_react:
	source infra/.env && \
	cd fe && \
	npm run build && \
	cd .. && \
	aws s3 sync fe/dist s3://$$TF_VAR_bucket_name --acl public-read