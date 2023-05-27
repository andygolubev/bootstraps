#!/bin/bash

# This script is for a sandbox environment setup (in us-east-1 region)
# Run localy with the configured aws cli profile

export AWS_PROFILE=aws_sandbox
aws s3api create-bucket --bucket devops-directive-tf-state-123-us-east-1 --region us-east-1
aws s3api put-bucket-versioning --bucket devops-directive-tf-state-123-us-east-1 --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket devops-directive-tf-state-123-us-east-1 --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
aws dynamodb create-table --table-name terraform-state-locking-us-east-1  --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --tags Key=Name,Value="terraform state dynamo table" Key=CreatedBy,Value="AWS CLI" Key=Region,Value=us-east-1 

cp -r ../AWS /tmp
rm -rf /tmp/AWS/.*
rm -rf /tmp/AWS/terraform.tfstate*   

# Create local state

rm /tmp/AWS/00-provider.tf
cat << EOF | tee /tmp/AWS/00-provider.tf
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = " ~> 4.0"
        }
  }
}

provider "aws" {
    region =  var.aws_region
}

EOF

terraform -chdir=/tmp/AWS/ init -var-file=terraform.tfvars.test
terraform -chdir=/tmp/AWS/ plan -var-file=terraform.tfvars.test
terraform -chdir=/tmp/AWS/ apply --auto-approve -var-file=terraform.tfvars.test

# transfer state to the s3 bucket

rm /tmp/AWS/00-provider.tf
cat << EOF | tee /tmp/AWS/00-provider.tf
terraform {
    backend "s3" {
        bucket = "devops-directive-tf-state-123-us-east-1"
        key = "tf-infra/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "terraform-state-locking-us-east-1"
        encrypt = true
    }

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = " ~> 4.0"
        }
  }

}

provider "aws" {
    region =  var.aws_region
}

EOF

terraform -chdir=/tmp/AWS/ init -force-copy -var-file=terraform.tfvars.test
terraform -chdir=/tmp/AWS/ plan -var-file=terraform.tfvars.test
terraform -chdir=/tmp/AWS/ apply --auto-approve -var-file=terraform.tfvars.test

rm -rf /tmp/AWS/

unset AWS_PROFILE
