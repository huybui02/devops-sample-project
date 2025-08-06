APP_NAME := latency-monitor
AWS_ACCOUNT_ID := 123456789012 # Assume that it is my AWS account ID
AWS_REGION := ap-southeast-1
ECR_REPO := $(APP_NAME)
TAG := latest

ECR_URI := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO)

INFRA_DIR := infrastructure/environment/dev
PING_HOST := $(shell terraform -chdir=$(INFRA_DIR) output -json ec2_public_ips | jq -r '.["1"]')

build:
	docker build --build-arg PING_HOST=$(PING_HOST) -t $(APP_NAME):$(TAG) .
tag:
	docker tag $(APP_NAME):$(TAG) $(ECR_URI):$(TAG)

login:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

push: login build tag
	docker push $(ECR_URI):$(TAG)

deploy: push
	@echo "Image pushed to: $(ECR_URI):$(TAG)"
