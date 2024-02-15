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

