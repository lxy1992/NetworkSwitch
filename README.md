# NetworkSwitch - Mac 网络自动切换工具
# NetworkSwitch - Automatic Network Switching Tool for Mac

一款简洁的 macOS 状态栏应用，可以在检测到有线网络（以太网）接入时自动关闭 Wi-Fi，在有线网络断开时自动恢复 Wi-Fi 连接。
A lightweight macOS menu bar application that automatically turns off Wi-Fi when an Ethernet connection is detected and turns it back on when Ethernet is disconnected.

---

## 🚀 主要功能 (Features)

- **✅ 自动切换 (Automatic Switching)**:
  - 检测到以太网连接时，自动关闭 Wi-Fi。
  - When an Ethernet connection is detected, Wi-Fi is automatically turned off.
  - 以太网连接断开时，自动重新开启 Wi-Fi。
  - When the Ethernet connection is lost, Wi-Fi is automatically re-enabled.
- **✅ 状态栏菜单 (Menu Bar Integration)**:
  - 所有核心功能都集成在状态栏菜单中，方便快速操作。
  - All core functions are integrated into the menu bar for quick access.
- **✅ 开机自启 (Launch at Login)**:
  - 可在偏好设置中设为开机自动启动。
  - Can be configured to launch automatically at login via preferences.
- **✅ 实时状态 (Real-time Status)**:
  - 状态栏图标和菜单会实时显示当前网络连接状态。
  - The menu bar icon and menu display the current network status in real time.
- **✅ 系统通知 (System Notifications)**:
  - 每当网络状态发生自动切换时，都会收到系统通知。
  - Receive a system notification whenever an automatic network switch occurs.

---

## 💻 如何安装 (Installation)

1. **下载应用 (Download the App)**
   - 前往项目的 [**Releases**](https://github.com/lvxinyan/NetworkSwitch/releases) 页面。
   - Go to the project's [**Releases**](https://github.com/lvxinyan/NetworkSwitch/releases) page.
   - 下载最新版本的 `NetworkSwitch-vX.X.X.dmg` 文件。
   - Download the latest `NetworkSwitch-vX.X.X.dmg` file.

2. **安装 (Install)**
   - 双击打开 `.dmg` 文件。
   - Double-click the downloaded `.dmg` file.
   - 将 `NetworkSwitch.app` 图标拖拽到 `Applications` (应用程序) 文件夹中。
   - Drag the `NetworkSwitch.app` icon into your `Applications` folder.

3. **首次运行 (First Launch)**
   - 首次打开应用时，如果系统提示"无法验证开发者"，请按以下步骤操作：
   - On the first launch, if you see a "Cannot verify developer" warning:
   - 前往 `系统设置` > `隐私与安全性`，在下方的安全部分点击"仍要打开"。
   - Go to `System Settings` > `Privacy & Security`, and in the security section at the bottom, click "Open Anyway".
   - 或者，右键点击应用图标，选择"打开"。
   - Alternatively, right-click the app icon and select "Open".

---

## 💡 如何使用 (Usage)

- **启动应用 (Launch the App)**:
  - 启动后，应用图标会出现在屏幕右上角的状态栏中，同时会显示主设置窗口。
  - After launching, the app icon will appear in the menu bar at the top-right of your screen, and the main settings window will be displayed.
- **启用/禁用 (Enable/Disable)**:
  - 在主窗口或状态栏菜单中，勾选/取消勾选 "启用自动切换" 即可控制应用。
  - Check/uncheck "Enable Auto Switch" in the main window or menu bar to control the app.
- **隐藏窗口 (Hide Window)**:
  - 点击主窗口的关闭按钮或状态栏菜单的"隐藏"选项，可将窗口关闭，应用会继续在状态栏运行。
  - Click the close button on the main window or the "Hide" option in the menu to dismiss the window. The app will continue running in the menu bar.

---

## ⚙️ 工作原理 (How It Works)

- **网络监控 (Network Monitoring)**:
  - 使用苹果现代化的 `Network.framework` 框架中的 `NWPathMonitor` 来实时、高效地监控网络连接状态的变化，特别是以太网接口的连接与断开。
  - It uses `NWPathMonitor` from Apple's modern `Network.framework` to efficiently monitor changes in network connection status in real time, especially for the Ethernet interface.
- **自动切换 (Automated Toggling)**:
  - 当检测到以太网可用时，应用会调用系统底层的 `networksetup` 命令行工具来关闭 Wi-Fi 服务。
  - When an Ethernet connection becomes available, the app invokes the underlying `networksetup` command-line tool to turn off the Wi-Fi service.
  - 当以太网断开时，再次调用该工具重新开启 Wi-Fi 服务。
  - When the Ethernet connection is lost, it calls the tool again to re-enable the Wi-Fi service.
- **延迟防抖 (Debouncing)**:
  - 内置了短暂的延迟机制，以避免在网络状态快速、频繁波动时（例如插拔网线的瞬间）执行不必要的重复切换。
  - A short delay is built-in to prevent unnecessary, repetitive switching during rapid network fluctuations (e.g., the moment of plugging/unplugging a cable).

---

## 👨‍💻 致开发者 (For Developers)

若您想从源码构建本项目，请确保您已安装 Xcode。然后在项目根目录运行以下命令：
If you wish to build the project from the source, ensure you have Xcode installed. Then, run the following command in the project's root directory:

```bash
./build_release.sh
```
该脚本将自动构建应用，并在项目根目录下生成可分发的 `.dmg` 和 `.zip` 文件。
This script will build the application and create distributable `.dmg` and `.zip` files in the project's root directory.

---

## 📄 许可证 (License)

本项目基于 **GNU Affero General Public License v3.0** 发布。详情请见 [LICENSE](LICENSE) 文件。
This project is licensed under the **GNU Affero General Public License v3.0**. See the [LICENSE](LICENSE) file for details. 