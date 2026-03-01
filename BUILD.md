# LearnSite DeepSeek Docker 项目构建指南

## 项目简介

本项目用于将 LearnSite 项目中的 deepseek 模块（AI 对话、文本转语音、OCR、翻译等功能）Docker 化，方便部署使用。

## 功能列表

| 功能 | 路由 | 说明 | 依赖 |
|------|------|------|------|
| AI 对话 | `/chat` | 流式输出智能对话 | DeepSeek API |
| PPT 大纲 | `/aippt` | 主题生成 PPT 大纲 | DeepSeek API |
| 图片生成 | `/photo` | pollinations 免费图生 | 无需 API |
| 智谱图片 | `/photos` | 智谱 AI 图片生成 | 智谱 API |
| 语音合成 | `/voice` | 文本转语音 | edge-tts |
| 文字识别 | `/ocr` | 图片文字识别 | EasyOCR |
| 中英翻译 | `/translator` | 中英文互译 | translate |
| 文件上传 | `/upload` | 文件上传到服务器 | 本地存储 |

## 文件结构

```
learnsite-deepseek/
├── Dockerfile           # Docker 构建文件（三阶段构建）
├── docker-compose.yml  # Docker Compose 配置
├── .dockerignore       # 忽略文件
├── index.html          # Web 统一入口页面（现代扁平化科技风）
├── README.md           # 项目说明
├── BUILD.md            # 构建指南（本文件）
├── LICENSE             # 许可证
└── .github/
    └── workflows/
        └── ci.yml      # GitHub Actions 自动构建
```

## 快速开始

### 方式一：直接使用镜像（推荐）

1. **修改 API 配置**

编辑 `docker-compose.yml`，填入你的 API Key：

```yaml
environment:
  # 【必填】DeepSeek API Key
  # 申请地址：https://platform.deepseek.com
  - DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
  
  # 【可选】智谱 AI API Key（用于 /photos 图片生成）
  # 申请地址：https://open.bigmodel.cn
  - PHOTO_API_KEY=
  
  # 【可选】Qwen API Key（阿里云 DashScope）
  # 申请地址：https://dashscope.console.aliyun.com
  - QWEN_API_KEY=
```

2. **启动服务**

```bash
docker-compose up -d
```

3. **访问服务**

- Web 入口：`http://localhost:2000`（统一功能入口页面）
- 健康检查：`http://localhost:2000/health`
- 配置状态：`http://localhost:2000/config`

---

### 方式二：映射宿主机源码（开发调试用）

如果需要修改代码或使用本地版本，可以映射宿主机目录：

```yaml
volumes:
  # 映射宿主机源码目录
  # 群晖示例：
  - /volume1/docker/learnsite/app/deepseek:/app
  
  # 数据持久化（可选，如需保留生成的文件）
  # - ./download:/app/downloads
  # - ./uploads:/app/uploads
  # - ./downmp3:/app/downmp3
```

**宿主机目录结构要求：**
```
deepseek/
├── deepseek.py      # 主程序
├── index.html       # 入口页面
├── downloads/       # 图片生成目录
├── uploads/         # 上传文件目录
└── downmp3/         # 语音合成目录
```

## 端口说明

| 配置项 | 说明 |
|--------|------|
| 宿主机端口 | 2000（可修改 docker-compose.yml 中的 `"2000:2000"`） |
| 容器端口 | 2000 |

## 镜像信息

| 项目 | 说明 |
|------|------|
| 镜像地址 | `orzg/learnsite-deepseek:latest` |
| 基础镜像 | python:3.11-slim-bookworm |
| 镜像体积 | 约 800MB（主要由 EasyOCR 和 PyTorch 贡献） |

## 环境变量

| 变量 | 必填 | 说明 | 默认值 |
|------|------|------|--------|
| DEEPSEEK_API_KEY | ✅ 是 | DeepSeek API Key | - |
| PHOTO_API_KEY | 否 | 智谱 AI API Key | 预设测试 Key |
| QWEN_API_KEY | 否 | 阿里云 Qwen API Key | 预设测试 Key |
| HOST_IP | 否 | 监听地址 | 0.0.0.0 |

**API 申请地址：**
- DeepSeek: https://platform.deepseek.com
- 智谱 AI: https://open.bigmodel.cn
- 阿里云 Qwen: https://dashscope.console.aliyun.com

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

## 故障排查

### 容器启动失败

```bash
# 查看容器日志
docker logs learnsite-deepseek

# 手动运行查看错误（需配置环境变量）
docker run -it --rm -e DEEPSEEK_API_KEY=your_key -p 2000:2000 orzg/learnsite-deepseek:latest python deepseek.py
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
docker exec learnsite-deepseek env | grep API
```

### 查看配置状态

访问 `http://localhost:2000/config` 查看 API 配置是否生效：

```json
{
  "deepseek_configured": true,
  "qwen_configured": false,
  "photo_configured": false
}
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

**注意**：源码中的 deepseek.py 已包含以下路由：
- `/health` - 健康检查
- `/` - Web 入口页面
- `/config` - 配置状态查询

## 注意事项

1. EasyOCR 模型已在构建时预下载，客户首次启动无需等待
2. OCR 功能依赖较重，如不需要可基于此镜像自定义精简
3. 确保宿主机 2000 端口已开放
4. 生产环境建议使用自己的 API Key，避免默认 Key 额度用尽
