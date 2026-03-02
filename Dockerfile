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

# 设置工作目录
WORKDIR /app

# 注意：代码由 learnsite 容器自动拉取（通过 volumes 映射共享）
# 宿主机目录结构需要：
# /volume1/docker/learnsite/app/deepseek/
#   ├── deepseek.py
#   ├── *.html
#   ├── downloads/
#   ├── uploads/
#   └── downmp3/

# 暴露端口
EXPOSE 2000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:2000/health')" || exit 1

# 启动命令
CMD ["python", "/app/deepseek.py"]
