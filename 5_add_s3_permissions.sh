#! /bin/bash

# Connect S3 bucket to JupyterHub (aws s3 cp)
# NOTE: need to get roles programmatically... (won't run as a general script yet.)

export AWS_DEFAULT_PROFILE=circleci
REGION=$(aws configure get region)
CLUSTER_NAME=hcp-pangeo
POLICYARN=CHANGE
#POLICYARN=$(aws iam create-policy --policy-name my-policy --policy-document file://policy)

# Policy needs to be attached to both dask workers and user notebooks
# Or vice versa? could probably attach a policy to the bucket
# Add nodegroup NodeInstanceRole
aws iam attach-role-policy --role-name CHANGE_DASK_NODE --policy-arn $POLICYARN

aws iam attach-role-policy --role-name CHANGE_USER_NODE --policy-arn $POLICYARN
