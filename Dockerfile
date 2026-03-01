# 阶段1: 安装依赖
FROM python:3.11-slim-bookworm AS deps

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    libfontconfig1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN pip download --no-cache-dir --dest /tmp/wheels \
    Flask==3.0.0 \
    Flask-Cors==4.0.0 \
    gevent==23.9.1 \
    edge-tts==6.1.10 \
    opencv-python-headless>=4.9.0.80 \
    paddlepaddle==3.0.0 \
    paddleocr==2.9.1 \
    translate==3.6.1 \
    requests==2.31.0 \
    numpy==1.26.2

# 阶段2: 下载源码并配置
FROM python:3.11-slim-bookworm AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://github.com/RealKiro/learnsite/archive/refs/heads/main.tar.gz | tar xz && \
    mv learnsite-main/deepseek . && \
    rm -rf learnsite-main

WORKDIR /build/deepseek

COPY index.html .

# 替换 API Key 为环境变量（支持客户在 docker-compose 中配置）
RUN sed -i 's/^DEEPSEEK_API_KEY = "sk-.*"/DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")/' deepseek.py && \
    sed -i 's/^Qwen_API_KEY = "sk-.*"/Qwen_API_KEY = os.getenv("QWEN_API_KEY", "sk-e2f0cdd2fd04446c83e698a4bea0e40f")/' deepseek.py && \
    sed -i 's/^PHOTO_API_KEY = ".*"/PHOTO_API_KEY = os.getenv("PHOTO_API_KEY", "67121ff795f24159a4f2eaaabb89cc78.DDAMTxnDEFuiYR7f")/' deepseek.py && \
    sed -i 's/^HostIp = "127.0.0.1"/HostIp = os.getenv("HOST_IP", "0.0.0.0")/' deepseek.py

# 注意：/health、/、/config 路由已在源码 deepseek.py 中定义

COPY --from=deps /tmp/wheels /tmp/wheels
RUN pip install --no-cache-dir --no-index --find-links /tmp/wheels Flask==3.0.0 Flask-Cors==4.0.0 gevent==23.9.1 edge-tts==6.1.10 opencv-python-headless>=4.9.0.80 paddlepaddle==3.0.0 paddleocr==2.9.1 translate==3.6.1 requests==2.31.0 numpy==1.26.2

# 阶段3: 运行阶段
FROM python:3.11-slim-bookworm AS runner

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    libfontconfig1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/deepseek /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# 预下载 paddleocr 模型，加快首次启动速度
RUN python -c "from paddleocr import PaddleOCR; PaddleOCR(use_angle_cls=True, lang='ch')"

RUN mkdir -p /app/downloads /app/uploads /app/downmp3

ENV FLASK_APP=deepseek.py
ENV PYTHONUNBUFFERED=1

EXPOSE 2000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:2000/health')" || exit 1

CMD ["python", "deepseek.py"]
