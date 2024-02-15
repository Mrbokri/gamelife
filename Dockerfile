# Dockerfile.rocm
FROM rocm/dev-ubuntu-22.04
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8
WORKDIR /sdtemp
RUN apt-get update &&\
    apt-get install -y \
    wget \
    git \
    python3 \
    python3-pip \
    python-is-python3
RUN python -m pip install --upgrade pip wheel
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui /sdtemp

## NEW
ENV TORCH_COMMAND="pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm5.6"

RUN python -m $TORCH_COMMAND

EXPOSE 7860

RUN python launch.py --skip-torch-cuda-test --exit
RUN python -m pip install opencv-python-headless

# extensions deps / roop
RUN apt-get install python-dev-is-python3 -y
RUN python -m pip install --use-deprecated=legacy-resolver insightface==0.7.3 onnxruntime ifnude # roop extension dep

WORKDIR /stablediff-web

# docker-compose.yml

version: '3'

services:
stablediff-rocm:
    build: 
      context: .
      dockerfile: Dockerfile.rocm
    container_name: stablediff-rocm-runner
    environment:
      TZ: "Asia/Jakarta"
      ROC_ENABLE_PRE_VEGA: 1
      COMMANDLINE_ARGS: "--listen --precision full --no-half --enable-insecure-extension-access"
      ## IMPORTANT!
      HSA_OVERRIDE_GFX_VERSION: "10.3.0"
      ROCR_VISIBLE_DEVICES: 1
      #PYTORCH_HIP_ALLOC_CONF: "garbage_collection_threshold:0.6,max_split_size_mb:128"

    entrypoint: ["/bin/sh", "-c"]
    command: >
      "rocm-smi; . /stablediff.env; echo launch.py $$COMMANDLINE_ARGS;
      if [ ! -d /stablediff-web/.git ]; then
        cp -a /sdtemp/. /stablediff-web/
      fi;
      if [ ! -f /stablediff-web/models/Stable-diffusion/*.ckpt ]; then
        echo 'Please copy stable diffusion model to stablediff-models directory'
        echo 'You may need sudo to perform this action'
        exit 1
      fi;
      python launch.py"
    ports:
      - "7860:7860"
    devices:
      - "/dev/kfd:/dev/kfd"
      - "/dev/dri:/dev/dri"
    group_add:
      - video
    ipc: host
    cap_add:
      - SYS_PTRACE
    security_opt:
      - seccomp:unconfined
    volumes:
      - ./insightface:/root/.insightface
      - ./ifnude:/root/.ifnude
      - ./cache:/root/.cache
      - ./stablediff.env:/stablediff.env
      - ./stablediff-web:/stablediff-web
      - ./stablediff-models:/stablediff-web/models/Stable-diffusion
