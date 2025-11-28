# Videoplay

一个功能强大的 iOS 视频播放器应用，支持本地视频播放、WebDAV 网络视频播放，并集成了实时美颜滤镜功能。

[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 📸 预览

> 支持本地视频和 WebDAV 网络视频播放，实时美颜滤镜处理

## ✨ 主要特性

- 🎬 **多源视频播放**
  - 本地视频文件播放
  - WebDAV 网络视频流播放
  - 支持多种视频格式

- 💄 **实时美颜滤镜**
  - 基于 GPUPixel 的高性能视频处理
  - 支持磨皮、美白、瘦脸等多种美颜效果
  - 实时调节美颜参数

- 🌐 **WebDAV 支持**
  - WebDAV 服务器浏览
  - HTTP Basic 认证
  - 本地缓存模式（下载后播放）
  - 流式播放模式（边播边缓存）

- 🎮 **播放控制**
  - 播放/暂停/进度控制
  - 手势操作（双击播放/暂停，单击显示/隐藏控制栏）
  - 长按加速播放
  - 拖拽快进/快退
  - 记忆播放进度（自动保存和恢复播放位置）

- 🔄 **横竖屏切换**
  - 自动横竖屏适配
  - 全屏播放支持

## 📁 项目结构

```
videoplay/
├── Sources/
│   ├── App/                    # 应用入口
│   │   └── VideoplayApp.swift
│   ├── Views/                  # 视图层
│   │   ├── AdvancedContentView.swift      # 主播放器视图
│   │   ├── ContentView.swift              # 主界面
│   │   ├── DebugContentView.swift         # 调试视图
│   │   ├── LogViewerView.swift            # 日志查看器
│   │   ├── SettingsView.swift             # 设置界面
│   │   ├── SimpleContentView.swift        # 简单播放器
│   │   ├── VideoPickerContentView.swift   # 视频选择器
│   │   └── WebDAVBrowserView.swift        # WebDAV 浏览器
│   ├── Models/                 # 数据模型
│   │   ├── BeautySettings.swift           # 美颜设置
│   │   ├── PlayerSettings.swift           # 播放器设置
│   │   └── PlaybackProgressManager.swift  # 播放进度管理
│   ├── Services/               # 业务服务
│   │   ├── StreamingResourceLoader.swift  # 流式资源加载器
│   │   ├── WebDAVFileProvider.swift       # WebDAV 文件提供者
│   │   └── WebDAVResourceLoader.swift     # WebDAV 资源加载器
│   ├── Utils/                  # 工具类
│   │   ├── DocumentPicker.swift           # 文档选择器
│   │   ├── Logger.swift                   # 日志工具
│   │   └── VideoPicker.swift              # 视频选择器
│   └── GPUPixel/              # GPU 处理
│       ├── BridgingHeader.h               # Objective-C 桥接头文件
│       ├── GPUPixelWrapper.h              # GPUPixel 封装头文件
│       └── GPUPixelWrapper.mm             # GPUPixel 封装实现
├── Resources/                  # 资源文件
│   └── Assets.xcassets                    # 图片资源
├── gpupixel_ios_arm64/        # GPUPixel 框架
│   ├── lib/                               # 库文件
│   ├── include/                           # 头文件
│   ├── models/                            # AI 模型
│   └── res/                               # 资源文件
├── Project.swift              # Tuist 项目配置
├── build_ipa.sh              # IPA 构建脚本
└── README.md                 # 项目说明文档
```

## 🛠 技术栈

| 技术 | 说明 |
|------|------|
| **开发语言** | Swift 5, Objective-C++ |
| **UI 框架** | SwiftUI |
| **视频播放** | AVFoundation (AVPlayer) |
| **视频处理** | GPUPixel (C++ 图像处理框架) |
| **网络协议** | WebDAV (HTTP Basic Auth) |
| **项目管理** | Tuist |
| **最低支持** | iOS 16.0+ |

## 📦 依赖项

- **GPUPixel**: 高性能 GPU 图像/视频处理框架
  - 提供实时美颜滤镜功能
  - 基于 Metal 的硬件加速

## 🚀 构建与运行

### 前置要求

- Xcode 15.0+
- Tuist 4.0+
- iOS 16.0+ 设备或模拟器

### 安装步骤

1. **克隆项目**
   ```bash
   git clone git@github.com:qi-mooo/videoplay.git
   cd videoplay
   ```

2. **安装依赖**
   ```bash
   tuist install
   ```

3. **生成 Xcode 项目**
   ```bash
   tuist generate
   ```

4. **打开项目**
   ```bash
   open Videoplay.xcworkspace
   ```

5. **运行项目**
   - 在 Xcode 中选择目标设备
   - 点击运行按钮 (⌘R)

### 构建 IPA

使用提供的脚本快速构建 IPA 文件：

```bash
./build_ipa.sh
```

构建完成后，IPA 文件位于项目根目录：`Videoplay.ipa`

## ⚙️ 配置说明

### WebDAV 服务器配置

1. 打开应用主界面
2. 点击 "WebDAV 浏览器" 按钮
3. 输入服务器配置：
   - **服务器地址**: `http://your-server:port` 或 `https://your-server:port`
   - **用户名**: WebDAV 账号
   - **密码**: WebDAV 密码
4. 点击连接，浏览文件列表
5. 选择视频文件开始播放

**示例配置**:
```
服务器: http://192.168.1.100:5005
用户名: admin
密码: ********
```

### 美颜设置

在播放视频时，可以实时调节以下美颜参数：

| 参数 | 范围 | 说明 |
|------|------|------|
| **磨皮强度** | 0-100 | 平滑皮肤，减少瑕疵 |
| **美白强度** | 0-100 | 提亮肤色 |
| **瘦脸强度** | 0-100 | 瘦脸效果 |
| **大眼强度** | 0-100 | 放大眼睛 |

### 播放模式

| 模式 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **流式播放** | 即点即播，无需等待 | 依赖网络稳定性 | 网络良好时 |
| **本地缓存** | 播放流畅，支持离线 | 需要等待下载 | 网络不稳定或需要反复观看 |

💡 **提示**: 在设置中可以切换 "启用本地缓存 (WebDAV)" 选项。

### 播放进度记忆

应用会自动记住每个视频的播放位置，下次打开时从上次停止的地方继续播放。

| 功能 | 说明 |
|------|------|
| **自动保存** | 每 10 秒自动保存一次播放进度 |
| **智能记忆** | 只记忆播放超过 5 秒且未播放完成的视频 |
| **自动清理** | 播放到接近结尾时自动清除记录 |
| **容量限制** | 最多保存 100 个视频的播放进度 |
| **开关控制** | 可在设置中关闭此功能，关闭时会清除所有已保存的进度 |

💡 **提示**: 
- 播放进度基于视频文件的唯一标识（文件名+大小或 URL）
- 即使删除后重新下载相同的视频，也能恢复播放进度
- 关闭"记忆播放进度"功能会立即清除所有已保存的进度

## 🎯 使用说明

### 播放本地视频

1. 点击主界面的 "选择视频" 按钮
2. 从相册或文件中选择视频
3. 视频自动开始播放

### 播放 WebDAV 视频

1. 点击 "WebDAV 浏览器"
2. 输入服务器信息并连接
3. 浏览文件列表
4. 点击视频文件开始播放

### 播放控制

- **单击屏幕**: 显示/隐藏控制栏
- **双击屏幕**: 播放/暂停
- **长按屏幕**: 2倍速播放
- **左右拖拽**: 快进/快退
- **进度条**: 拖动调整播放进度

## 🔧 开发说明

### 添加新功能

1. 在对应的文件夹下创建新文件
2. 无需修改 `Project.swift`（使用通配符自动包含）
3. 运行 `tuist generate` 重新生成项目

### 日志调试

应用内置了日志系统，可以在 "日志查看器" 中查看运行日志：
- 点击主界面的日志图标
- 查看详细的运行日志和错误信息

### 自定义美颜效果

修改 `Sources/GPUPixel/GPUPixelWrapper.mm` 中的美颜参数：
```objective-c
[beautyFaceFilter setBlurAlpha:blurAlpha];
[beautyFaceFilter setWhite:white];
[beautyFaceFilter setThinFaceAlpha:thinFace];
[beautyFaceFilter setBigeyeAlpha:bigeye];
```

## 📝 注意事项

- ⚠️ WebDAV 播放需要网络权限
- ⚠️ 美颜功能仅支持 AVPlayer 播放器
- ⚠️ 本地缓存会占用临时存储空间，关闭视频时自动清理
- ⚠️ 首次运行需要授予相册和文件访问权限
- ⚠️ GPUPixel 框架文件较大（~4MB），首次克隆可能需要一些时间

## 🐛 已知问题

- WebDAV 认证失败时会显示错误提示
- 某些视频格式可能不支持硬件解码
- 模拟器上美颜效果可能与真机有差异

## 📋 未来计划

- [x] ~~记忆播放进度功能~~ ✅ 已完成
- [ ] 支持更多视频格式
- [ ] 添加视频列表播放功能
- [ ] 支持 SMB 协议
- [ ] 优化美颜算法性能
- [ ] 添加更多滤镜效果
- [ ] 支持视频截图和录制

## �� 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 👥 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📧 联系方式

- **GitHub Issues**: [提交问题](https://github.com/qi-mooo/videoplay/issues)
- **Pull Requests**: [贡献代码](https://github.com/qi-mooo/videoplay/pulls)

## 🙏 致谢

- [GPUPixel](https://github.com/pixpark/gpupixel) - 高性能图像处理框架
- [Tuist](https://tuist.io) - Xcode 项目生成工具

---

**⚠️ 重要提示**: 
- 本项目使用 GPUPixel 框架，请确保遵守相关许可协议
- 仅供学习和研究使用，请勿用于商业用途
- 使用 WebDAV 功能时请确保网络安全
