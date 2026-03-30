#!/usr/bin/env bash
# Baixa apenas os checkpoints e LoRAs extras do pack do Menochoppa
# depois que o ImageStudioArrakis2.sh original ja instalou o resto.

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

COMFY_DIR="${COMFY_DIR:-/root/comfy/ComfyUI}"
MODELS_DIR="${MODELS_DIR:-$COMFY_DIR/models}"
HF_MODELS_REPO="${HF_MODELS_REPO:-menochoppa/comfy_models_pack}"
HF_TOKEN="${HF_TOKEN:-}"

DOWNLOAD_FILES=(
  "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/checkpoints/magicILL_magicILLEPSV10.safetensors|checkpoints|magicILL_magicILLEPSV10.safetensors"
  "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/checkpoints/waiIllustriousSDXL_v140.safetensors|checkpoints|waiIllustriousSDXL_v140.safetensors"
  "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/Balecxi_Style_Illustrious-10.safetensors|loras|Balecxi_Style_Illustrious-10.safetensors"
  "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/DisneyStudios_style-12IL.safetensors|loras|DisneyStudios_style-12IL.safetensors"
  "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/IFL_v1.0_IL.safetensors|loras|IFL_v1.0_IL.safetensors"
  "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/Shexyo.safetensors|loras|Shexyo.safetensors"
  "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/lightingSlider.safetensors|loras|lightingSlider.safetensors"
  "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/pantsushi.safetensors|loras|pantsushi.safetensors"
  "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/princess_rc_il.safetensors|loras|princess_rc_il.safetensors"
  "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/shexyo_style_trigger.safetensors|loras|shexyo_style_trigger.safetensors"
)

download_hf() {
  local url="$1"
  local target_dir="$2"
  local filename="$3"

  mkdir -p "$target_dir"

  if [ -f "$target_dir/$filename" ]; then
    log_success "Ja existe: $filename"
    return 0
  fi

  log_info "Baixando: $filename"

  local aria_headers=()
  local curl_args=(-fL -o "$target_dir/$filename")
  local wget_args=(-q --show-progress -c -O "$target_dir/$filename")
  if [ -n "$HF_TOKEN" ]; then
    aria_headers+=(--header="Authorization: Bearer ${HF_TOKEN}")
    curl_args+=(-H "Authorization: Bearer ${HF_TOKEN}")
    wget_args+=(--header="Authorization: Bearer ${HF_TOKEN}")
  fi

  if command -v aria2c >/dev/null 2>&1; then
    aria2c -c -x 4 -s 4 --console-log-level=warn "${aria_headers[@]}" --dir="$target_dir" --out="$filename" "$url" || \
    curl "${curl_args[@]}" "$url" || \
    wget "${wget_args[@]}" "$url" || {
      log_error "Download falhou: $filename"
      return 1
    }
  else
    curl "${curl_args[@]}" "$url" || \
    wget "${wget_args[@]}" "$url" || {
      log_error "Download falhou: $filename"
      return 1
    }
  fi
}

log_info "Baixando extras do pack do Menochoppa para $MODELS_DIR"

for entry in "${DOWNLOAD_FILES[@]}"; do
  IFS='|' read -r url type filename <<< "$entry"
  download_hf "$url" "$MODELS_DIR/$type" "$filename"
done

log_success "Downloads finalizados."
