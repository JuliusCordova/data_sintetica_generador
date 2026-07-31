SHELL := /bin/bash

.PHONY: bootstrap deploy validate all

bootstrap:
	bash scripts/bootstrap.sh

deploy:
	bash scripts/deploy_bigquery.sh

validate:
	bash scripts/validate_bigquery.sh

all: bootstrap deploy validate
