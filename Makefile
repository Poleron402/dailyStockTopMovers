.PHONY: prepare_save prepare_fetch load_and_plan load_infra load_react

prepare_save:
	cd be-save && \
	rm -rf lambda && \
	mkdir lambda && \
	cp script.py lambda/script.py && \
	pip install -r requirements.txt -t lambda/


prepare_fetch:
	cd be-fetch && \
	rm -rf lambda && \
	mkdir lambda && \
	cp script.py lambda/script.py && \
	pip install -r requirements.txt -t lambda/

load_and_plan:
	cd infra && \
	source .env && \
	terraform plan

load_infra:
	cd infra && \
	terraform apply

load_react:
	cd infra && \
	source .env && \
	cd .. && \
	cd fe && \
	npm run build && \
	cd .. && \
	aws s3 sync fe/dist s3://$(TF_VAR_bucket_name) --acl public-read

