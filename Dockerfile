FROM pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HOME=/data/cache/huggingface \
    TORCH_HOME=/data/cache/torch \
    OLLAMA_MODELS=/data/ollama \
    TACHIDUBB_DATA_DIR=/data/tachidubb

RUN apt-get update && apt-get install -y --no-install-recommends \
      ffmpeg nginx apache2-utils supervisor curl ca-certificates \
      libsndfile1 zstd && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://ollama.com/install.sh | sh

WORKDIR /opt/tachidubb
COPY requirements.txt ./requirements.txt
RUN python -m pip install --upgrade pip && \
    python -m pip install -r requirements.txt && \
    python -c "import nltk; nltk.download('punkt'); nltk.download('punkt_tab')"

COPY . .
COPY docker/nginx.conf /etc/nginx/sites-available/default
COPY docker/supervisord.conf /etc/supervisor/conf.d/tachidubb.conf
COPY docker/docker-entrypoint.sh /usr/local/bin/tachidubb-entrypoint
RUN chmod +x /usr/local/bin/tachidubb-entrypoint && \
    mkdir -p /data/cache /data/ollama /data/tachidubb/uploads /data/tachidubb/outputs

EXPOSE 8910
ENTRYPOINT ["/usr/local/bin/tachidubb-entrypoint"]
