# LearnSite DeepSeek Docker 项目构建指南

## 项目简介

本项目用于将 LearnSite 项目中的 deepseek 模块（AI 对话、文本转语音、OCR、翻译等功能）Docker 化，方便部署使用。

## 部署顺序

> **重要提示**：请按以下顺序部署
> 
> 1. **先部署 LearnSite**（确保 LearnSite 运行成功）
> 2. **再部署 DeepSeek**（映射 LearnSite 的 deepseek 文件夹作为工作目录）

## 功能列表

| 功能 | HTML 页面 | 说明 | 依赖 |
|------|-----------|------|------|
| AI 对话 | `deepseek.html` | 流式输出智能对话 | DeepSeek API |
| 图片生成 | `aidraw.html` | pollinations 免费图生 | 无需 API |
| 语音合成 | `speek.html` | 文本转语音 | edge-tts |
| 文字识别 | `ocr.html` | 图片文字识别 | EasyOCR |
| 翻译 | `robot.html` | 中英文互译 | translate |

## 快速开始

### 1. 部署 DeepSeek

编辑 `docker-compose.yml`，配置你的 API Key：

```yaml
environment:
  # 【必填】DeepSeek API Key
  # 申请地址：https://platform.deepseek.com
  - DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
  
  # 【可选】使用硅基流动 API
  # - DEEPSEEK_API_URL=https://api.siliconflow.cn/v1/chat/completions
  # - DEEPSEEK_MODEL=Qwen/Qwen2.5-7B-Instruct
```

启动服务：

```bash
docker-compose up -d
```

### 2. 映射 LearnSite 的 deepseek 文件夹

```yaml
volumes:
  # 映射 LearnSite 的 deepseek 文件夹作为工作目录
  # 群晖示例：
  - /volume1/docker/learnsite/app/deepseek:/app
```

> **说明**：代码由 LearnSite 统一管理，LearnSite 更新时 DeepSeek 模块同步更新

### 3. 访问服务

- 入口页面：`http://localhost:2000/`（导航页）
- 各功能页面：通过导航页点击访问对应的 `.html` 文件
- 健康检查：`http://localhost:2000/health`
- 配置状态：`http://localhost:2000/config`

## 目录结构

映射的 deepseek 文件夹需包含以下文件：

```
deepseek/
├── deepseek.py      # 主程序（Flask 后端）
├── index.html       # 入口页面（导航页）
├── deepseek.html    # AI 对话页面
├── aidraw.html      # 图片生成页面
├── speek.html       # 语音合成页面
├── ocr.html         # 文字识别页面
├── robot.html       # 翻译页面
├── downloads/       # 图片生成目录
├── uploads/         # 上传文件目录
└── downmp3/         # 语音合成目录
```

## 环境变量

| 变量 | 必填 | 说明 | 默认值 |
|------|------|------|--------|
| DEEPSEEK_API_KEY | ✅ | DeepSeek API Key | - |
| DEEPSEEK_API_URL | 否 | API 地址 | https://api.deepseek.com/v1/chat/completions |
| DEEPSEEK_MODEL | 否 | 模型名称 | deepseek-chat |
| PHOTO_API_KEY | 否 | 智谱 AI API Key | 预设测试 Key |
| QWEN_API_KEY | 否 | 阿里云 Qwen API Key | 预设测试 Key |

**API 申请地址：**
- DeepSeek: https://platform.deepseek.com
- 硅基流动: https://cloud.siliconflow.cn

## 镜像信息

| 项目 | 说明 |
|------|------|
| 镜像地址 | `orzg/learnsite-deepseek:latest` |
| 镜像体积 | 约 800MB |

## 故障排查

### 查看容器日志

```bash
docker logs learnsite-deepseek
```

### 端口被占用

修改 `docker-compose.yml` 中的端口映射：

```yaml
ports:
  - "8080:2000"
```

### 查看 API 配置状态

访问 `http://localhost:2000/config`

## 注意事项

1. 镜像只包含运行时依赖，**必须**映射 LearnSite 的 deepseek 文件夹
2. EasyOCR 模型已在构建时预下载，首次启动无需等待
3. 生产环境建议使用自己的 API Key

## 相关链接

- LearnSite: https://github.com/RealKiro/learnsite
- Docker Hub: orzg/learnsite-deepseek
