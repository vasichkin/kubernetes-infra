.PHONY: init plan apply destroy validate verify setup-tfvars

# terraform.tfvars is auto-loaded by OpenTofu; no -var-file needed.

init:
	tofu init -backend-config=backend.hcl

setup-tfvars:
	@test -f terraform.tfvars || (cp terraform.tfvars.example terraform.tfvars && echo "Created terraform.tfvars from example — edit before apply")

plan:
	tofu plan

apply:
	tofu apply

destroy:
	tofu destroy

validate:
	tofu validate

verify:
	KUBECONFIG=$$(pwd)/kubeconfigs/config ./scripts/verify-prometheus-autodiscovery.sh
