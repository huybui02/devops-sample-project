INFRA_DIR := infrastructure
APP_DIR := latency-app
ANSIBLE_DIR := ansible
IMAGE_TAG ?= latest

infra-provision:
	cd $(INFRA_DIR) && make tf-provision-all

app-deploy:
	cd $(APP_DIR) && make push TAG=$(IMAGE_TAG)

generate-inventory:
	@echo "Generating Ansible inventory from Terraform output..."
	terraform -chdir=$(INFRA_DIR) output -json ec2_public_ips | \
	jq -r '.["0"]' | \
	xargs -I {} echo "ec2 ansible_host={} ansible_user=ubuntu ansible_ssh_private_key_file=$(INFRA_DIR)/keys/id_rsa" \
	> $(ANSIBLE_DIR)/inventory

ansible-deploy:
	ansible-playbook -i $(ANSIBLE_DIR)/inventory $(ANSIBLE_DIR)/playbook.yml --extra-vars "image_tag=$(IMAGE_TAG)"

all: infra-provision app-deploy generate-inventory ansible-deploy

update-app:
    app-deploy ansible-deploy