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

# 复制项目源码（从 GitHub 下载或本地复制）
# 方式1：从 GitHub 拉取（推荐，保证最新）
RUN apt-get install -y curl && \
    curl -sL https://github.com/RealKiro/learnsite/archive/refs/heads/main.tar.gz | tar xz --strip-components=2 -C /app learnsite-main/deepseek && \
    apt-get remove -y curl && apt-get autoremove -y

# 方式2：如果使用本地构建，注释上面，取消下面
# COPY ./deepseek /app

# 复制自定义入口页面（如果需要覆盖）
COPY index.html /app/

# 修改源码以支持环境变量（避免硬编码 API Key）
RUN sed -i 's/^DEEPSEEK_API_KEY = "sk-.*"/DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")/' /app/deepseek.py && \
    sed -i 's/^Qwen_API_KEY = "sk-.*"/Qwen_API_KEY = os.getenv("QWEN_API_KEY", "sk-e2f0cdd2fd04446c83e698a4bea0e40f")/' /app/deepseek.py && \
    sed -i 's/^PHOTO_API_KEY = ".*"/PHOTO_API_KEY = os.getenv("PHOTO_API_KEY", "67121ff795f24159a4f2eaaabb89cc78.DDAMTxnDEFuiYR7f")/' /app/deepseek.py && \
    sed -i 's/^HostIp = "127.0.0.1"/HostIp = os.getenv("HOST_IP", "0.0.0.0")/' /app/deepseek.py

# 安装 Python 依赖（使用国内镜像加速，可选）
RUN pip install --no-cache-dir -i https://mirrors.aliyun.com/pypi/simple/ \
    Flask==3.0.0 \
    Flask-CORS==4.0.0 \
    gevent==23.9.1 \
    edge-tts==6.1.10 \
    opencv-python-headless>=4.9.0.80 \
    paddlepaddle==3.0.0 \
    paddleocr==2.9.1 \
    translate==3.6.1 \
    requests==2.31.0 \
    numpy==1.26.2

# 预下载 OCR 模型（避免首次启动下载慢）
RUN python -c "from paddleocr import PaddleOCR; PaddleOCR(use_angle_cls=True, lang='ch')"

# 创建必要的目录
RUN mkdir -p /app/downloads /app/uploads /app/downmp3

# 暴露端口
EXPOSE 2000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:2000/health')" || exit 1

# 启动命令（直接运行脚本）
CMD ["python", "/app/deepseek.py"]