
.ONESHELL:
.SHELL := /usr/bin/bash

VARENV=testenv
VARS="variables/${VARENV}.tfvars"
CURRENT_FOLDER=$(shell basename "$$(pwd)")
BOLD=$(shell tput bold)
RED=$(shell tput setaf 1)
GREEN=$(shell tput setaf 2)
YELLOW=$(shell tput setaf 3)
RESET=$(shell tput sgr0)

.DEFAULT_GOAL := help


.PHONY: fmt
fmt: ## terraform format
	@terraform fmt $(args) $(RUN_ARGS)
.PHONY: lint
lint: ## Rewrites config to canonical format
	@terraform fmt -diff=true -check $(args) $(RUN_ARGS)



validate:  ## validate TF files
	@for i in $$(find -type f -name "*.tf" -exec dirname {} \; | grep -v "/test"); do \
        terraform validate "$$i"; \
        if [ $$? -ne 0 ]; then \
                echo "Failed Terraform .tf file validation"; \
                echo; \
                exit 1; \
        fi; \
    done


init: fmt ## Init terraform module
	@terraform init \
		-input=false

update: ## Get terraform module
	@terraform get -update=true 1>/dev/null		

plan: init update ## Show what terraform thinks it will do
	@terraform plan \
		-lock=true \
		-input=false \
		-refresh=true


plan-destroy: init update ## Creates a destruction plan.
	@terraform plan \
		-input=false \
		-refresh=true \
		-destroy

up: apply	## alias of apply
apply: init update ## Have terraform do the things. This will cost money.
	@terraform apply \
		-lock=true \
		-input=false \
		-refresh=true \
		-auto-approve=true

del: destroy	## alias of destroy
delete: destroy ## alias of destroy
destroy: init update ## Destroy everything
	@terraform destroy \
		-lock=true \
		-input=false \
		-refresh=true \
		-force
	@rm -rf terraform.tfstate*
	@rm -rf .terraform/
	@rm -rf kubeconfig/

destroy-target: init update  ## Destroy one data
	@echo "Specifically destroy a piece of Terraform data."
	@echo
	@echo "Example to type for the following question: module.rds.aws_route53_record.rds-master"
	@echo
	@read -p "Destroy target: " DATA &&\
        terraform destroy \
		-lock=true \
		-input=false \
		-refresh=true \
        -target=$$DATA

output: init update  ## print terraform output 
	@echo "Example to type for the module: MODULE=module.rds.aws_route53_record.rds-master"
	@echo
	@if [ -z $(MODULE) ]; then\
        terraform output;\
     else\
        terraform output -module=$(MODULE);\
     fi


show: init  ## Show
	@terraform show -module-depth=-1



help:
	@printf "\033[32mTerraform-makefile\033[0m\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'





