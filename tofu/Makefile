.PHONY: help bootstrap init plan apply destroy plan-destroy show state output kubeconfig

ENV ?= staging
PROVIDER ?= aws
BOOTSTRAP_DIR := bootstrap
PROVIDER_DIR := $(PROVIDER)
TFVARS := $(PROVIDER_DIR)/environments/$(ENV).tfvars

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

check-env: ## Validate environment and provider
	@if [ "$(ENV)" != "staging" ] && [ "$(ENV)" != "production" ]; then \
		echo "Error: ENV must be 'staging' or 'production'. Got '$(ENV)'"; exit 1; \
	fi
	@if [ "$(PROVIDER)" != "aws" ] && [ "$(PROVIDER)" != "digitalocean" ]; then \
		echo "Error: PROVIDER must be 'aws' or 'digitalocean'. Got '$(PROVIDER)'"; exit 1; \
	fi
	@if ! command -v tofu >/dev/null 2>&1; then \
		echo "Error: tofu not found. Install OpenTofu first."; exit 1; \
	fi
	@if [ "$(PROVIDER)" = "aws" ]; then \
		if ! aws sts get-caller-identity >/dev/null 2>&1; then \
			echo "Error: AWS credentials not configured."; exit 1; \
		fi; \
	fi
	@if [ "$(PROVIDER)" = "digitalocean" ]; then \
		if [ -z "$$DIGITALOCEAN_TOKEN" ]; then \
			echo "Error: DIGITALOCEAN_TOKEN environment variable not set."; exit 1; \
		fi; \
		if ! aws sts get-caller-identity >/dev/null 2>&1; then \
			echo "Error: AWS credentials not configured (needed for S3 state backend)."; exit 1; \
		fi; \
	fi
	@test -f $(TFVARS) || (echo "Error: $(TFVARS) not found"; exit 1)

bootstrap: ## Create S3 state bucket and DynamoDB lock table (run once)
	cd $(BOOTSTRAP_DIR) && tofu init && tofu apply

init: check-env ## Initialize OpenTofu for PROVIDER/ENV (e.g., make init PROVIDER=digitalocean ENV=staging)
	cd $(PROVIDER_DIR) && tofu init

plan: check-env ## Plan changes (e.g., make plan PROVIDER=digitalocean ENV=staging)
	cd $(PROVIDER_DIR) && tofu plan -var-file=environments/$(ENV).tfvars

apply: check-env ## Apply changes (e.g., make apply PROVIDER=digitalocean ENV=staging)
	cd $(PROVIDER_DIR) && tofu apply -var-file=environments/$(ENV).tfvars

plan-destroy: check-env ## Preview what will be destroyed (dry run)
	cd $(PROVIDER_DIR) && tofu plan -destroy -var-file=environments/$(ENV).tfvars

destroy: check-env ## Destroy infrastructure (prompts for confirmation)
	cd $(PROVIDER_DIR) && tofu destroy -var-file=environments/$(ENV).tfvars

show: check-env ## Show all resources in current state
	cd $(PROVIDER_DIR) && tofu show

state: check-env ## List all resources tracked in state
	cd $(PROVIDER_DIR) && tofu state list

output: check-env ## Show outputs
	cd $(PROVIDER_DIR) && tofu output

kubeconfig: check-env ## Update kubeconfig for the cluster
	@if [ "$(PROVIDER)" = "aws" ]; then \
		cd $(PROVIDER_DIR) && tofu output -raw eks_update_kubeconfig_command | sh; \
	elif [ "$(PROVIDER)" = "digitalocean" ]; then \
		cd $(PROVIDER_DIR) && tofu output -raw kubeconfig_command | sh; \
	fi
