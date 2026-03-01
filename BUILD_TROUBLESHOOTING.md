# LearnSite DeepSeek Docker 构建问题汇总

## 时间线

### 2026-03-01

#### 1. 项目初始化
- 创建 `learnsite-deepseek` 项目
- 添加 `Dockerfile`、`docker-compose.yml`、`BUILD.md`、`index.html` 等文件
- 添加现代扁平化科技风 Web 入口页面

#### 2. 添加路由
- `/health` - 健康检查
- `/` - Web 入口页面
- `/config` - API 配置状态查询

#### 3. OCR 库替换
- **问题**：PaddleOCR 镜像体积大 (~1-2GB)
- **解决**：替换为 EasyOCR，减小体积 (~800MB)
- **遇到问题**：
  - easyocr 无法从国内镜像安装
  - torch/torchvision 版本不兼容
  - numpy 版本冲突
- **修复**：分开安装，先装 torch，再装 easyocr，最后装其他依赖

#### 4. 容器启动失败
- **问题**：容器不断重启，没有日志
- **原因**：
  1. CMD 使用相对路径 `deepseek.py`，但容器工作目录不对
  2. WORKDIR 未设置
- **修复**：添加 `WORKDIR /app` 和绝对路径 `CMD ["python", "/app/deepseek.py"]`

#### 5. API 调用失败
- **问题**：所有功能返回 "Failed to process the request" 或 "'content'"
- **原因**：前端 index.html 发送的数据格式与后端期望不一致
- **修复**：修改 deepseek.py，兼容多种数据格式：
  - `{content: "..."}` 
  - `{messages: {content: "..."}}`
  - `{messages: [{content: "..."}]}`

#### 6. /config 路由报错
- **问题**：访问 /config 返回 500 错误
- **原因**：变量名错误 `QWEN_API_KEY` 应为 `Qwen_API_KEY`
- **修复**：修正变量名

#### 7. 环境变量传递问题
- **问题**：功能测试提示 "Missing content" 或 API 余额错误
- **排查**：添加调试日志输出环境变量值

---

## 环境变量说明

| 变量名 | 必填 | 说明 | 默认值 |
|--------|------|------|--------|
| DEEPSEEK_API_KEY | ✅ | DeepSeek API Key | - |
| PHOTO_API_KEY | ❌ | 智谱 AI API Key | 测试 Key |
| QWEN_API_KEY | ❌ | 阿里云 Qwen API Key | 测试 Key |
| HOST_IP | ❌ | 监听地址 | 0.0.0.0 |

## 常见错误排查

### 1. 容器启动失败
```bash
# 查看日志
docker logs learnsite-deepseek
```

### 2. API 调用失败
- 检查 `/config` 端点返回的配置状态
- 查看容器日志中的环境变量值

### 3. 前端提交格式
后端已兼容以下格式：
```javascript
// 格式1：直接 content
{ content: "内容" }

// 格式2：messages 对象
{ messages: { content: "内容" } }

// 格式3：messages 数组
{ messages: [{ role: "user", content: "内容" }] }
```

## 相关文件

- `Dockerfile` - Docker 构建文件
- `docker-compose.yml` - 部署配置
- `index.html` - Web 入口页面
- `BUILD.md` - 构建指南
- `deepseek.py` - 主程序（从 learnsite 仓库拉取）

## 仓库地址

- learnsite: https://github.com/RealKiro/learnsite
- learnsite-source: https://github.com/RealKiro/learnsite-source
- learnsite-deepseek: https://github.com/RealKiro/learnsite-deepseek
- Docker Hub: orzg/learnsite-deepseek
