#!/bin/bash
# scripts/azure/configs/custom.sh
# Custom dataset configuration for Azure runs.
# Source this after azure_common.sh.
# Update DATASET_NAME and data setup command to match your dataset.

DATASET_NAME="your_dataset"   # <-- update this (subfolder under datasets/)
IN_DATA_PATH="$(datastore_path "datasets/${DATASET_NAME}")"

CFG="cfg/training/yolov7-tiny.yaml"
HYP_FULL="data/hyp.scratch.tiny.yaml"

EPOCHS=600
BATCH_SIZE=16
IMG_SIZE="640 640"
WORKERS=8
DEVICE=0

# Custom dataset data setup — update paths to match your dataset structure
custom_data_setup() {
    cat << 'SETUP'
export DATA_ROOT=${{inputs.input_data}} && \
sed -i "s|^train:.*|train: $DATA_ROOT/train.txt|" data/your_dataset.yaml && \
sed -i "s|^val:.*|val: $DATA_ROOT/val.txt|" data/your_dataset.yaml && \
sed -i "s|^\./||" $DATA_ROOT/train.txt && sed -i "s|^|$DATA_ROOT/|" $DATA_ROOT/train.txt && \
sed -i "s|^\./||" $DATA_ROOT/val.txt && sed -i "s|^|$DATA_ROOT/|" $DATA_ROOT/val.txt
SETUP
}
