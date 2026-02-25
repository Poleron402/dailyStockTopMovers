.PHONY: prepare_save prepare_fetch

prepare_save:
	cd be-save && \
	mkdir lambda && \
	cp script.py lambda/script.py && \
	pip install -r requirements.txt -t lambda/


prepare_fetch:
	cd be-fetch && \
	mkdir lambda && \
	cp script.py lambda/script.py && \
	pip install -r requirements.txt -t lambda/