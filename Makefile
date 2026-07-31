SHELL := /bin/bash

.PHONY: bootstrap deploy validate bronze-deploy bronze-validate origen-all bronze-all all

bootstrap:
	bash scripts/bootstrap.sh

deploy:
	bash scripts/deploy_bigquery.sh

validate:
	bash scripts/validate_bigquery.sh

bronze-deploy:
	bash scripts/deploy_bronze.sh

bronze-validate:
	bash scripts/validate_bronze.sh

origen-all: bootstrap deploy validate

bronze-all: bootstrap deploy validate bronze-deploy bronze-validate

all: bronze-all
