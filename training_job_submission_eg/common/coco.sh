#!/bin/bash
# scripts/azure/configs/coco.sh
# COCO dataset configuration for Azure runs.
# Source this after azure_common.sh.

IN_DATA_PATH="$(datastore_path 'datasets/coco')"

CFG="cfg/training/yolov7-tiny.yaml"
HYP_FULL="data/hyp.scratch.tiny.yaml"

EPOCHS=300
BATCH_SIZE=32
IMG_SIZE="640 640"
WORKERS=8
DEVICE=0
