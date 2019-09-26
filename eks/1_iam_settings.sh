#! /bin/bash

# Deploy EKS cluster and EFS storage on AWS for Pangeo JupyterHub

#1) Create IAM user w/ adequate permissions for EKS cluster management - need to check on separate account! NOTE: probably have to run this as admin user
# https://github.com/weaveworks/eksctl/issues/204
#aws iam create-user --user-name circle-ci-deploy

#ACCOUNT=CHANGE_ME
#echo "Assigning inline policy to circle-ci-deploy..."
#sed -e "s/CHANGE_ACCOUNT_NUMBER/$ACCOUNT/g" ./templates/template-eksctl-permissions.json > eksctl-permissions.json
#aws iam create-policy --policy-name eksctl-permissions --policy-document file://eksctl-permissions.json
#aws iam attach-user-policy --policy-arn arn:aws:iam::$ACCOUNT:policy/eksctl-permissions --user-name circle-ci-deploy


#2) CUSTOMIZE configuration and permissions
#KEY=CHANGE
#SECRET_KEY=CHANGE
#aws configure set aws_access_key_id ${KEY}
#aws configure set aws_secret_access_key ${SECRET_KEY}

PROFILE=circleci
REGION="us-east-1"
aws configure set region ${REGION} --profile circleci
aws configure set output json --profile circleci

echo "using aws profile: $PROFILE"
echo "using region: $REGION"
