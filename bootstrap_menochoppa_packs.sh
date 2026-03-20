#!/usr/bin/env bash
# Wrapper for Arrakis Start that injects the "menochoppa Packs" preset
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
PRESET_FILE="${PRESET_FILE:-$PRESETS_DIR/menochoppa-packs.json}"
PRESET_NAME="${PRESET_NAME:-menochoppa Packs}"
HF_MODELS_REPO="${HF_MODELS_REPO:-menochoppa/comfy_models_pack}"
POLL_INTERVAL="${POLL_INTERVAL:-2}"
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-1800}"

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
  "sams/sam_vit_b_01ec64.pth"
  "ultralytics/bbox/Anzhc_Faceseg_1024_v2_y8n.pt"
  "ultralytics/bbox/ntd11_anime_nsfw_segm_v5-variant1.pt"
  "upscale_models/2x-AnimeSharpV4_Fast_RCAN_PU.safetensors"
  "upscale_models/4x-AnimeSharp.pth"
)

write_preset() {
  mkdir -p "$PRESETS_DIR"
  cat > "$PRESET_FILE" <<JSON
{
  "name": "${PRESET_NAME}",
  "description": "Pack do Menochoppa com modelos e embeddings usados no workflow_geracao_2026V19.",
  "use_sage_attention": false,
  "comfyui_flags": [],
  "models": [
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/checkpoints/Better_Days.safetensors",
      "dir": "checkpoints",
      "filename": "Better_Days.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/checkpoints/Hassaku.safetensors",
      "dir": "checkpoints",
      "filename": "Hassaku.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/checkpoints/magicILL_magicILLEPSV10.safetensors",
      "dir": "checkpoints",
      "filename": "magicILL_magicILLEPSV10.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/checkpoints/waiIllustriousSDXL_v140.safetensors",
      "dir": "checkpoints",
      "filename": "waiIllustriousSDXL_v140.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/Balecxi_Style_Illustrious-10.safetensors",
      "dir": "loras",
      "filename": "Balecxi_Style_Illustrious-10.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/DisneyStudios_style-12IL.safetensors",
      "dir": "loras",
      "filename": "DisneyStudios_style-12IL.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/IFL_v1.0_IL.safetensors",
      "dir": "loras",
      "filename": "IFL_v1.0_IL.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/Shexyo.safetensors",
      "dir": "loras",
      "filename": "Shexyo.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/lightingSlider.safetensors",
      "dir": "loras",
      "filename": "lightingSlider.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/pantsushi.safetensors",
      "dir": "loras",
      "filename": "pantsushi.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/princess_rc_il.safetensors",
      "dir": "loras",
      "filename": "princess_rc_il.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/shexyo_style_trigger.safetensors",
      "dir": "loras",
      "filename": "shexyo_style_trigger.safetensors"
    },
    {
      "url": "https://huggingface.co/NeigeSnowflake/neigeworkflow/resolve/main/lazyneg.safetensors",
      "dir": "embeddings",
      "filename": "lazyneg.safetensors"
    },
    {
      "url": "https://huggingface.co/NeigeSnowflake/neigeworkflow/resolve/main/lazypos.safetensors",
      "dir": "embeddings",
      "filename": "lazypos.safetensors"
    },
    {
      "url": "https://huggingface.co/datasets/WhiteAiZ/sd-webui-forge-classic/resolve/main/models/embeddings/Smooth_Negative-neg.safetensors",
      "dir": "embeddings",
      "filename": "Smooth_Negative-neg.safetensors"
    },
    {
      "url": "https://huggingface.co/Coercer/Lora_Compilation/resolve/main/Smooth_Quality.safetensors",
      "dir": "embeddings",
      "filename": "Smooth_Quality.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/upscale_models/2x-AnimeSharpV4_Fast_RCAN_PU.safetensors",
      "dir": "upscale_models",
      "filename": "2x-AnimeSharpV4_Fast_RCAN_PU.safetensors"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/upscale_models/4x-AnimeSharp.pth",
      "dir": "upscale_models",
      "filename": "4x-AnimeSharp.pth"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/sams/sam_vit_b_01ec64.pth",
      "dir": "sams",
      "filename": "sam_vit_b_01ec64.pth"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/ultralytics/bbox/Anzhc_Faceseg_1024_v2_y8n.pt",
      "dir": "ultralytics/bbox",
      "filename": "Anzhc_Faceseg_1024_v2_y8n.pt"
    },
    {
      "url": "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/ultralytics/bbox/ntd11_anime_nsfw_segm_v5-variant1.pt",
      "dir": "ultralytics/bbox",
      "filename": "ntd11_anime_nsfw_segm_v5-variant1.pt"
    }
  ],
  "nodes": [
    "https://github.com/adbrasi/cezarsave34",
    "https://github.com/adbrasi/comfydodi",
    "https://github.com/adbrasi/futfilter",
    "https://github.com/adbrasi/pixivmosaic",
    "https://github.com/adbrasi/prompta_generita",
    "https://github.com/adbrasi/randomico",
    "https://github.com/adbrasi/randomsizito",
    "https://github.com/Cezarsaint/blacklisto",
    "https://github.com/Cezarsaint/rand0micoUploaderLoven",
    "https://github.com/Extraltodeus/ComfyUI-AutomaticCFG",
    "https://github.com/Jonseed/ComfyUI-Detail-Daemon",
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack",
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack",
    "https://github.com/omar92/ComfyUI-QualityOfLifeSuit_Omar92",
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts",
    "https://github.com/pythongosssss/ComfyUI-WD14-Tagger",
    "https://github.com/rgthree/rgthree-comfy",
    "https://github.com/sipherxyz/comfyui-art-venture",
    "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes",
    "https://github.com/TinyTerra/ComfyUI_tinyterraNodes",
    "https://github.com/WASasquatch/was-node-suite-comfyui"
  ]
}
JSON
  log_success "Preset injected at $PRESET_FILE"
}

validate_hf_assets() {
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
    print("[OK] Todos os assets do workflow foram encontrados no repo do Hugging Face.")
PY
}

start_upstream_bootstrap() {
  log_info "Starting upstream Arrakis bootstrap in background..."
  (
    curl -fsSL "$UPSTREAM_BOOTSTRAP_URL" | bash
  ) &
  BOOTSTRAP_PID=$!
  export BOOTSTRAP_PID
}

wait_for_preset_target() {
  local waited=0

  while [ "$waited" -lt "$MAX_WAIT_SECONDS" ]; do
    if [ -d "$PRESETS_DIR" ]; then
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
log_info "Preset name: $PRESET_NAME"
log_info "HF repo: $HF_MODELS_REPO"

validate_hf_assets
start_upstream_bootstrap

if wait_for_preset_target; then
  write_preset
else
  log_warn "Could not find $PRESETS_DIR before upstream bootstrap finished."
  log_warn "If the preset does not appear, rerun the wrapper after /workspace/comfy/arrakis_start exists."
fi

wait "$BOOTSTRAP_PID"
