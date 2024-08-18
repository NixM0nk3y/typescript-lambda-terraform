# Meta tasks
# ----------

RUN_TF ?= tofu

# Useful variables
export SAM_CLI_TELEMETRY=0

# deployment environment
export ENVIRONMENT ?= dev

# region
export AWS_REGION ?= eu-west-1

# account
export AWS_ACCOUNT ?= 074705540277

# if we store our artifact
export TF_ARTIFACT ?= ".terraform/$(ENVIRONMENT).plan"

#
export BUILD_SOURCEVERSION ?=$(shell git rev-list -1 HEAD)

export COMMIT ?= $(shell git rev-list -1 HEAD --abbrev-commit)
export BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
export DATE ?= $(shell date -u '+%Y%m%d')

# Terraform variables
# --------------

# Output helpers
# --------------

TASK_DONE = echo "✓  $@ done"
TASK_BUILD = echo "🛠️  $@ done"

# ----------------
.DEFAULT_GOAL := terraform/plan

clean:
	@rm -rf $(CURDIR)/.terraform vendor builds
	@$(TASK_DONE)

init: terraform/init
	@$(TASK_DONE)

plan: terraform/plan
	@$(TASK_DONE)

apply: terraform/apply
	@$(TASK_DONE)

destroy: terraform/destroy
	@$(TASK_DONE)

terraform/format: ## Correct formatting.
	@$(RUN_TF) fmt $(CURDIR)
	@$(TASK_BUILD)

terraform/format/check: ## Run a formatting check.
	@$(RUN_TF) fmt -check $(CURDIR)
	@$(TASK_BUILD)

terraform/plan:
	@$(RUN_TF) plan -var-file=config/$(ENVIRONMENT).tfvars
	@$(TASK_BUILD)

terraform/plan/artifact:
	@$(RUN_TF) plan -var-file=config/$(ENVIRONMENT).tfvars -out $(TF_ARTIFACT)
	@$(TASK_BUILD)

terraform/plan/artifact/ci:
	@$(RUN_TF) plan -var-file=config/$(ENVIRONMENT).tfvars -detailed-exitcode -out $(TF_ARTIFACT); \
	TF_RETURN=$$? ; \
	if [ $${TF_RETURN} -eq 2 ] ; then \
		echo "terraform changes detected"; \
		echo "##vso[task.setvariable variable=TERRAFORM_CHANGE;issecret=false;isoutput=true]true"; \
    elif [ $${TF_RETURN} -eq 1 ]; then \
	    echo "terraform error detected"; \
        exit 1; \
	else \
		echo "no terraform changes detected"; \
		echo "##vso[task.setvariable variable=TERRAFORM_CHANGE;issecret=false;isoutput=true]false"; \
	fi
	@$(TASK_BUILD)

terraform/apply:
	@$(RUN_TF) apply -var-file=config/$(ENVIRONMENT).tfvars -auto-approve  
	@$(TASK_BUILD)

terraform/apply/artifact:
	@$(RUN_TF) apply -auto-approve $(TF_ARTIFACT) 
	@$(TASK_BUILD)
 
terraform/destroy:
	@$(RUN_TF) destroy -var-file=config/$(ENVIRONMENT).tfvars
	@$(TASK_BUILD)

terraform/init: terraform/module/init
	@$(RUN_TF) init -reconfigure
	@if [ `$(RUN_TF) workspace list | grep -c $(ENVIRONMENT)` -eq 0 ] ; then \
		$(RUN_TF) workspace new $(ENVIRONMENT); \
	else \
		$(RUN_TF) workspace select $(ENVIRONMENT); \
	fi
	@$(TASK_BUILD)

terraform/lint: ## Run a lint across the module.
	mkdir -p /tmp/tflint.d
	docker run --rm -v /tmp/tflint.d:/root/.tflint.d -v $(CURDIR):/data -v $(CURDIR)/.tflint.hcl:/data/.tflint.hcl -t ghcr.io/terraform-linters/tflint --init
	docker run --rm -v /tmp/tflint.d:/root/.tflint.d -v $(CURDIR):/data -v $(CURDIR)/.tflint.hcl:/data/.tflint.hcl -t ghcr.io/terraform-linters/tflint
	@$(TASK_BUILD)

terraform/security: ## Run a security scan.
	docker run --rm -it -v "$(CURDIR):/src" -v "$(CURDIR)/.tfsec:/src/.tfsec" aquasec/tfsec /src --exclude-downloaded-modules --exclude-path /src/vendor
	@$(TASK_BUILD)

terraform/module/init:
	terrafile
	@$(TASK_BUILD)

help: ## Show this help message.
	@echo 'usage: make [target] ...'
	@echo
	@echo 'targets:'
	@egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | column -t -c 2 -s ':#'
