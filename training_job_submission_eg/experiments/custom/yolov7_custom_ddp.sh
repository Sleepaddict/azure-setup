#!/bin/bash
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPTS_DIR/configs/azure_common.sh"
source "$SCRIPTS_DIR/configs/custom.sh"
HYP="$HYP_FULL"
DATA_SETUP_CMD="$(custom_data_setup)" #takes from custom.sh
# DDP config
NUM_GPUS=2
# You can overrride whatever configs are in custom.sh 
BATCH_SIZE=64
EPOCHS=3
IMG_SIZE="1280 1280"
WORKERS=16
source "$SCRIPTS_DIR/runs/submit_yolov7_ddp.sh" \
    yolov7_debug \
    debug_finetune \
    "artifacts/debug_finetune" \
    "" # Leave blank if training from scratch