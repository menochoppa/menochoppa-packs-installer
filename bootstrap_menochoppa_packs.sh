#!/usr/bin/env bash
# Wrapper for Arrakis Start that injects custom Menochoppa presets
# without modifying the upstream adbrasi/arrakis_start repository.

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERR]${NC} $1"; }

UPSTREAM_BOOTSTRAP_URL="${UPSTREAM_BOOTSTRAP_URL:-https://raw.githubusercontent.com/adbrasi/arrakis_start/main/bootstrap.sh}"
COMFY_BASE="${COMFY_BASE:-/workspace/comfy}"
ARRAKIS_DIR="${ARRAKIS_DIR:-$COMFY_BASE/arrakis_start}"
PRESETS_DIR="$ARRAKIS_DIR/presets"
HF_MODELS_REPO="${HF_MODELS_REPO:-menochoppa/comfy_models_pack}"
POLL_INTERVAL="${POLL_INTERVAL:-1}"
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-1800}"
VALIDATE_HF_ASSETS="${VALIDATE_HF_ASSETS:-0}"

REQUIRED_MODEL_PATHS=(
  "checkpoints/Better_Days.safetensors"
  "checkpoints/Hassaku.safetensors"
  "checkpoints/magicILL_magicILLEPSV10.safetensors"
  "checkpoints/waiIllustriousSDXL_v140.safetensors"
  "loras/Balecxi_Style_Illustrious-10.safetensors"
  "loras/DisneyStudios_style-12IL.safetensors"
  "loras/IFL_v1.0_IL.safetensors"
  "loras/Shexyo.safetensors"
  "loras/lightingSlider.safetensors"
  "loras/pantsushi.safetensors"
  "loras/princess_rc_il.safetensors"
  "loras/shexyo_style_trigger.safetensors"
)

write_preset_file() {
  local preset_file="$1"
  local preset_name="$2"
  local checkpoint="$3"
  local lora_a="$4"
  local lora_b="$5"

  cat > "$preset_file" <<JSON
{
  "name": "${preset_name}",
  "description": "Preset do Menochoppa com checkpoint e LoRAs dedicados.",
  "use_sage_attention": false,
  "comfyui_flags": [],
  "models": [
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/checkpoints/${checkpoint}",
      "dir": "checkpoints",
      "filename": "${checkpoint}"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/${lora_a}",
      "dir": "loras",
      "filename": "${lora_a}"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/${lora_b}",
      "dir": "loras",
      "filename": "${lora_b}"
    }
  ]
}
JSON
  log_success "Preset injected at $preset_file"
}

write_presets() {
  mkdir -p "$PRESETS_DIR"
  rm -f "$PRESETS_DIR/menochoppa-packs.json"

  write_preset_file "$PRESETS_DIR/meitabuu.json" "MEITABUU" \
    "Better_Days.safetensors" \
    "Balecxi_Style_Illustrious-10.safetensors" \
    "IFL_v1.0_IL.safetensors"

  write_preset_file "$PRESETS_DIR/studioneverai.json" "StudioneverAI" \
    "Hassaku.safetensors" \
    "Balecxi_Style_Illustrious-10.safetensors" \
    "Shexyo.safetensors"

  write_preset_file "$PRESETS_DIR/auroredrem3d.json" "Auroredrem3d" \
    "magicILL_magicILLEPSV10.safetensors" \
    "DisneyStudios_style-12IL.safetensors" \
    "princess_rc_il.safetensors"

  write_preset_file "$PRESETS_DIR/juliaverse.json" "Juliaverse" \
    "waiIllustriousSDXL_v140.safetensors" \
    "IFL_v1.0_IL.safetensors" \
    "shexyo_style_trigger.safetensors"

  write_preset_file "$PRESETS_DIR/rulegirl3d.json" "RuleGirl3d" \
    "waiIllustriousSDXL_v140.safetensors" \
    "pantsushi.safetensors" \
    "lightingSlider.safetensors"
}

validate_hf_assets() {
  if [ "$VALIDATE_HF_ASSETS" != "1" ]; then
    log_info "HF validation skipped for faster startup (set VALIDATE_HF_ASSETS=1 to enable)."
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    log_warn "python3 nao encontrado; pulando validacao do Hugging Face."
    return 0
  fi

  local auth_args=()
  if [ -n "${HF_TOKEN:-}" ]; then
    auth_args=(-H "Authorization: Bearer ${HF_TOKEN}")
  fi

  local tree_json
  if ! tree_json="$(curl -fsSL "${auth_args[@]}" "https://huggingface.co/api/models/${HF_MODELS_REPO}/tree/main?recursive=1")"; then
    log_warn "Nao foi possivel ler o repo ${HF_MODELS_REPO} no Hugging Face; seguindo mesmo assim."
    return 0
  fi

  local required_paths
  required_paths="$(printf '%s\n' "${REQUIRED_MODEL_PATHS[@]}")"

  REQUIRED_PATHS="$required_paths" TREE_JSON="$tree_json" python3 - <<'PY'
import json
import os
import sys

required = [line.strip() for line in os.environ.get("REQUIRED_PATHS", "").splitlines() if line.strip()]
tree = json.loads(os.environ["TREE_JSON"])
paths = {item.get("path", "") for item in tree}
missing = [path for path in required if path not in paths]

if missing:
    print("[WARN] Assets faltando no repo do Hugging Face:")
    for item in missing:
        print(f"  - {item}")
else:
    print("[OK] Todos os assets verificados do pack principal foram encontrados no repo do Hugging Face.")
PY
}

start_upstream_bootstrap() {
  log_info "Starting upstream Arrakis bootstrap in background..."
  (
    curl -fsSL "$UPSTREAM_BOOTSTRAP_URL" | bash
  ) &
  BOOTSTRAP_PID=$!
}

wait_for_arrakis_dir() {
  local waited=0

  while [ "$waited" -lt "$MAX_WAIT_SECONDS" ]; do
    if [ -d "$ARRAKIS_DIR" ]; then
      return 0
    fi

    if ! kill -0 "$BOOTSTRAP_PID" >/dev/null 2>&1; then
      return 1
    fi

    sleep "$POLL_INTERVAL"
    waited=$((waited + POLL_INTERVAL))
  done

  return 1
}

log_info "Preparing custom preset injection for Arrakis Start..."
log_info "Preset set: MEITABUU, StudioneverAI, Auroredrem3d, Juliaverse, RuleGirl3d"
log_info "HF repo: $HF_MODELS_REPO"
log_info "Presets baixam apenas checkpoints e LoRAs nas pastas padrao do ComfyUI."

validate_hf_assets
start_upstream_bootstrap

if [ -d "$ARRAKIS_DIR" ] || wait_for_arrakis_dir; then
  write_presets
else
  log_warn "Could not find $ARRAKIS_DIR before upstream bootstrap finished."
  log_warn "If the preset does not appear, rerun the wrapper after /workspace/comfy/arrakis_start exists."
fi

wait "$BOOTSTRAP_PID"
