# Claude Kimi CC

本项目基于 [Kimi CC项目](https://github.com/LLM-Red-Team/kimi-cc) 
脚本由Claude Code + Kimi-👁-0711-preview修改完成，仅在mac下验证

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
