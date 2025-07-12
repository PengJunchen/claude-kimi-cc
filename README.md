# Claude Kimi CC

本项目基于 [Kimi CC项目](https://github.com/LLM-Red-Team/kimi-cc) 

脚本由Claude Code + Kimi-K2-0711-preview修改完成，已支持mac和windows，仅在mac下充分测试

### 功能说明
- 自动配置Proxy
- 一键安装claude code
- 集成Kimi最新模型(kimi-k2-0711-preview)驱动Claude Code

## 准备工作
1. 一台mac电脑
2. 安装[NodeJS18+](https://nodejs.org/en/download)并完成系统配置
3. 获取[Kimi开放平台](https://platform.moonshot.cn/)的API Key
   - 登录后进入右上角用户中心 -> API Key 管理 -> 新建 API Key
4. 在Kimi开放平台充值50元
   - （否则使用claude可能遇到限制，需要提升账号等级）

## 快速安装

### 代理配置说明
脚本运行时会询问是否使用代理，选择 `yes` 后将提供两种代理模式：
- **全局代理**：影响所有命令，仅在脚本执行期间临时生效，脚本退出后自动清除
- **npm-only代理**：仅影响npm包管理，配置会持久保存在npm设置中

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/PengJunchen/claude-kimi-cc/refs/heads/main/claude_install.sh)"
```

### 使用方法
安装完成后，在终端输入以下命令启动：
```shell
claude
```

## 遇到问题
### 手动配置Proxy
如果自动配置失败，可尝试手动安装：
```shell
npm install -g @anthropic-ai/claude-code
```

### 参考资料
- [Claude Code 官方文档](https://www.anthropic.com/claude-code)
- [Kimi开放平台](https://platform.moonshot.cn/)

## Windows系统支持（实验性）

> **注意**：Windows版本脚本尚处于实验阶段，未经过充分测试（因缺乏Windows测试环境），可能存在兼容性问题。

### 快速安装
1. 下载[claude_install.bat](https://raw.githubusercontent.com/PengJunchen/claude-kimi-cc/refs/heads/main/claude_install.bat)文件
2. 右键点击文件，选择“以管理员身份运行”
3. 按照脚本提示完成安装（包括代理配置选项）

### 使用方法
安装完成后，在命令提示符或PowerShell中输入：
```shell
claude
```

### 注意事项
- 脚本需要管理员权限运行
- 若遇到代理配置问题，可尝试手动设置npm代理：
  ```shell
  npm config set proxy http://proxy-url:port
  npm config set https-proxy http://proxy-url:port
  ```
