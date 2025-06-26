# NetworkSwitch - Mac 网络自动切换工具

一个简洁的 macOS 状态栏应用，可以自动在以太网和 WiFi 之间切换，解决网络连接优先级问题。

## 功能特性

- ✅ **自动网络切换**: 检测到以太网连接时自动关闭 WiFi，断开时自动开启 WiFi
- ✅ **状态栏集成**: 始终在状态栏显示，方便随时控制
- ✅ **开机启动**: 可设置为开机自动启动
- ✅ **实时状态**: 实时显示网络连接状态
- ✅ **系统通知**: 网络切换时显示通知提醒
- ✅ **完全退出**: 可完全关闭应用和状态栏图标

## 界面预览

### 状态栏菜单
点击状态栏图标后显示的菜单包含：
- 主开关 (启用/禁用自动切换)
- 网络状态显示
- 开机启动勾选框
- 偏好设置按钮 (齿轮图标)
- 退出应用按钮

### 主界面
- 应用介绍和说明
- 自动切换开关
- 实时网络状态
- 偏好设置选项
- 操作按钮

## 安装和使用

### 系统要求
- macOS 10.15 或更高版本
- 管理员权限 (用于修改网络设置)

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/lvxinyan/NetworkSwitch.git
   cd NetworkSwitch
   ```

2. **使用 Xcode 打开项目**
   ```bash
   open NetworkSwitch.xcodeproj
   ```

3. **编译和运行**
   - 在 Xcode 中选择目标设备为 "My Mac"
   - 按 `⌘ + R` 运行项目
   - 或者按 `⌘ + B` 编译项目

4. **授权网络权限**
   - 首次运行时，系统会要求授权网络访问权限
   - 在 "系统偏好设置" > "安全性与隐私" > "隐私" 中授权

### 使用方法

1. **启动应用**
   - 应用启动后会在状态栏显示网络图标
   - 首次启动会显示主界面介绍功能

2. **启用自动切换**
   - 点击状态栏图标
   - 点击 "启用自动切换"
   - 或在主界面中点击开关按钮

3. **设置开机启动**
   - 在状态栏菜单或主界面中勾选 "开机自动启动"

4. **查看状态**
   - 状态栏图标会根据当前网络状态变化
   - 点击可查看详细的网络连接信息

## 工作原理

1. **网络监控**: 使用 `NWPathMonitor` 监控网络接口状态变化
2. **自动切换**: 当检测到以太网连接时，通过 `networksetup` 命令关闭 WiFi
3. **状态恢复**: 当以太网断开时，自动重新开启 WiFi
4. **延迟防抖**: 1秒延迟避免网络状态快速变化时的频繁切换

## 技术架构

- **AppDelegate**: 应用生命周期管理和窗口控制
- **StatusBarController**: 状态栏图标和菜单管理
- **NetworkManager**: 网络监控和切换逻辑
- **PreferencesManager**: 偏好设置存储和管理
- **MainViewController**: 主界面逻辑 (程序化 UI)
- **LaunchAtLoginHelper**: 开机启动功能

## 故障排除

### 权限问题
如果应用无法切换网络，请检查：
1. 在 "系统偏好设置" > "安全性与隐私" > "隐私" 中授权应用
2. 确保运行应用的用户具有管理员权限

### 网络检测问题
如果网络状态检测不准确：
1. 检查网络接口名称是否正确
2. 在控制台查看应用日志

### 开机启动问题
如果开机启动不生效：
1. 检查 "系统偏好设置" > "用户与群组" > "登录项"
2. 手动添加应用到登录项

## 开发说明

### 主要依赖
- `Network.framework`: 网络状态监控
- `SystemConfiguration.framework`: 系统配置访问
- `AppKit`: macOS 原生界面框架

### 构建配置
- 最低部署目标: macOS 10.15
- Swift 版本: 5.0+
- Xcode 版本: 12.0+

### 代码结构
```
NetworkSwitch/
├── AppDelegate.swift           # 应用委托
├── StatusBarController.swift   # 状态栏控制
├── NetworkManager.swift        # 网络管理
├── PreferencesManager.swift    # 偏好设置
├── MainViewController.swift    # 主界面
├── MainWindowController.swift  # 窗口控制
└── NetworkSwitch.entitlements  # 应用权限
```

## 许可证

本项目基于原 [mac-network-switch](https://github.com/lxy1992/mac-network-switch) 项目修改，使用 AppKit 重新实现为原生 Mac 应用。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！

## 更新日志

### v1.0.0
- 初始版本发布
- 基本的网络自动切换功能
- 状态栏集成
- 程序化界面设计
- 开机启动支持 