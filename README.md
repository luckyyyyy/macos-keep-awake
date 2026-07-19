# 保持唤醒

[![CI](https://github.com/luckyyyyy/macos-keep-awake/actions/workflows/ci.yml/badge.svg)](https://github.com/luckyyyyy/macos-keep-awake/actions/workflows/ci.yml)

一个简单的原生 macOS 菜单栏应用。运行期间阻止因用户空闲导致的屏幕熄灭和系统睡眠，不修改系统设置、配置文件或安全策略。

## 下载

从 [Releases](https://github.com/luckyyyyy/macos-keep-awake/releases/latest) 下载 `KeepAwake-macOS-universal.zip`。应用同时支持 Apple Silicon 和 Intel Mac，最低支持 macOS 12。

解压后打开 `KeepAwake.app`（Finder 中显示为“保持唤醒”）。应用启动后立即生效，可以从菜单栏太阳图标暂停、恢复或退出。

> Release 使用临时签名，不含 Apple Developer ID 公证。首次运行时 macOS 可能要求在 Finder 中右键应用并选择“打开”。

## 工作方式

应用通过 macOS IOKit 的公开电源管理 API 创建两项进程级断言：

- `PreventUserIdleDisplaySleep`
- `PreventUserIdleSystemSleep`

断言只在应用运行期间存在。退出应用后，macOS 会自动恢复原有的电源管理行为。应用不会尝试规避组织管理、安全软件或管理员主动触发的强制锁屏策略。

## 本地构建

需要 Xcode Command Line Tools：

```bash
./scripts/package.sh
```

构建结果位于 `dist/KeepAwake-macOS-universal.zip`。

## 自动化

- 推送到 `main` 或创建 Pull Request 时，CI 会构建并验证通用架构应用。
- 推送 `v*` 标签时，Release 工作流会构建 ZIP 并创建 GitHub Release。

## License

[MIT](LICENSE)
