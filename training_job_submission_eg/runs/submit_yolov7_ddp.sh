#!/bin/bash
# scripts/azure/runs/submit_baseline.sh
#
# Reusable Azure baseline launcher.
# Source dataset config before calling this.
#
# Required env vars:
#   CODE, SUBMIT_SCRIPT, ENV_FILE, ENV_NAME, COMPUTE
#   IN_DATA_PATH, CFG, HYP, DATA, EPOCHS, BATCH_SIZE, IMG_SIZE, WORKERS, DEVICE
#   DATA_SETUP_CMD (string containing the data path setup commands)
#
# Args:
#   $1 — run name         (e.g. "yolov7_training")
#   $2 — experiment name  (e.g. "debug")
#   $3 — output subpath   (e.g. "artifacts/debug")
#   $4 — weights [Optional]         (e.g. yolov7_training.pt)

RUN_NAME="${1:?'run name required as \$1'}"
EXPT_NAME="${2:?'experiment name required as \$2'}"
OUT_SUBPATH="${3:?'output subpath required as \$3'}"
WEIGHTS="${4:-''}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPTS_DIR/configs/azure_common.sh"

OUT_DATA_PATH="$(datastore_path "$OUT_SUBPATH")"
if [ -n "$WEIGHTS" ]; then
    WEIGHTS_DATA_PATH="$(datastore_path 'weights')"
    WEIGHTS_DATA_ARG="--weightsdatapath $WEIGHTS_DATA_PATH"
    WEIGHTS_ARG="--weights \${{inputs.weights_data}}/$WEIGHTS"
else
    WEIGHTS_DATA_ARG=""
    WEIGHTS_ARG=""
fi
CMD="${DATA_SETUP_CMD} && \\
torchrun --nproc_per_node=${NUM_GPUS} --master_port=29500 train_equivariant.py \\
  --workers ${WORKERS} \\
  --batch-size ${BATCH_SIZE} \\
  --data ${DATA} \\
  --img-size ${IMG_SIZE} \\
  --cfg ${CFG} \\
  --name ${RUN_NAME} \\
  --hyp ${HYP} \\
  ${WEIGHTS_ARG:+$WEIGHTS_ARG} \
  --project \${{outputs.output_data}} \\
  --epochs ${EPOCHS} \\
  --noautoanchor \\
  --sync-bn"

echo "Submitting: $RUN_NAME [DDP x${NUM_GPUS}]"
python "$SUBMIT_SCRIPT" \
    --code        "$CODE"          \
    --cmd         "$CMD"           \
    --indatapath  "$IN_DATA_PATH"  \
    --outdatapath "$OUT_DATA_PATH" \
    ${WEIGHTS_DATA_ARG:+$WEIGHTS_DATA_ARG} \
    --store_local                  \
    --env         "$ENV_FILE"      \
    --env_name    "$ENV_NAME"      \
    --compute     "$COMPUTE"       \
    --display_name "$RUN_NAME"     \
    --expt_name   "$EXPT_NAME"
