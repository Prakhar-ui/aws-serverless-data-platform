.PHONY: help init validate plan apply destroy test install fmt precommit

MODULES = bootstrap s3 iam sns glue lambda step_functions eventbridge monitoring budget

help:  ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-20s %s\n", $$1, $$2}'

init: ## Initialize all Terraform modules
	@for mod in $(MODULES); do \
		if [ -d "terraform/$${mod}" ]; then \
			echo "=== $${mod} ==="; \
			cd terraform/$${mod} && terraform init && cd ../..; \
		fi; \
	done

validate: ## Validate all Terraform modules
	@for mod in $(MODULES); do \
		if [ -d "terraform/$${mod}" ]; then \
			echo "=== $${mod} ==="; \
			cd terraform/$${mod} && terraform validate && cd ../..; \
		fi; \
	done

plan: ## Plan all Terraform modules
	@for mod in $(MODULES); do \
		if [ -d "terraform/$${mod}" ]; then \
			echo "=== $${mod} ==="; \
			cd terraform/$${mod} && terraform plan && cd ../..; \
		fi; \
	done

apply: ## Apply all Terraform modules
	@for mod in $(MODULES); do \
		if [ -d "terraform/$${mod}" ]; then \
			echo "=== $${mod} ==="; \
			cd terraform/$${mod} && terraform apply -auto-approve && cd ../..; \
		fi; \
	done

destroy: ## Destroy all Terraform modules (reverse order)
	@for mod in $(shell echo "$(MODULES)" | tr ' ' '\n' | tac | tr '\n' ' '); do \
		if [ -d "terraform/$${mod}" ]; then \
			echo "=== $${mod} ==="; \
			cd terraform/$${mod} && terraform destroy -auto-approve && cd ../..; \
		fi; \
	done

fmt: ## Format all Terraform files
	terraform fmt -recursive terraform/

test: ## Run Lambda unit tests
	cd tests && pip install -q -r requirements-test.txt && pytest -v

test-glue: ## Run Glue PySpark unit tests
	cd tests && pip install -q pyspark pytest && pytest tests/glue/ -v

install: ## Install development dependencies
	pip install -q -r tests/requirements-test.txt
	pip install -q pre-commit ruff mypy
	pre-commit install

precommit: ## Run pre-commit hooks on all files
	pre-commit run --all-files

clean: ## Remove generated/compiled artifacts
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find terraform -type f -name "*.zip" -delete
