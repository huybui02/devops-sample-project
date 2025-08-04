TF=terraform
TF_FLAGS=-auto-approve

init:
	$(TF) init

plan:
	$(TF) plan

apply:
	$(TF) apply $(TF_FLAGS)

destroy:
	$(TF) destroy $(TF_FLAGS)

validate:
	$(TF) validate

clean:
	rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl

tf-provision-all: init apply output
