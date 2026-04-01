#!/bin/bash
# Source this in all Azure experiment scripts.

# ── Azure ML infrastructure ───────────────────────────────────────────────────
SUBSCRIPTION=<YOUR_SUBSCRIPTION>
RESOURCE_GROUP=<YOUR RESOURCE GROUP>
WORKSPACE=<YOUR WORKSPACE>
DATASTORE=<YOUR DATASTORE>
COMPUTE="aml-clusteruser1234"


# ── Code and environment ──────────────────────────────────────────────────────
CODE="./blob_mount/codes/<your_training_code_root>/"
ENV_FILE="./azure-setup/sample_env.yaml"
ENV_NAME="<your_env_name>"
SUBMIT_SCRIPT="./azure-setup/sample_submit_job.py"


# ── Helper: build datastore path ─────────────────────────────────────────────
datastore_path() {
    # Usage: datastore_path "datasets/coco"
    echo "azureml://subscriptions/${SUBSCRIPTION}/resourcegroups/${RESOURCE_GROUP}/workspaces/${WORKSPACE}/datastores/${DATASTORE}/paths/${1}"
}


# ── Data setup command (prepended to every training cmd) ─────────────────────
# Rewrites data/coco.yaml and image list files to use the mounted data path.
coco_data_setup() {
    cat << 'SETUP'
export DATA_ROOT=${{inputs.input_data}} && \
sed -i "s|^train:.*|train: $DATA_ROOT/train2017.txt|" data/coco.yaml && \
sed -i "s|^val:.*|val: $DATA_ROOT/val2017.txt|" data/coco.yaml && \
sed -i "s|^test:.*|test: $DATA_ROOT/test-dev2017.txt|" data/coco.yaml && \
sed -i "s|^\./||" $DATA_ROOT/train2017.txt && sed -i "s|^|$DATA_ROOT/|" $DATA_ROOT/train2017.txt && \
sed -i "s|^\./||" $DATA_ROOT/val2017.txt && sed -i "s|^|$DATA_ROOT/|" $DATA_ROOT/val2017.txt && \
sed -i "s|^\./||" $DATA_ROOT/test-dev2017.txt && sed -i "s|^|$DATA_ROOT/|" $DATA_ROOT/test-dev2017.txt
SETUP
}