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
  "embeddings/lazyneg.safetensors"
  "embeddings/lazypos.safetensors"
  "embeddings/Smooth_Negative-neg.safetensors"
  "embeddings/Smooth_Quality.safetensors"
  "sams/sam_vit_b_01ec64.pth"
  "ultralytics/bbox/Anzhc_Faceseg_1024_v2_y8n.pt"
  "ultralytics/bbox/Eyeful_v2-Paired.pt"
  "ultralytics/bbox/hand_yolov8s.pt"
  "ultralytics/bbox/ntd11_anime_nsfw_segm_v5-variant1.pt"
  "ultralytics/bbox/99coins_anime_girl_face_m_seg.pt"
  "upscale_models/2x-AnimeSharpV4_RCAN_fp16_op17.onnx"
  "upscale_models/4x-AnimeSharp.pth"
  "upscale_models/2x-AnimeSharpV4_Fast_RCAN_PU.safetensors"
  "upscale_models/2x-AnimeSharpV3.pth"
  "upscale_models/4x_foolhardy_Remacri.pth"
  "upscale_models/4x-UltraSharpV2.pth"
  "upscale_models/4x-UltraSharpV2_Lite.pth"
)

HF_LORA_FILES=(
  "Balecxi_Style_Illustrious-10.safetensors"
  "DisneyStudios_style-12IL.safetensors"
  "IFL_v1.0_IL.safetensors"
  "Shexyo.safetensors"
  "lightingSlider.safetensors"
  "pantsushi.safetensors"
  "princess_rc_il.safetensors"
  "shexyo_style_trigger.safetensors"
)

SHARED_MODEL_ENTRIES=(
  "https://huggingface.co/NeigeSnowflake/neigeworkflow/resolve/main/lazyneg.safetensors|embeddings|lazyneg.safetensors"
  "https://huggingface.co/NeigeSnowflake/neigeworkflow/resolve/main/lazypos.safetensors|embeddings|lazypos.safetensors"
  "https://huggingface.co/datasets/WhiteAiZ/sd-webui-forge-classic/resolve/main/models/embeddings/Smooth_Negative-neg.safetensors|embeddings|Smooth_Negative-neg.safetensors"
  "https://huggingface.co/Coercer/Lora_Compilation/resolve/main/Smooth_Quality.safetensors|embeddings|Smooth_Quality.safetensors"
  "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth|sams|sam_vit_b_01ec64.pth"
  "https://huggingface.co/Anzhc/Anzhcs_YOLOs/resolve/main/Anzhc%20Face%20seg%201024%20v2%20y8n.pt|ultralytics/bbox|Anzhc_Faceseg_1024_v2_y8n.pt"
  "https://huggingface.co/adbrasi/wanlotest/resolve/main/Eyeful_v2-Individual.pt|ultralytics/bbox|Eyeful_v2-Paired.pt"
  "https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov8s.pt|ultralytics/bbox|hand_yolov8s.pt"
  "https://huggingface.co/adbrasi/wanlotest/resolve/main/ntd11_anime_nsfw_segm_v5-variant1.pt|ultralytics/bbox|ntd11_anime_nsfw_segm_v5-variant1.pt"
  "https://huggingface.co/adbrasi/testedownload/resolve/main/99coins_anime_girl_face_m_seg.pt|ultralytics/bbox|99coins_anime_girl_face_m_seg.pt"
  "https://huggingface.co/adbrasi/wanlotest/resolve/main/2x-AnimeSharpV4_RCAN_fp16_op17.onnx|upscale_models|2x-AnimeSharpV4_RCAN_fp16_op17.onnx"
  "https://huggingface.co/Kim2091/AnimeSharp/resolve/main/4x-AnimeSharp.pth|upscale_models|4x-AnimeSharp.pth"
  "https://huggingface.co/adbrasi/wanlotest/resolve/main/2x-AnimeSharpV4_Fast_RCAN_PU.safetensors|upscale_models|2x-AnimeSharpV4_Fast_RCAN_PU.safetensors"
  "https://huggingface.co/Kim2091/AnimeSharpV3/resolve/main/2x-AnimeSharpV3.pth|upscale_models|2x-AnimeSharpV3.pth"
  "https://huggingface.co/FacehugmanIII/4x_foolhardy_Remacri/resolve/main/4x_foolhardy_Remacri.pth|upscale_models|4x_foolhardy_Remacri.pth"
  "https://huggingface.co/Kim2091/UltraSharpV2/resolve/main/4x-UltraSharpV2.pth|upscale_models|4x-UltraSharpV2.pth"
  "https://huggingface.co/Kim2091/UltraSharpV2/resolve/main/4x-UltraSharpV2_Lite.pth|upscale_models|4x-UltraSharpV2_Lite.pth"
)

build_model_entries_json() {
  local entry url dir filename
  local first=1

  for entry in "$@"; do
    IFS='|' read -r url dir filename <<< "$entry"
    [ -n "$url" ] || continue

    if [ "$first" -eq 0 ]; then
      printf ',\n'
    fi

    cat <<JSON
    {
      "url": "${url}",
      "dir": "${dir}",
      "filename": "${filename}"
    }
JSON
    first=0
  done
}

write_preset_file() {
  local preset_file="$1"
  local preset_name="$2"
  local checkpoint="$3"
  local lora_a="$4"
  local lora_b="$5"
  local lora_c="${6:-}"
  local primary_loras="${lora_a}, ${lora_b}"
  local lora_file
  local -a preset_entries=(
    "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/checkpoints/${checkpoint}|checkpoints|${checkpoint}"
  )

  if [ -n "$lora_c" ]; then
    primary_loras="${primary_loras}, ${lora_c}"
  fi

  for lora_file in "${HF_LORA_FILES[@]}"; do
    preset_entries+=("https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/${lora_file}|loras|${lora_file}")
  done

  local models_json
  models_json="$(build_model_entries_json "${preset_entries[@]}" "${SHARED_MODEL_ENTRIES[@]}")"

  cat > "$preset_file" <<JSON
{
  "name": "${preset_name}",
  "description": "Preset do Menochoppa com checkpoint dedicado. LoRAs principais: ${primary_loras}. O pack completo de LoRAs do HF tambem e baixado.",
  "use_sage_attention": false,
  "comfyui_flags": [],
  "pip_commands": [
    {
      "command": ["python", "-m", "pip", "install", "-q", "pandas"],
      "description": "Instalar pandas para prompta_generita",
      "verify_import": "pandas"
    },
    {
      "command": ["python", "-m", "pip", "install", "-q", "openpyxl"],
      "description": "Instalar openpyxl para leitura de planilhas",
      "verify_import": "openpyxl"
    }
  ],
  "models": [
${models_json}
  ],
  "nodes": [
    "https://github.com/adbrasi/huggpackreator",
    "https://github.com/adbrasi/packreator_processor",
    "https://github.com/Cezarsaint/Packreator_managerMEita",
    "https://github.com/adbrasi/cezarsave34",
    "https://github.com/adbrasi/prompta_generita",
    "https://github.com/adbrasi/pageonetor",
    "https://github.com/QuietNoise/comfyui_queue_manager",
    "https://github.com/adbrasi/pakreatorio",
    "https://github.com/adbrasi/WaterMark_bumbumzin",
    "https://github.com/adbrasi/marcadaguita",
    "https://github.com/adbrasi/randomico",
    "https://github.com/kijai/ComfyUI-KJNodes",
    "https://github.com/ltdrdata/ComfyUI-Inspire-Pack",
    "https://github.com/adbrasi/groqrouter",
    "https://github.com/adbrasi/find_charakito",
    "https://github.com/adbrasi/randomsizito",
    "https://github.com/adbrasi/importex",
    "https://github.com/adbrasi/storitadifusita",
    "https://github.com/adbrasi/attentionPPM",
    "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes",
    "https://github.com/sipherxyz/comfyui-art-venture",
    "https://github.com/pamparamm/sd-perturbed-attention",
    "https://github.com/KoreTeknology/ComfyUI-Universal-Styler",
    "https://github.com/WASasquatch/was-node-suite-comfyui",
    "https://github.com/chflame163/ComfyUI_LayerStyle",
    "https://github.com/pythongosssss/ComfyUI-WD14-Tagger",
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack",
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts",
    "https://github.com/rgthree/rgthree-comfy",
    "https://github.com/adbrasi/Importador",
    "https://github.com/adbrasi/GetFirstTag",
    "https://github.com/adbrasi/comfydodi",
    "https://github.com/omar92/ComfyUI-QualityOfLifeSuit_Omar92",
    "https://github.com/Cezarsaint/blacklisto",
    "https://github.com/TinyTerra/ComfyUI_tinyterraNodes",
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack",
    "https://github.com/Cezarsaint/rand0micoUploaderLoven",
    "https://github.com/adbrasi/pixivmosaic",
    "https://github.com/adbrasi/futfilter",
    "https://github.com/shiimizu/ComfyUI_smZNodes",
    "https://github.com/CoreyCorza/ComfyUI-CRZnodes",
    "https://github.com/MoonGoblinDev/Civicomfy",
    "https://github.com/Jonseed/ComfyUI-Detail-Daemon",
    "https://github.com/fearnworks/ComfyUI_FearnworksNodes",
    "https://github.com/aria1th/ComfyUI-LogicUtils",
    "https://github.com/Extraltodeus/ComfyUI-AutomaticCFG",
    "https://github.com/adbrasi/captionizador"
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
    "IFL_v1.0_IL.safetensors" \
    "Shexyo.safetensors"

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
    if [ -f "$ARRAKIS_DIR/start.py" ] && [ -d "$PRESETS_DIR" ]; then
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
log_info "Presets baixam checkpoint dedicado + todas as LoRAs do pack HF, mais embeds/upscales/SAM/ultralytics e nodes do Arrakis2."

validate_hf_assets
start_upstream_bootstrap

if { [ -f "$ARRAKIS_DIR/start.py" ] && [ -d "$PRESETS_DIR" ]; } || wait_for_arrakis_dir; then
  write_presets
else
  log_warn "Could not find a ready Arrakis checkout at $ARRAKIS_DIR before upstream bootstrap finished."
  log_warn "If the preset does not appear, rerun the wrapper after /workspace/comfy/arrakis_start/start.py exists."
fi

wait "$BOOTSTRAP_PID"
