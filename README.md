# Videoplay

一个功能强大的 iOS 视频播放器应用，支持本地视频播放、WebDAV 网络视频播放，并集成了实时美颜滤镜功能。

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
│   │   └── PlayerSettings.swift           # 播放器设置
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

- **开发语言**: Swift 5, Objective-C++
- **UI 框架**: SwiftUI
- **视频播放**: AVFoundation (AVPlayer)
- **视频处理**: GPUPixel (C++ 图像处理框架)
- **项目管理**: Tuist
- **最低支持**: iOS 16.0+

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
   git clone <repository-url>
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

1. 打开应用设置
2. 点击 "WebDAV 浏览器"
3. 输入服务器地址、用户名和密码
4. 浏览并选择视频文件播放

### 美颜设置

在播放视频时，可以实时调节以下美颜参数：
- **磨皮强度**: 0-100
- **美白强度**: 0-100
- **瘦脸强度**: 0-100
- **大眼强度**: 0-100

### 播放模式

- **流式播放**: 直接播放网络视频，支持美颜滤镜
- **本地缓存**: 先下载到本地再播放，播放更流畅

在设置中可以切换 "启用本地缓存 (WebDAV)" 选项。

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

- WebDAV 播放需要网络权限
- 美颜功能仅支持 AVPlayer 播放器
- 本地缓存会占用临时存储空间，关闭视频时自动清理
- 首次运行需要授予相册和文件访问权限

## 🐛 已知问题

- WebDAV 认证失败时会显示错误提示
- 某些视频格式可能不支持硬件解码

## 📄 许可证

本项目仅供学习和研究使用。

## 👥 贡献

欢迎提交 Issue 和 Pull Request！

## 📧 联系方式

如有问题或建议，请通过 Issue 反馈。

---

**注意**: 本项目使用 GPUPixel 框架，请确保遵守相关许可协议。
