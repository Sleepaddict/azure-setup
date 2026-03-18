#!/usr/bin/env bash

# Default parameters
SUFFIX="user1234"
RESOURCE_GROUP="proj-dev-${SUFFIX}"
RESOURCE_PROVIDER="Microsoft.MachineLearningServices"
REGION="koreacentral"
WORKSPACE_NAME="mlw-proj-dev-${SUFFIX}"
COMPUTE_INSTANCE="ci${SUFFIX}"
INSTANCE_SIZE="Standard_NC40ads_H100_v5"
COMPUTE_CLUSTER="aml-cluster${SUFFIX}"
CLUSTER_SIZE="Standard_NC80adis_H100_v5"
CLUSTER_MAX_INSTANCE=2

# Help message
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --suffix STR        Suffix to add to workspace/resource group/compute instance names (default: user1234)"
  echo "  --resource_grp STR  Name to use for resource group (default: proj-dev)"
  echo "  --region STR        Region to host resources (default: koreacentral)"
  echo "  --workspace STR     Name to use for Machine Learning workspace (default: mlw-proj-dev)"
  echo "  --inst_name STR     Name to use for compute instance (default: ci)"
  echo "  --inst_size STR     Size of compute instance to use (default: Standard_NC40ads_H100_v5)"
  echo "  --clust_name STR    Name to use for compute cluster (default: aml-cluster)"
  echo "  --clust_size STR    Size of compute cluster to use (default: Standard_NC80adis_H100_v5)"
  echo "  --clust_max_node INT  Max instance for compute cluster (default: 2)"
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --suffix)
      SUFFIX="$2"
      shift 2
      ;;
    --resource_grp)
      RESOURCE_GROUP="$2-${SUFFIX}"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --workspace)
      WORKSPACE_NAME="$2-${SUFFIX}"
      shift 2
      ;;
    --inst_name)
      COMPUTE_INSTANCE="$2${SUFFIX}"
      shift 2
      ;;
    --inst_size)
      INSTANCE_SIZE="$2"
      shift 2
      ;;
    --clust_name)
      COMPUTE_CLUSTER="$2${SUFFIX}"
      shift 2
      ;;
    --clust_size)
      CLUSTER_SIZE="$2"
      shift 2
      ;;
    --clust_max_node)
      CLUSTER_MAX_INSTANCE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      show_help
      ;;
  esac
done

# Print config
echo "Suffix: $SUFFIX"
echo "Resource Group: $RESOURCE_GROUP"
echo "Region: $REGION"
echo "Resource Provider: $RESOURCE_PROVIDER"
echo "Workspace: $WORKSPACE_NAME"
echo "Compute Instance: $COMPUTE_INSTANCE"
echo "CI size: $INSTANCE_SIZE"
echo "Compute Cluster: $COMPUTE_CLUSTER"
echo "CC size: $CLUSTER_SIZE"
echo "Cluster max nodes: $CLUSTER_MAX_INSTANCE"

# Register the Azure Machine Learning resource provider in the subscription
echo "Register the Machine Learning resource provider:"
az provider register --namespace $RESOURCE_PROVIDER

# Create the resource group and workspace and set to default
echo "Create a resource group and set as default:"
az group create --name $RESOURCE_GROUP --location $REGION
az configure --defaults group=$RESOURCE_GROUP

echo "Create an Azure Machine Learning workspace:"
az ml workspace create --name $WORKSPACE_NAME 
az configure --defaults workspace=$WORKSPACE_NAME

# Create compute instance
echo "Creating a compute instance with name: " $COMPUTE_INSTANCE
az ml compute create --name ${COMPUTE_INSTANCE} --size $INSTANCE_SIZE --type ComputeInstance

# Create compute cluster
echo "Creating a compute cluster with name: " $COMPUTE_CLUSTER
az ml compute create --name ${COMPUTE_CLUSTER} --size $CLUSTER_SIZE --max-instances $CLUSTER_MAX_INSTANCE --type AmlCompute 