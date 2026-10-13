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
WEB_PORT="${WEB_PORT:-8090}"
VALIDATE_HF_ASSETS="${VALIDATE_HF_ASSETS:-0}"

REQUIRED_MODEL_PATHS=(
  "checkpoints/Better_Days.safetensors"
  "checkpoints/Hassaku.safetensors"
  "checkpoints/magicILL_magicILLEPSV10.safetensors"
  "checkpoints/waiIllustriousSDXL_v140.safetensors"
  "checkpoints/animeScreenshotMerge_v40.safetensors"
  "loras/Balecxi_Style_Illustrious-10.safetensors"
  "loras/DisneyStudios_style-12IL.safetensors"
  "loras/IFL_v1.0_IL.safetensors"
  "loras/Shexyo.safetensors"
  "loras/lightingSlider.safetensors"
  "loras/pantsushi.safetensors"
  "loras/princess_rc_il.safetensors"
  "loras/shexyo_style_trigger.safetensors"
  "loras/anime_screencap-IL-NOOB_v3.safetensors"
  "loras/ht_series_style_v2_illustrious.safetensors"
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
  local extra_lora_a="${7:-}"
  local extra_lora_b="${8:-}"
  local primary_loras=""
  local lora_file
  local -a preset_entries=(
    "https://huggingface.co/${HF_MODELS_REPO}/resolve/main/checkpoints/${checkpoint}|checkpoints|${checkpoint}"
  )

  for lora_file in "$lora_a" "$lora_b" "$lora_c" "$extra_lora_a" "$extra_lora_b"; do
    if [ -n "$lora_file" ]; then
      if [ -n "$primary_loras" ]; then
        primary_loras="${primary_loras}, "
      fi
      primary_loras="${primary_loras}${lora_file}"
    fi
  done

  for lora_file in "${HF_LORA_FILES[@]}"; do
    preset_entries+=("https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/${lora_file}|loras|${lora_file}")
  done

  for lora_file in "$extra_lora_a" "$extra_lora_b"; do
    if [ -n "$lora_file" ]; then
      preset_entries+=("https://huggingface.co/${HF_MODELS_REPO}/resolve/main/loras/${lora_file}|loras|${lora_file}")
    fi
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

  write_preset_file "$PRESETS_DIR/meitanime.json" "MEITANIME" \
    "animeScreenshotMerge_v40.safetensors" \
    "" \
    "" \
    "" \
    "anime_screencap-IL-NOOB_v3.safetensors" \
    "ht_series_style_v2_illustrious.safetensors"
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

setup_arrakis() {
  local bootstrap_dir
  bootstrap_dir="$(mktemp -d)"
  # The upstream script ends by exec'ing a long-running selector. Download it
  # completely and replace ONLY that known launch line in a temporary copy so
  # setup can finish before we write presets. Never edit the upstream checkout.
  if ! curl -fsSL --retry 3 "$UPSTREAM_BOOTSTRAP_URL" -o "$bootstrap_dir/upstream.sh"; then
    rm -rf -- "$bootstrap_dir"
    log_error "Falha ao baixar o bootstrap original. Nenhum preset foi alterado."
    return 1
  fi
  if ! python3 - "$bootstrap_dir/upstream.sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
launch = '    exec "$ARRAKIS_PYTHON" start.py --web-only'
if source.count(launch) != 1:
    sys.exit("[ERR] Bootstrap original mudou: linha de inicializacao nao reconhecida. Abortando.")
path.write_text(source.replace(launch, '    return 0 # Selector started by Menochoppa wrapper'))
PY
  then
    rm -rf -- "$bootstrap_dir"
    return 1
  fi
  log_info "Preparando/atualizando Arrakis antes de gravar os presets..."
  local result=0
  COMFY_BASE="$COMFY_BASE" WEB_PORT="$WEB_PORT" bash "$bootstrap_dir/upstream.sh" || result=$?
  rm -rf -- "$bootstrap_dir"
  return "$result"
}

protect_custom_presets() {
  # An upstream stash --include-untracked must not remove our JSON files on
  # later runs of either installer. Use local Git excludes, not upstream edits.
  local exclude preset
  exclude="$(git -C "$ARRAKIS_DIR" rev-parse --git-path info/exclude)"
  case "$exclude" in
    /*) ;;
    *) exclude="$ARRAKIS_DIR/$exclude" ;;
  esac
  mkdir -p "$(dirname "$exclude")"
  touch "$exclude"
  for preset in meitabuu studioneverai auroredrem3d juliaverse rulegirl3d meitanime; do
    if ! grep -Fxq "/presets/$preset.json" "$exclude"; then
      printf '\n/presets/%s.json\n' "$preset" >> "$exclude"
    fi
  done
}

selector_port_status() {
  # Exit 0: free; 10: selector from this checkout; anything else: abort.
  # Inspect only. Never kill an unrelated service or an active installation.
  "$ARRAKIS_DIR/.venv/bin/python" - "$WEB_PORT" "$ARRAKIS_DIR" <<'PY'
import errno
import os
from pathlib import Path
import socket
import sys

port = int(sys.argv[1])
checkout = Path(sys.argv[2]).resolve()
try:
    with socket.socket() as probe:
        probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        probe.bind(("0.0.0.0", port))
except OSError as exc:
    if exc.errno != errno.EADDRINUSE:
        sys.exit(f"[ERR] Nao foi possivel verificar a porta {port}: {exc}")
else:
    sys.exit(0)

inodes = set()
for table in ("/proc/net/tcp", "/proc/net/tcp6"):
    try:
        for line in Path(table).read_text().splitlines()[1:]:
            fields = line.split()
            if fields[3] == "0A" and int(fields[1].rsplit(":", 1)[1], 16) == port:
                inodes.add(fields[9])
    except OSError:
        pass

owners = set()
recognized = set()
for process in Path("/proc").iterdir():
    if not process.name.isdigit():
        continue
    try:
        sockets = {os.readlink(fd) for fd in (process / "fd").iterdir()}
        if not any(f"socket:[{inode}]" in sockets for inode in inodes):
            continue
        owners.add(process.name)
        args = (process / "cmdline").read_bytes().decode(errors="replace").split("\0")
        cwd = (process / "cwd").resolve()
        if any(arg and (cwd / arg).resolve() == checkout / "start.py" for arg in args):
            recognized.add(process.name)
    except OSError:
        continue
if owners and owners == recognized:
    sys.exit(10)
sys.exit(f"[ERR] Porta {port} ocupada por outro servico ou processo nao identificavel. "
         "Nenhum processo foi encerrado. Use WEB_PORT=8091 e encaminhe essa porta no provedor.")
PY
}

install_impact_compatibility() {
  local hook_dir="$COMFY_BASE/ComfyUI/custom_nodes/menochoppa_impact_compat"
  mkdir -p "$hook_dir"
  # ComfyUI imports this hook at every start, after preset installation has
  # had the chance to clone/update Impact Pack. No polling or server changes.
  cat > "$hook_dir/__init__.py" <<'PY'
"""Compatibility for the Impact Pack legacy node-id connect call."""
import hashlib
import logging
from pathlib import Path
import re
import shutil

NODE_CLASS_MAPPINGS = {}
NODE_DISPLAY_NAME_MAPPINGS = {}
logger = logging.getLogger("menochoppa_impact_compat")

def apply_compatibility(root):
    # Remove the obsolete slot-zero workaround entirely: its type override
    # can select the INT widget type instead of the incoming STRING type.
    # Also migrate our earlier node-object fix, which retained that override.
    obsolete = re.compile(
        rb"if\s*\(link_info\.target_slot\s*==\s*0\s*&&\s*this\.inputs\.length\s*>\s*3\)\s*\{"
        rb"(?:\s|//[^\r\n]*)*origin_type\s*=\s*this\.inputs\[1\]\.type;\s*"
        rb"node\.connect\(link_info\.origin_slot,\s*node(?:\.id)?,\s*'input1'\);\s*\}"
    )
    files = list(Path(root).glob("*/js/impact-pack.js"))
    if not files:
        logger.info("Impact Pack ainda nao instalado; correcao sera verificada no proximo inicio.")
    for path in files:
        try:
            source = path.read_bytes()
            count = len(obsolete.findall(source))
            if count == 0:
                if b"node.connect(link_info.origin_slot, node.id, 'input1');" in source:
                    logger.warning("Impact Pack: implementacao diferente; arquivo preservado.")
                else:
                    logger.info("Impact Pack: bloco antigo ausente; arquivo preservado.")
                continue
            if count != 1:
                logger.warning("Impact Pack: trecho ambiguo em %s; arquivo preservado.", path)
                continue
            digest = hashlib.sha256(source).hexdigest()[:16]
            backup = path.with_name(path.name + ".menochoppa-backup-" + digest)
            if not backup.exists():
                shutil.copy2(path, backup)
            path.write_bytes(obsolete.sub(b"/* Menochoppa: obsolete slot-zero reconnect removed. */", source))
            logger.warning("Impact Pack: findInputSlot corrigido; backup em %s. Atualize o navegador com Ctrl+F5.", backup)
        except OSError:
            logger.exception("Impact Pack: nao foi possivel corrigir %s.", path)

apply_compatibility(Path(__file__).resolve().parent.parent)
PY
  python3 "$hook_dir/__init__.py"
  log_success "Compatibilidade do Impact Pack instalada; verificada agora e em cada inicio do ComfyUI."
}

main() {
  if [ "$ARRAKIS_DIR" != "$COMFY_BASE/arrakis_start" ]; then
    log_error "ARRAKIS_DIR deve ser COMFY_BASE/arrakis_start; ajuste COMFY_BASE."
    return 1
  fi
  command -v python3 >/dev/null || { log_error "python3 e necessario."; return 1; }
  log_info "Preset set: MEITABUU, StudioneverAI, Auroredrem3d, Juliaverse, RuleGirl3d, MEITANIME"
  validate_hf_assets
  setup_arrakis || return "$?"
  if [ ! -f "$ARRAKIS_DIR/start.py" ] || [ ! -x "$ARRAKIS_DIR/.venv/bin/python" ]; then
    log_error "Bootstrap terminou sem preparar o Arrakis. Presets nao foram gravados."
    return 1
  fi
  protect_custom_presets
  write_presets
  install_impact_compatibility

  local port_status=0
  selector_port_status || port_status=$?
  if [ "$port_status" -eq 10 ]; then
    log_success "Arrakis ja esta rodando na porta $WEB_PORT. Atualize a pagina para ver os seis presets."
    return 0
  elif [ "$port_status" -ne 0 ]; then
    return "$port_status"
  fi

  export WEB_PORT
  export COMFY_PYTHON="$COMFY_BASE/.venv/bin/python"
  export COMFY_CLI="$COMFY_BASE/.venv/bin/comfy"
  export VIRTUAL_ENV="$COMFY_BASE/.venv"
  export PATH="$VIRTUAL_ENV/bin:$PATH"
  cd "$ARRAKIS_DIR"
  log_success "Seis presets prontos. Iniciando seletor na porta $WEB_PORT..."
  exec "$ARRAKIS_DIR/.venv/bin/python" start.py --web-only
}

main "$@"
