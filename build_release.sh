#!/bin/bash

# NetworkSwitch 应用程序打包脚本
# 自动构建 Release 版本并创建分发包

set -e  # 发生错误时停止脚本

echo "🚀 开始构建 NetworkSwitch Release 版本..."

# 清理之前的构建
echo "🧹 清理之前的构建文件..."
rm -rf build/
rm -rf dist/
rm -f NetworkSwitch-v*.dmg
rm -f NetworkSwitch-v*.zip

# 构建 Release 版本
echo "🔨 构建 Release 版本..."
xcodebuild -project NetworkSwitch.xcodeproj \
           -scheme NetworkSwitch \
           -configuration Release \
           -derivedDataPath ./build \
           clean build

# 检查构建是否成功
if [ ! -d "build/Build/Products/Release/NetworkSwitch.app" ]; then
    echo "❌ 构建失败！未找到应用程序文件"
    exit 1
fi

echo "✅ 构建成功！"

# 创建分发目录
echo "📦 准备分发文件..."
mkdir -p dist
cp -R build/Build/Products/Release/NetworkSwitch.app dist/

# 获取版本号（如果你在 Info.plist 中设置了版本）
VERSION=$(defaults read "$(pwd)/build/Build/Products/Release/NetworkSwitch.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")

# 创建文档
cat > dist/安装说明.txt << 'EOF'
NetworkSwitch - 网络自动切换工具
=====================================

📋 安装说明：
1. 将 NetworkSwitch.app 拖拽到 /Applications 文件夹
2. 首次运行时，可能需要在系统设置中允许该应用程序运行
3. 如果出现"无法验证开发者"的提示，请按以下步骤操作：
   - 右键点击应用程序，选择"打开"
   - 在弹出的对话框中点击"打开"

🔧 使用说明：
- 启动后会显示偏好设置窗口
- 勾选"启用自动切换"以开始自动网络切换
- 点击"隐藏到状态栏"将应用放入状态栏
- 在状态栏中可以快速切换设置和查看状态

⚙️ 功能介绍：
✅ 自动检测以太网连接状态
✅ 以太网连接时自动关闭WiFi
✅ 以太网断开时自动开启WiFi
✅ 系统通知提醒
✅ 开机自动启动
✅ 支持中英文界面

📧 技术支持：
如有问题请联系开发者

EOF

cat > dist/README.md << 'EOF'
# NetworkSwitch - Automatic Network Switching Tool

## 📋 Installation
1. Drag NetworkSwitch.app to your /Applications folder
2. On first launch, you may need to allow the app in System Settings
3. If you see "Cannot verify developer" message:
   - Right-click the app and select "Open"
   - Click "Open" in the dialog box

## 🔧 Usage
- Launch to see the preferences window
- Check "Enable Auto Switch" to start automatic network switching
- Click "Hide to Status Bar" to minimize to the menu bar
- Access settings and status from the status bar icon

## ⚙️ Features
✅ Automatic Ethernet connection detection  
✅ Auto-disable WiFi when Ethernet is connected  
✅ Auto-enable WiFi when Ethernet is disconnected  
✅ System notifications  
✅ Launch at login option  
✅ Bilingual interface (Chinese/English)  

## 🔒 Privacy & Security
This app requires network access to monitor connection status and control WiFi. All operations are performed locally on your Mac.

## 📧 Support
For technical support, please contact the developer.

EOF

# 创建 DMG 文件
echo "💿 创建 DMG 磁盘映像..."
hdiutil create -volname "NetworkSwitch" \
               -srcfolder dist \
               -ov \
               -format UDZO \
               "NetworkSwitch-v${VERSION}.dmg"

# 创建 ZIP 文件
echo "🗜️  创建 ZIP 压缩包..."
cd dist
zip -r "../NetworkSwitch-v${VERSION}.zip" *
cd ..

# 显示结果
echo ""
echo "🎉 打包完成！"
echo "📁 分发文件："
ls -lh NetworkSwitch-v${VERSION}.*

echo ""
echo "📋 分发建议："
echo "   💿 DMG 文件：适合 macOS 用户，双击即可安装"
echo "   🗜️  ZIP 文件：通用格式，体积更小"
echo ""
echo "🔒 安全提示："
echo "   - 如果需要广泛分发，建议申请 Apple 开发者账号进行代码签名"
echo "   - 当前版本可能会在用户系统中显示安全警告"
echo "   - 用户需要在系统设置中允许运行来自未识别开发者的应用" 