#!/bin/bash
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPTS_DIR/common/azure_common.sh"
source "$SCRIPTS_DIR/common/coco.sh"
HYP="$HYP_FULL"
DATA_SETUP_CMD="$(coco_data_setup)"
# DDP config
NUM_GPUS=2
# You can overrride whatever configs are in coco.sh 
BATCH_SIZE=64
EPOCHS=3
IMG_SIZE="1280 1280"
WORKERS=16
source "$SCRIPTS_DIR/runs/submit_yolov7_ddp.sh" \
    yolov7_debug \
    debug_ddp_no_init \
    "artifacts/yolov7_debug_ddp" \
    "" # Leave blank if training from scratch
