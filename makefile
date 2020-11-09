.PHONY: build run test azure shell destroy

export DIR = $(shell pwd)
export WORK_DIR = $(shell dirname ${DIR})
export CONTAINER_IMAGE = 'f5-scca-terraform'

run: build shell

build:
	docker build -t ${CONTAINER_IMAGE} .

shell:
	@echo "tf shell ${WORK_DIR}"
	@docker run --rm -it \
	--volume ${DIR}:/workspace \
	-e ARM_CLIENT_ID=${ARM_CLIENT_ID} \
	-e ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET} \
	-e ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID} \
	-e ARM_TENANT_ID=${ARM_TENANT_ID} \
	-v ${SSH_KEY_DIR}/:/root/.ssh/:ro \
	${CONTAINER_IMAGE} \

azure:
	@#terraform init, plan, apply
	@echo "init, plan, apply"
	@docker run --rm -it \
	--volume ${DIR}:/workspace \
	-e ARM_CLIENT_ID=${ARM_CLIENT_ID} \
	-e ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET} \
	-e ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID} \
	-e ARM_TENANT_ID=${ARM_TENANT_ID} \
	${CONTAINER_IMAGE} \
	sh -c "terraform init; terraform plan; terraform apply --auto-approve"

gov:
	@#terraform init, plan, apply
	@echo "init, plan, apply"
	@docker run --rm -it \
	--volume ${DIR}:/workspace \
	-e ARM_CLIENT_ID=${ARM_CLIENT_ID} \
	-e ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET} \
	-e ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID} \
	-e ARM_TENANT_ID=${ARM_TENANT_ID} \
	-e ARM_ENVIRONMENT=${ARM_ENVIRONMENT} \
	${CONTAINER_IMAGE} \
	sh -c "terraform init; terraform plan; terraform apply --auto-approve"

plan:
	@#terraform plan
	@echo "plan"
	@docker run --rm -it \
	--volume ${DIR}:/workspace \
	-e ARM_CLIENT_ID=${ARM_CLIENT_ID} \
	-e ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET} \
	-e ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID} \
	-e ARM_TENANT_ID=${ARM_TENANT_ID} \
	${CONTAINER_IMAGE} \
	sh -c "terraform plan"

destroy:
	@#terraform destroy --auto-approve
	@echo "destroy"
	@docker run --rm -it \
	--volume ${DIR}:/workspace \
	-e ARM_CLIENT_ID=${ARM_CLIENT_ID} \
	-e ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET} \
	-e ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID} \
	-e ARM_TENANT_ID=${ARM_TENANT_ID} \
	${CONTAINER_IMAGE} \
	sh -c "terraform destroy --auto-approve"

revolution:
	@#terraform destroy --auto-approve
	@echo "destroy"
	@docker run --rm -it \
	--volume ${DIR}:/workspace \
	-e ARM_CLIENT_ID=${ARM_CLIENT_ID} \
	-e ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET} \
	-e ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID} \
	-e ARM_TENANT_ID=${ARM_TENANT_ID} \
	-e ARM_ENVIRONMENT=${ARM_ENVIRONMENT} \
	${CONTAINER_IMAGE} \
	sh -c "terraform destroy --auto-approve"

test: build test1 test2 test3

test1:
	@echo "terraform install"
	@docker run --rm -it \
	--volume ${DIR}:/workspace \
	-e ARM_CLIENT_ID=${ARM_CLIENT_ID} \
	-e ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET} \
	-e ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID} \
	-e ARM_TENANT_ID=${ARM_TENANT_ID} \
	${CONTAINER_IMAGE} \
	sh -c "terraform --version "
test2:
	@echo "terraform init"
	@docker run --rm -it \
	--volume ${DIR}:/workspace \
	-e ARM_CLIENT_ID=${ARM_CLIENT_ID} \
	-e ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET} \
	-e ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID} \
	-e ARM_TENANT_ID=${ARM_TENANT_ID} \
	${CONTAINER_IMAGE} \
	sh -c "terraform init "
test3:
	@echo "terraform validate"
	@docker run --rm -it \
	--volume ${DIR}:/workspace \
	-e ARM_CLIENT_ID=${ARM_CLIENT_ID} \
	-e ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET} \
	-e ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID} \
	-e ARM_TENANT_ID=${ARM_TENANT_ID} \
	${CONTAINER_IMAGE} \
	sh -c "terraform validate "
