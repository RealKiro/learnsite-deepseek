# 阶段1: 构建阶段
FROM python:3.11-slim-bookworm AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://github.com/RealKiro/learnsite/archive/refs/heads/main.tar.gz | tar xz && \
    mv learnsite-main/deepseek . && \
    rm -rf learnsite-main

WORKDIR /build/deepseek

# 替换源码中的硬编码配置为环境变量
RUN sed -i 's/^DEEPSEEK_API_KEY = ""/DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")/' deepseek.py && \
    sed -i 's/^Qwen_API_KEY = "sk-e2f0cdd2fd04446c83e698a4bea0e40f"/Qwen_API_KEY = os.getenv("QWEN_API_KEY", "sk-e2f0cdd2fd04446c83e698a4bea0e40f")/' deepseek.py && \
    sed -i 's/^PHOTO_API_KEY = "67121ff795f24159a4f2eaaabb89cc78.DDAMTxnDEFuiYR7f"/PHOTO_API_KEY = os.getenv("PHOTO_API_KEY", "67121ff795f24159a4f2eaaabb89cc78.DDAMTxnDEFuiYR7f")/' deepseek.py && \
    sed -i 's/^HostIp = "127.0.0.1"/HostIp = os.getenv("HOST_IP", "0.0.0.0")/' deepseek.py

RUN pip install --no-cache-dir --upgrade pip wheel

RUN pip install --no-cache-dir \
    Flask==3.0.0 \
    Flask-Cors==4.0.0 \
    gevent==23.9.1 \
    edge-tts==6.1.10 \
    opencv-python-headless==4.8.1.78 \
    paddlepaddle==2.6.0 \
    paddleocr==2.7.3 \
    translate==3.6.1 \
    requests==2.31.0 \
    numpy==1.26.2

# 阶段2: 运行阶段 - 使用 Alpine
FROM python:3.11-alpine AS runner

WORKDIR /app

RUN apk add --no-cache \
    libglib \
    libsm6 \
    libxrender \
    libxext \
    libgomp \
    libstdc++ \
    ttf-freefont \
    ffmpeg

COPY --from=builder /build/deepseek /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

RUN mkdir -p /app/downloads /app/uploads /app/downmp3

ENV FLASK_APP=deepseek.py
ENV PYTHONUNBUFFERED=1

EXPOSE 2000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:2000/aippt || exit 1

CMD ["python", "deepseek.py"]
