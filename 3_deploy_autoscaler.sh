#! /bin/bash
CLUSTER_NAME=hcp-pangeo

export AWS_DEFAULT_PROFILE=circleci
AUTOSCALER_TEMPLATE=./templates/template-cluster-autoscaler-autodiscovery.yaml
AUTOSCALER_PERMISSIONS=./templates/template-autoscaler-permissions.json
# NOTE: version mappings 1.3.8 : 1.11,   1.12.6 : 1.12,   1.13.5 : 1.13
AUTOSCALER_VERSION="1.13.7"
REGION=$(aws configure get region)

echo "Configuring autoscaling on EKS cluster [$CLUSTER_NAME]..."

# Node/instance that autoscaler is running on needs permissions to launch other machines
# https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#scaling-a-node-group-to-0
HUB_ROLE=$(eksctl utils describe-stacks --name $CLUSTER_NAME --profile AWS_DEFAULT_PROFILE | grep eksctl-$CLUSTER_NAME-nodegroup-hub-NodeInstanceRole --color=never | cut -d'/' -f2 | tr -d '"')
aws iam create-policy --policy-name cluster-autoscaler --policy-document file://${AUTOSCALER_PERMISSIONS}
aws iam put-role-policy --role-name $HUB_ROLE --policy-name cluster-autoscaler --policy-document file://${AUTOSCALER_PERMISSIONS}

echo "Applying autoscaler configuration cluster-autoscaler.yaml..."
sed -e "s/CHANGE_CLUSTER_NAME/$CLUSTER_NAME/g" -e "s/CHANGE_AUTOSCALER_VERSION/${AUTOSCALER_VERSION}/g" ${AUTOSCALER_TEMPLATE} > cluster-autoscaler.yaml
kubectl apply -f cluster-autoscaler.yaml

echo "Cluster autoscaler version ${AUTOSCALER_VERSION} enabled on ${CLUSTER_NAME}!"
