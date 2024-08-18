.EXPORT_ALL_VARIABLES:

# Useful variables
export SAM_CLI_TELEMETRY=0

# region
export AWS_REGION ?= eu-west-1

# deployment environment
ENVIRONMENT ?= dev

export COMMIT ?= $(shell git rev-list -1 HEAD --abbrev-commit)
export BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
export DATE ?= $(shell date -u '+%Y%m%d')

ARTIFACTS_DIR ?= /asset-output

# Output helpers
# --------------

TASK_DONE = echo "✓  $@ done"
TASK_BUILD = echo "🛠️  $@ done"

all: build

clean:
	rm -rf dist node_modules .aws-sam

deps:
	npm ci
	@$(TASK_DONE)

version: 
	COMMIT=$(COMMIT) BRANCH=$(BRANCH) DATE=$(DATE) ./scripts/version.sh

build: deps
	npm run build
	@$(TASK_BUILD)

bundle: deps
	npm run bundle
	@$(TASK_BUILD)

bundle-lambda: version bundle
	cp ./dist/lambda.mjs ${ARTIFACTS_DIR}/
	@$(TASK_BUILD)

lambda/test/invoke: lambda/build ## Test a local invoke of the lambda.
	@sam local invoke --event tests/events/event.json --env-vars tests/environment.json  --region $(AWS_REGION)
	@$(TASK_BUILD)

lambda/build: ## install the deps
	@sam build --use-container --template-file ./template.yaml \
		--container-env-var SAM_CLI_TELEMETRY=$$SAM_CLI_TELEMETRY
	@$(TASK_BUILD)

test: build
	npm run test
	@$(TASK_BUILD)