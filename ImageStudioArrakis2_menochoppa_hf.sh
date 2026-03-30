#!/usr/bin/env bash
# setup_comfyui_simple.sh
# Baseado no ImageStudioArrakis2.sh original, com adicao do pack do Menochoppa no Hugging Face.

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# Configuracao
COMFY_DIR="/root/comfy/ComfyUI"
MODELS_DIR="$COMFY_DIR/models"
COMFY_HOST="0.0.0.0"
COMFY_PORT="8818"
VENV_DIR="/root/comfy/.venv"
CIVITAI_TOKEN="${CIVITAI_TOKEN:-}"
HF_TOKEN="${HF_TOKEN:-}"
HF_MODELS_REPO="${HF_MODELS_REPO:-menochoppa/comfy_models_pack}"

# Performance
export MAX_JOBS=32
export HF_HUB_ENABLE_HF_TRANSFER=1

# Lista de downloads - Formato: "URL|TIPO|NOME_OPCIONAL"
DOWNLOAD_FILES=(
    # Mega primeiro (sem nome forcado - usar nome original)
    #"mega://https://mega.nz/file/gIRTFQSQ#no6Ay3JLE9LVRi7ib9O-Jc0CW7XmG046kCgpCzDg1tY|loras|"

    # Checkpoints
    "https://civitai.com/api/download/models/1772645?type=Model&format=SafeTensor&size=pruned&fp=fp16|checkpoints|JANKUV5TrainedNoobai_v40.safetensors"
    "https://civitai.com/api/download/models/2337366?type=Model&format=SafeTensor&size=pruned&fp=fp16|checkpoints|Hassaku.safetensors"
    "https://civitai.com/api/download/models/2295031?type=Model&format=SafeTensor&size=pruned&fp=fp16|checkpoints|nova-3dcg-xl.safetensors"
    "https://civitai.com/api/download/models/2019115?type=Model&format=SafeTensor&size=full&fp=fp16|checkpoints|Better_Days.safetensors"

    # LoRAs Civitai
    "https://civitai.com/api/download/models/1268294?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/1148809?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/1715330?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/1715330?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/1499397?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/1779002?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/1114313?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/1780244?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/1613410?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/1804885?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/1809575?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/2135873?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/2332149?type=Model&format=SafeTensor|loras|"
    "https://civitai.com/api/download/models/1517104?type=Model&format=SafeTensor|loras|"

    "https://civitai.com/api/download/models/1833157?type=Model&format=SafeTensor|embeddings|"

    "https://huggingface.co/Anzhc/Anzhcs_YOLOs/resolve/main/Anzhc%20Face%20seg%201024%20v2%20y8n.pt|ultralytics/bbox|Anzhc_Faceseg_1024_v2_y8n.pt"
    "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth|sams|sam_vit_b_01ec64.pth"
    "https://huggingface.co/adbrasi/wanlotest/resolve/main/Eyeful_v2-Individual.pt|ultralytics/bbox|Eyeful_v2-Paired.pt"
    "https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov8s.pt|ultralytics/bbox|hand_yolov8s.pt"
    "https://huggingface.co/adbrasi/wanlotest/resolve/main/ntd11_anime_nsfw_segm_v5-variant1.pt|ultralytics/bbox|ntd11_anime_nsfw_segm_v5-variant1.pt"
    "https://civitai.com/api/download/models/2121199?type=Model&format=Other|embeddings|"
    "https://civitai.com/api/download/models/1195487?type=Negative&format=Other|embeddings|"
    "https://civitai.com/api/download/models/1470551?type=Model&format=SafeTensor|embeddings|"

    # Upscalers
    "https://huggingface.co/adbrasi/wanlotest/resolve/main/2x-AnimeSharpV4_RCAN_fp16_op17.onnx|upscale_models|2x-AnimeSharpV4_RCAN_fp16_op17.onnx"
    "https://huggingface.co/Kim2091/AnimeSharp/resolve/main/4x-AnimeSharp.pth|upscale_models|4x-AnimeSharp.pth"
    "https://huggingface.co/adbrasi/wanlotest/resolve/main/2x-AnimeSharpV4_Fast_RCAN_PU.safetensors|upscale_models|2x-AnimeSharpV4_Fast_RCAN_PU.safetensors"
    "https://huggingface.co/Kim2091/AnimeSharpV3/resolve/main/2x-AnimeSharpV3.pth|upscale_models|2x-AnimeSharpV3.pth"
    "https://huggingface.co/FacehugmanIII/4x_foolhardy_Remacri/resolve/main/4x_foolhardy_Remacri.pth|upscale_models|4x_foolhardy_Remacri.pth"
    "https://huggingface.co/Kim2091/UltraSharpV2/resolve/main/4x-UltraSharpV2.pth|upscale_models|4x-UltraSharpV2.pth"
    "https://huggingface.co/Kim2091/UltraSharpV2/resolve/main/4x-UltraSharpV2_Lite.pth|upscale_models|4x-UltraSharpV2_Lite.pth"

    # Ultralytics
    "https://huggingface.co/adbrasi/testedownload/resolve/main/99coins_anime_girl_face_m_seg.pt|ultralytics/bbox|99coins_anime_girl_face_m_seg.pt"
)

# Adicoes do pack do Menochoppa no Hugging Face
EXTRA_HF_DOWNLOADS=(
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

DOWNLOAD_FILES+=("${EXTRA_HF_DOWNLOADS[@]}")

# Custom nodes
CUSTOM_NODES=(
    "https://github.com/adbrasi/huggpackreator"
    "https://github.com/adbrasi/packreator_processor"
    "https://github.com/Cezarsaint/Packreator_managerMEita"
    "https://github.com/adbrasi/cezarsave34"
    "https://github.com/adbrasi/prompta_generita"
    "https://github.com/adbrasi/pageonetor"
    "https://github.com/QuietNoise/comfyui_queue_manager"
    "https://github.com/adbrasi/pakreatorio"
    "https://github.com/adbrasi/WaterMark_bumbumzin"
    "https://github.com/adbrasi/marcadaguita"
    "https://github.com/adbrasi/randomico"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/ltdrdata/ComfyUI-Inspire-Pack"
    "https://github.com/adbrasi/groqrouter"
    "https://github.com/adbrasi/find_charakito"
    "https://github.com/adbrasi/randomsizito"
    "https://github.com/adbrasi/importex"
    "https://github.com/adbrasi/storitadifusita"
    "https://github.com/adbrasi/attentionPPM"
    "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes"
    "https://github.com/sipherxyz/comfyui-art-venture"
    "https://github.com/pamparamm/sd-perturbed-attention"
    "https://github.com/KoreTeknology/ComfyUI-Universal-Styler"
    "https://github.com/WASasquatch/was-node-suite-comfyui"
    "https://github.com/chflame163/ComfyUI_LayerStyle"
    "https://github.com/pythongosssss/ComfyUI-WD14-Tagger"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/adbrasi/Importador"
    "https://github.com/adbrasi/GetFirstTag"
    "https://github.com/adbrasi/comfydodi"
    "https://github.com/omar92/ComfyUI-QualityOfLifeSuit_Omar92"
    "https://github.com/Cezarsaint/blacklisto"
    "https://github.com/TinyTerra/ComfyUI_tinyterraNodes"
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack"
    "https://github.com/Cezarsaint/rand0micoUploaderLoven"
    "https://github.com/adbrasi/pixivmosaic"
    "https://github.com/adbrasi/futfilter"
    "https://github.com/shiimizu/ComfyUI_smZNodes"
    "https://github.com/CoreyCorza/ComfyUI-CRZnodes"
    "https://github.com/MoonGoblinDev/Civicomfy"
    "https://github.com/Jonseed/ComfyUI-Detail-Daemon"
    "https://github.com/WASasquatch/was-node-suite-comfyui"
    "https://github.com/fearnworks/ComfyUI_FearnworksNodes"
    "https://github.com/aria1th/ComfyUI-LogicUtils"
    "https://github.com/Extraltodeus/ComfyUI-AutomaticCFG"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack"
    "https://github.com/adbrasi/captionizador"
)

download_hf() {
    local url="$1"
    local target_dir="$2"
    local filename="$3"
    local resolved_name="${filename:-$(basename "${url%%\?*}")}"

    if [ -f "$target_dir/$resolved_name" ]; then
        log_success "Ja existe: $resolved_name"
        return 0
    fi

    log_info "Baixando HF: $resolved_name"

    local aria_args=(
        -c
        -x 4
        -s 4
        --console-log-level=warn
        --dir="$target_dir"
        --out="$resolved_name"
    )
    local wget_args=(-q --show-progress -c -O "$target_dir/$resolved_name")
    local curl_args=(-fL -o "$target_dir/$resolved_name")

    if [ -n "$HF_TOKEN" ]; then
        aria_args+=(--header="Authorization: Bearer ${HF_TOKEN}")
        wget_args+=(--header="Authorization: Bearer ${HF_TOKEN}")
        curl_args+=(-H "Authorization: Bearer ${HF_TOKEN}")
    fi

    if command -v aria2c >/dev/null 2>&1; then
        aria2c "${aria_args[@]}" "$url" || \
        wget "${wget_args[@]}" "$url" || \
        curl "${curl_args[@]}" "$url" || {
            log_error "Download HF falhou: $resolved_name"
            return 1
        }
    else
        wget "${wget_args[@]}" "$url" || \
        curl "${curl_args[@]}" "$url" || {
            log_error "Download HF falhou: $resolved_name"
            return 1
        }
    fi
}

download_mega() {
    local url="$1"
    local target_dir="$2"

    url="${url#mega://}"

    log_info "Baixando do Mega..."

    cd "$target_dir"
    if megadl "$url" 2>/dev/null; then
        log_success "Mega download OK"
    else
        log_warn "Mega download falhou"
    fi
    cd - >/dev/null
}

download_file() {
    local url="$1"
    local target_dir="$2"
    local filename="$3"

    if [[ "$url" == *"civitai.com"* ]] && [[ "$url" != *"token="* ]]; then
        url="${url}&token=${CIVITAI_TOKEN}"
    fi

    if [ -n "$filename" ] && [ -f "$target_dir/$filename" ]; then
        log_success "Ja existe: $filename"
        return 0
    fi

    log_info "Baixando: ${filename:-arquivo}"

    if command -v aria2c >/dev/null 2>&1; then
        if [ -n "$filename" ]; then
            aria2c -c -x 4 -s 4 --console-log-level=warn --dir="$target_dir" --out="$filename" "$url" || \
            wget -q --show-progress -c -O "$target_dir/$filename" "$url" || {
                log_error "Download falhou: $filename"
                return 1
            }
        else
            aria2c -c -x 4 -s 4 --console-log-level=warn --dir="$target_dir" "$url" || \
            (cd "$target_dir" && wget -q --show-progress -c "$url") || {
                log_error "Download falhou: $url"
                return 1
            }
        fi
    elif [ -n "$filename" ]; then
        wget -q --show-progress -c -O "$target_dir/$filename" "$url" || \
        {
            log_error "Download falhou: $filename"
            return 1
        }
    else
        (cd "$target_dir" && wget -q --show-progress -c "$url") || \
        {
            log_error "Download falhou: $url"
            return 1
        }
    fi
}

process_downloads() {
    for entry in "${DOWNLOAD_FILES[@]}"; do
        IFS='|' read -r url type filename <<< "$entry"

        local target_dir="$MODELS_DIR/$type"
        mkdir -p "$target_dir"

        if [[ "$url" == mega://* ]]; then
            download_mega "$url" "$target_dir"
        elif [[ "$url" == *"huggingface.co/"* ]]; then
            download_hf "$url" "$target_dir" "$filename"
        else
            download_file "$url" "$target_dir" "$filename"
        fi
    done
}

clone_repo() {
    local url="$1"
    local dest="$2"

    if [ -d "$dest/.git" ]; then
        git -C "$dest" pull --ff-only 2>/dev/null || true
    else
        git clone --depth 1 "$url" "$dest" 2>/dev/null || true
    fi

    if [ -f "$dest/requirements.txt" ]; then
        python -m pip install -q -r "$dest/requirements.txt" 2>/dev/null || true
    fi
}

log_info "========================================="
log_info " ComfyUI Setup"
log_info "========================================="

log_info "[1/6] Instalando dependencias do sistema..."

apt-get update -qq
apt-get install -y -qq python3-venv aria2 megatools git wget curl 2>/dev/null

log_success "Dependencias do sistema instaladas"

log_info "[2/6] Preparando ambiente virtual..."

if [ ! -d "$VENV_DIR/bin" ]; then
    python3 -m venv "$VENV_DIR"
    log_success "Ambiente virtual criado em $VENV_DIR"
else
    log_info "Ambiente virtual ja existe em $VENV_DIR"
fi

. "$VENV_DIR/bin/activate"

python -m pip install -U pip wheel setuptools -q
python -m pip install -U "huggingface_hub[cli,hf_transfer]" comfy-cli -q
python -m pip install -U pandas openpyxl -q || true

log_success "Ambiente virtual pronto e comfy-cli instalado"

log_info "[3/6] Instalando ComfyUI..."

if [ -f "$COMFY_DIR/main.py" ]; then
    log_warn "ComfyUI ja existe"
else
    comfy --skip-prompt install --fast-deps --nvidia --version "0.5.1"
fi

log_success "ComfyUI instalado"

log_info "[4/6] Verificando GPU..."

GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "")

if [[ "$GPU_INFO" == *"5090"* ]] || [[ "$GPU_INFO" == *"5080"* ]]; then
    log_warn "RTX 5090/5080 detectada - instalando PyTorch novo"
    python -m pip install --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
else
    log_info "GPU: ${GPU_INFO:-Nao detectada}"
fi

log_success "PyTorch configurado"

log_info "[5/6] Baixando modelos..."

process_downloads

log_success "Downloads processados"

log_info "[6/6] Instalando custom nodes..."

CN_DIR="$COMFY_DIR/custom_nodes"
mkdir -p "$CN_DIR"

declare -A seen_nodes=()
for repo in "${CUSTOM_NODES[@]}"; do
    if [ -n "${seen_nodes[$repo]:-}" ]; then
        continue
    fi

    seen_nodes[$repo]=1
    node_name=$(basename "$repo")
    clone_repo "$repo" "$CN_DIR/$node_name"
done

log_success "Custom nodes instalados"

log_info "========================================="
log_success "Instalacao concluida!"
log_info "Iniciando ComfyUI..."
log_info "URL: http://localhost:$COMFY_PORT"
log_info "========================================="

cd "$COMFY_DIR"
exec comfy launch -- --listen "$COMFY_HOST" --preview-method latent2rgb --front-end-version Comfy-Org/ComfyUI_frontend@latest --port "$COMFY_PORT"
