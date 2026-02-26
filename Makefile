.PHONY: prepare_save prepare_fetch load_and_plan load_infra

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