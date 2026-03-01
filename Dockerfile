# 使用官方 Python 3.11 轻量镜像
FROM python:3.11-slim-bookworm

# 安装系统依赖（OCR、语音等需要）
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

# 设置工作目录
WORKDIR /app

# 安装 git 并从 GitHub 拉取 deepseek 模块
RUN apt-get update && apt-get install -y --no-install-recommends git && \
    mkdir -p /app && \
    git clone --depth 1 --branch main https://github.com/RealKiro/learnsite.git /tmp/learnsite && \
    cp -r /tmp/learnsite/deepseek/* /app/ && \
    rm -rf /tmp/learnsite && \
    apt-get remove -y git && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# 修改源码以支持环境变量（避免硬编码 API Key）
RUN sed -i 's/DEEPSEEK_API_URL = "https:\/\/api.deepseek.com\/v1\/chat\/completions"/DEEPSEEK_API_URL = os.getenv("DEEPSEEK_API_URL", "https:\/\/api.deepseek.com\/v1\/chat\/completions")/' /app/deepseek.py && \
    sed -i 's/DEEPSEEK_MODEL = "deepseek-chat"/DEEPSEEK_MODEL = os.getenv("DEEPSEEK_MODEL", "deepseek-chat")/' /app/deepseek.py

# 安装 Python 依赖（使用兼容版本）
RUN pip install --no-cache-dir torch==2.5.1 torchvision==0.20.1 --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir easyocr && \
    pip install --no-cache-dir -i https://mirrors.aliyun.com/pypi/simple/ \
    Flask==3.0.0 \
    Flask-CORS==4.0.0 \
    gevent==23.9.1 \
    edge-tts==6.1.10 \
    opencv-python-headless==4.10.0.84 \
    translate==3.6.1 \
    requests==2.31.0 \
    numpy==1.26.4

# 预下载 EasyOCR 模型（避免首次启动下载慢）
RUN python -c "import easyocr; easyocr.Reader(['ch_sim', 'en'], gpu=False, verbose=False)"

# 创建必要的目录
RUN mkdir -p /app/downloads /app/uploads /app/downmp3

# 暴露端口
EXPOSE 2000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:2000/health')" || exit 1

# 启动命令（直接运行脚本）
CMD ["python", "/app/deepseek.py"]