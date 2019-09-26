#!/bin/bash

# Necessary to set up a hub with NFS home storage

REGION=$(aws configure get region)
CLUSTER_NAME=hcp-pangeo

# Create EFS volume in same VPC as cluster
echo "Created EKS cluster [$CLUSTER_NAME]. Now adding EFS volume in same VPC..."
VPC=$(aws eks describe-cluster --name ${CLUSTER_NAME} | jq -r ".cluster.resourcesVpcConfig.vpcId")
SUBNETS_PUBLIC=($(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC" "Name=tag:Name,Values=*PublicRouteTable*" | jq -r ".RouteTables[].Associations[].SubnetId"))
SG_NODES_SHARED=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC" "Name=tag:Name,Values=*ClusterSharedNodeSecurityGroup*" | jq -r ".SecurityGroups[].GroupId")

#An error occurred (IncorrectFileSystemLifeCycleState) when calling the CreateMountTarget operation: None
# I think we need to wait until EFS is fully created before running create-mount-target
EFSID=$(aws efs create-file-system --creation-token newefs --tags "Key=Name,Value=$CLUSTER_NAME" | jq -r ".FileSystemId")
for i in "${SUBNETS_PUBLIC[@]}"
do
	aws efs create-mount-target --file-system-id $EFSID --subnet-id $i --security-groups $SG_NODES_SHARED
done

# Install EFS provisioner
#helm upgrade --install --namespace kube-system efs-provisioner stable/efs-provisioner \
#     --set efsProvisioner.efsFileSystemId=$EFSID \
#     --set efsProvisioner.awsRegion=$REGION \

# Change the default storageClass (for now, given there's a bug in efs provisioner, this needs to be two steps).
#kubectl patch storageclass gp2 -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}' || true
#kubectl patch storageclass efs -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}' || true
