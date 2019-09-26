#! /bin/bash
CLUSTER_NAME=hcp-pangeo

# Assumes you have already configured a 'circleci' user and awscli profile from 1_create_iam_user.sh
export AWS_DEFAULT_PROFILE=circleci
REGION=$(aws configure get region)
CLUSTER_TEMPLATE='./eksctl-config.yaml'

echo "Using AWS profile=$AWS_DEFAULT_PROFILE, region=$REGION"

set -ex
# Create cluster ssh key
KEY_NAME=eks-${CLUSTER_NAME}-${REGION}
echo "Creating key pair $KEY_NAME..."
aws ec2 create-key-pair --key-name ${KEY_NAME} | jq -r ".KeyMaterial" > ${KEY_NAME}.pem || true
chmod 400 ${KEY_NAME}.pem
ssh-keygen -y -f ${KEY_NAME}.pem > ${KEY_NAME}.pub || true

# Creating a new ECR repository
echo "Creating new ECR repository..."
aws ecr create-repository --repository-name ${CLUSTER_NAME} || true

# Create configuration file from template
CONFIG_FILE=eksctl-config-$CLUSTER_NAME.yaml
echo "Creating eksctl-config.yaml configuration file..."
sed -e "s/CHANGE_CLUSTER_NAME/$CLUSTER_NAME/g" -e "s/CHANGE_REGION/$REGION/g" -e "s/CHANGE_PUBLICKEY/${KEY_NAME}.pub/g" ${CLUSTER_TEMPLATE} > CONFIG_FILE

# Create EKS cluster
echo "Creating EKS cluster '$CLUSTER_NAME'..."
eksctl create cluster --config-file=${CONFIG_FILE}

# Might need to incorporate this somehow
# kubectl patch storageclass gp2 -p '{"volumeBindingMode": "WaitForFirstConsumer"}'

# Configure from Zero2JupyterHub Docs (maybe move to pangeo-cloud-federation repo and hubploy?)
# NOTE: need to ensure kubeconfig pointing to correct cluster at this point
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin
kubectl create serviceaccount tiller --namespace=kube-system
kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
kubectl --namespace=kube-system patch deployment tiller-deploy --type=json \
      --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'


echo "Done! to delete this cluster run 'eksctl delete cluster --name ${CLUSTER_NAME}'"
