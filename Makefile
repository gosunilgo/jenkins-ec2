#
# Wrap the terraform commands with
#

STATEBUCKET = $(TF_VAR_s3_bucket)
PREFIX = $(TF_VAR_s3_bucket_prefix)

.PHONY: all plan apply destroy env init.txt

all: init.txt plan

get:
	terraform get -update

plan: get
	terraform plan

apply: get
	terraform apply

destroy:
	terraform destroy

env-%:
	@if [ "${${*}}" = "" ]; then \
	    echo "Environment variable $* must be set"; exit 1; \
    fi

# little hack target to prevent it running again without need
# for second nested Makefile
init.txt: env-TF_VAR_s3_bucket env-TF_VAR_s3_bucket_prefix
	terraform remote config -backend=s3 -backend-config="bucket=$(STATEBUCKET)" -backend-config="key=$(PREFIX)/terraform.tfstate"
	echo "ran terraform remote config -backend=s3 -backend-config=\"bucket=$(STATEBUCKET)\" -backend-config=\"key=$(PREFIX)/terraform.tfstate\"" > ./init.txt