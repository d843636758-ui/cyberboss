# 在 Zeabur 上部署 Cyberboss

本方案把 Cyberboss 作为现有 Zeabur 项目里的**独立服务**运行。它可以和 IO 共用同一项目/服务器资源，但不要把两个程序塞进同一个容器。

## 1. 创建服务与持久卷

从本仓库的 `main` 分支创建 Git 服务。Dockerfile 会被自动识别。

为服务添加持久卷并挂载到：

```text
/data
```

微信登录、Codex 登录、线程、提醒、日记和时间轴都会保存在这里。没有持久卷时，每次重新部署都可能要求重新登录。

这个服务使用微信长轮询，不需要绑定公网域名，也不要把 Codex 的 8765 端口暴露到公网。

## 2. 基础环境变量

```dotenv
CYBERBOSS_USER_NAME=念初
CYBERBOSS_USER_GENDER=female
CYBERBOSS_RUNTIME=codex
CYBERBOSS_WORKSPACE_ROOT=/data/workspace
CYBERBOSS_STATE_DIR=/data/.cyberboss
CYBERBOSS_ENABLE_LOCATION_SERVER=false
CYBERBOSS_BOOT_MODE=codex-login
CYBERBOSS_OB_MCP_URL=https://你的-ob-域名/mcp/你的专属路径
```

不要把 Codex 或微信登录产生的凭据提交到 GitHub。

### 只内嵌 OB MCP

本部署不会继承 IO 或其他环境中的 MCP 列表。除 Cyberboss 自带项目工具外，只会在设置下面变量时额外加载 OB：

```dotenv
CYBERBOSS_OB_MCP_URL=https://你的-ob-域名/mcp/你的专属路径
```

如果 OB 使用标准 Bearer Token，再设置：

```dotenv
CYBERBOSS_OB_BEARER_TOKEN=你的令牌
```

令牌只放在 Zeabur 环境变量中，不能写进仓库。OB 被设为必需服务：如果它断线，Codex runtime 会明确启动失败，不会悄悄以“没有记忆”的状态继续运行。

## 3. 登录 Codex

第一次部署使用：

```dotenv
CYBERBOSS_BOOT_MODE=codex-login
```

在部署日志中打开设备登录网址并输入显示的代码。完成后进程会退出，这是正常现象；登录信息已经写入 `/data/.codex`。

如果使用 API key，也可以直接设置 `OPENAI_API_KEY`，跳过设备登录。

## 4. 扫码连接微信

把启动模式改为：

```dotenv
CYBERBOSS_BOOT_MODE=weixin-login
```

重新部署，在日志中保存二维码或打开打印出的二维码链接，然后用微信扫码并确认。成功日志会打印：

```text
accountId: ...
userId: ...
```

记下 `userId`。

## 5. 正常运行

设置：

```dotenv
CYBERBOSS_BOOT_MODE=run
CYBERBOSS_ALLOWED_USER_IDS=上一步打印的userId
```

重新部署。日志出现以下内容说明桥已运行：

```text
Starting the shared Codex runtime and WeChat bridge.
```

在微信中发送：

```text
/bind /data/workspace
```

随后用 `/status` 检查线程、模型和工作目录。

## 6. 与 IO 共用 MCP

Cyberboss 和 IO 可以访问同一批远程 MCP 地址与凭据，但应分别配置环境变量。不要让 Cyberboss 直接读取 IO 容器的临时文件；需要共享的持久文件应放在卷或独立数据库中。

## 故障排查

- `No saved WeChat account`：持久卷没有正确挂到 `/data`，或尚未完成微信扫码。
- `CYBERBOSS_ALLOWED_USER_IDS is empty`：把扫码成功日志里的 `userId` 填入环境变量。
- `failed to start shared app-server`：检查 `/data/.cyberboss/logs/shared-app-server.log`，通常是 Codex 尚未登录。
- 重新部署后要求再次扫码：检查持久卷是否仍然挂载到 `/data`。
- 不要同时运行两个 `run` 实例，否则同一微信账号会发生重复轮询或抢消息。
