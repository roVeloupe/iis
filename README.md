# Liquid Glass Signer

iOS 26-27 Liquid Glass 风格签名工具 —— 基于 GitHub Actions 在云端完成 IPA 签名，无需本机安装 Xcode。

## 功能

| 能力 | 说明 | 入口 |
| --- | --- | --- |
| Swift 构建 IPA | 用 Swift/SwiftUI 构建 iOS 26-27 Liquid Glass 签名工具，产出 IPA | `.github/workflows/build-ipa.yml` |
| IPA 重签名 | 上传 IPA 直链 + p12 + mobileprovision，用 zsign 云端重签名 | `.github/workflows/resign-ipa.yml` |
| 源码自动构建 + 签名 | macOS Runner 自动 xcodebuild Archive 并手动签名导出 IPA | `.github/workflows/build-sign.yml` |
| 证书管理 | 查看 p12 / 描述文件 / IPA 签名状态，签名前体检 | `scripts/inspect.sh` |
| 网页控制台 | Liquid Glass 风格界面，本地转换 Base64、生成 Actions 参数 | `web/index.html` |

## 目录结构

```
.
├── LiquidGlassSigner/           # Swift 源码工程（iOS 26-27 · Liquid Glass 风格）
│   ├── App/                     # 应用入口
│   ├── Models/                  # 数据模型（证书/描述文件）
│   ├── Services/                # p12 导入与描述文件解析（Security 框架）
│   └── Views/                   # SwiftUI 视图（毛玻璃/极光背景组件）
├── project.yml                  # XcodeGen 工程配置
├── .github/workflows/
│   ├── build-ipa.yml            # Swift 构建 IPA（macOS + xcodegen + xcodebuild）
│   ├── resign-ipa.yml           # IPA 重签名（ubuntu + zsign）
│   └── build-sign.yml           # 外部源码构建 + 签名（macOS + xcodebuild）
├── scripts/
│   ├── resign.sh                # 本地/云端重签名脚本
│   └── inspect.sh               # 证书与 IPA 体检工具
└── web/index.html               # GitHub Pages 控制台
```

## Swift 构建 IPA

工程为 SwiftUI 应用，部署目标 iOS 26.0，使用 `project.yml`（XcodeGen）生成工程，避免手工维护 `.xcodeproj`。

在 `Actions` 页运行 **Liquid Glass - Swift 构建 IPA**（push 到 main 时也会自动触发），macOS Runner 上会：

1. 安装 XcodeGen 并生成 Xcode 工程
2. `xcodebuild` 以 Release 配置构建（`CODE_SIGNING_ALLOWED=NO`）
3. 把 `.app` 打包为 `Payload` 结构的标准 IPA 并作为 `unsigned-ipa` 工件上传

产物未签名，需再用 **Liquid Glass 签名 - IPA 重签名** 工作流填入你的 p12 证书与描述文件签名，即可安装到 iOS 26/27 设备。

## 快速开始

1. **开启 GitHub Actions**：把本仓库推送到 GitHub 后，进入 `Actions` 页。
2. **准备材料**：
   - `.p12` 证书（含密码）
   - `.mobileprovision` 描述文件（确保包含你的设备 UDID，且支持 iOS 26/27）
   - IPA 直链（例如上传到 Release 附件后复制链接）
3. **运行重签名**：
   - 在 `Actions` 页选择 **Liquid Glass 签名 - IPA 重签名** → `Run workflow`
   - 填入 `ipa_url`、`cert_base64`、`cert_password`、`provision_base64`（可选修改 Bundle ID / 应用名称）
   - 运行完成后在 `Artifacts` 下载 `signed-ipa`
4. **安装**：将签名后的 IPA 用任意安装工具装到设备（未信任开发者证书时需先在「设置-通用-VPN与设备管理」信任）。

### 生成 Base64

- 网页端：打开 `web/index.html`（或开启 GitHub Pages），在「签名控制台」选择文件即可自动转换并生成参数 JSON。
- 命令行：

```bash
base64 -i cert.p12 | tr -d '\n'
base64 -i profile.mobileprovision | tr -d '\n'
```

## 源码自动构建 + 签名

在 `Actions` 页选择 **Liquid Glass 签名 - 自动构建并签名**，填写源码仓库、工程路径、Scheme，以及 p12 / 描述文件参数。支持 `ad-hoc / development / enterprise / app-store` 四种导出方式。

## 证书体检（证书管理）

```bash
./scripts/inspect.sh p12  cert.p12  <密码>          # 查看证书有效期/指纹
./scripts/inspect.sh prov profile.mobileprovision  # 查看描述文件设备列表
./scripts/inspect.sh ipa  app.ipa                  # 查看 IPA 签名状态
```

## 本地重签名（可选）

不依赖 Actions，在 macOS/Linux 上直接签名：

```bash
./scripts/resign.sh -i app.ipa -c cert.p12 -p 密码 -m profile.mobileprovision \
    -b com.example.newid -n 新名称 -o signed.ipa
```

脚本会自动从源码编译 zsign（依赖 `build-essential cmake libssl-dev zlib1g-dev git`）。

## 注意事项

- **证书安全**：p12 与描述文件只属于你自己，GitHub Actions 日志中不会明文打印密码；不要在公共仓库的 Issues 中粘贴 Base64。
- **iOS 26/27 支持**：签名本身与系统版本无关，能否安装取决于描述文件是否包含对应设备 UDID。
- **重签名限制**：无法绕过原始应用的越狱/防盗版校验；仅用于你自己拥有或已授权的应用。
- **企业证书**：若使用企业证书（In-House），描述文件需选择企业类型，设备无需 UDID。
