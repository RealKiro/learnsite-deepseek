# LearnSite DeepSeek Docker 项目构建指南

## 项目简介

本项目用于将 LearnSite 项目中的 deepseek 模块（AI 对话、文本转语音、OCR、翻译等功能）Docker 化，方便在内网部署使用。

## 功能列表

| 功能 | 说明 | 依赖 |
|------|------|------|
| /chat | AI 对话（流式输出） | DeepSeek API |
| /aippt | PPT 大纲生成 | DeepSeek API |
| /photo | 图片生成（pollinations） | 无需 API |
| /photos | 图片生成（智谱 AI） | 智谱 API |
| /voice | 文本转语音 | edge-tts |
| /ocr | 图片文字识别 | paddleocr |
| /translator | 中英翻译 | translate |
| /upload | 文件上传 | - |

## 文件结构

```
learnsite-deepseek/
├── Dockerfile           # Docker 构建文件
├── docker-compose.yml  # Docker Compose 配置
├── .dockerignore       # 忽略文件
└── .github/
    └── workflows/
        └── ci.yml      # GitHub Actions CI/CD
```

## 快速开始

### 1. 修改 API 配置

编辑 `docker-compose.yml`，填入你的 API Key：

```yaml
environment:
  # 必填：DeepSeek API Key
  - DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
  # 可选：Qwen API Key
  - QWEN_API_KEY=
  # 可选：智谱 AI 图片生成 API Key
  - PHOTO_API_KEY=
```

### 2. 启动服务

```bash
docker-compose up -d
```

### 3. 访问服务

- 服务地址：`http://localhost:2000`
- 健康检查：`http://localhost:2000/aippt`

## 端口说明

- **宿主机端口**：2000（可修改 docker-compose.yml 中的 `"2000:2000"`）
- **容器端口**：2000

## 镜像信息

- **镜像地址**：`orzg/learnsite-deepseek:latest`
- **基础镜像**：python:3.11-slim-bookworm
- **镜像体积**：约 1-2GB（主要由 paddleocr 和 opencv 贡献）

## GitHub Actions 自动构建

推送到 main 分支时自动：
1. 构建 Docker 镜像
2. 运行容器测试
3. 推送到 Docker Hub

### 配置 Secrets

在 GitHub 仓库设置中添加：

| Secret | 说明 |
|--------|------|
| DOCKER_USERNAME | Docker Hub 用户名 |
| DOCKER_PASSWORD | Docker Hub 密码或 Token |

## 环境变量

| 变量 | 必填 | 说明 | 默认值 |
|------|------|------|--------|
| DEEPSEEK_API_KEY | 是 | DeepSeek API Key | - |
| QWEN_API_KEY | 否 | 阿里云 Qwen API Key | 预设值 |
| PHOTO_API_KEY | 否 | 智谱 AI API Key | 预设值 |
| HOST_IP | 否 | 监听地址 | 0.0.0.0 |

## 故障排查

### 容器启动失败

```bash
# 查看容器日志
docker logs deepseek-ai

# 手动运行查看错误
docker run -it orzg/learnsite-deepseek:latest python deepseek.py
```

### 端口被占用

修改 `docker-compose.yml`：

```yaml
ports:
  - "8080:2000"  # 宿主机 8080 映射到容器 2000
```

### API 调用失败

检查环境变量是否正确配置：

```bash
docker exec deepseek-ai env | grep API
```

## 构建优化说明

采用三阶段构建减小镜像体积：

1. **deps 阶段**：下载 pip 包到 wheels 目录
2. **builder 阶段**：安装依赖并配置源码
3. **runner 阶段**：复制必要文件到最终镜像

## 源码获取

Dockerfile 会自动从 GitHub 下载源码：

```bash
curl -sL https://github.com/RealKiro/learnsite/archive/refs/heads/main.tar.gz
```

## 注意事项

1. paddleocr 模型已在构建时预下载，客户首次启动无需等待
2. OCR 功能依赖较重，如不需要可移除以减小体积
3. 确保宿主机 2000 端口已开放
