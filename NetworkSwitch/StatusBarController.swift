//
//  StatusBarController.swift
//  NetworkSwitch
//
//  Created by 吕心言 on 26/6/2025.
//

import Cocoa

protocol StatusBarControllerDelegate: AnyObject {
    func statusBarControllerDidRequestMainWindow()
    func statusBarControllerDidRequestQuit()
}

class StatusBarController: NSObject {
    weak var delegate: StatusBarControllerDelegate?
    
    private var statusBarItem: NSStatusItem!
    private var networkManager = NetworkManager.shared
    private var languageManager = LanguageManager.shared
    private var menu: NSMenu!
    
    // 菜单项
    private var toggleMenuItem: NSMenuItem!
    private var statusMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!
    private var separatorMenuItem: NSMenuItem!
    private var preferencesMenuItem: NSMenuItem!
    private var quitMenuItem: NSMenuItem!
    
    func setupStatusBar() {
        print("🔧 开始设置状态栏...")
        
        // 创建状态栏项目
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let button = statusBarItem.button else {
            print("❌ 无法创建状态栏按钮")
            return
        }
        
        print("✅ 状态栏按钮创建成功")
        
        // 设置状态栏按钮 
        updateStatusBarIcon()
        let tooltipText = L("app_subtitle")
        button.toolTip = tooltipText.isEmpty ? "NetworkSwitch" : tooltipText
        print("🔧 状态栏按钮设置完成，工具提示: \(button.toolTip ?? "无")")
        
        // 创建菜单
        setupMenu()
        statusBarItem.menu = menu
        print("✅ 状态栏菜单已设置，菜单项数量: \(menu?.items.count ?? 0)")
        
        // 验证菜单是否正确设置
        if let menu = statusBarItem.menu {
            print("🔧 验证状态栏菜单:")
            for (index, item) in menu.items.enumerated() {
                print("  - 菜单项 \(index): \(item.title) (启用: \(item.isEnabled))")
            }
        } else {
            print("❌ 状态栏菜单未正确设置!")
        }
        
        // 监听网络状态变化
        setupNotifications()
        
        print("✅ 状态栏设置完成")
    }
    
    private func setupMenu() {
        menu = NSMenu()
        
        // 添加调试输出
        print("🔧 开始创建状态栏菜单...")
        
        // 标题项
        let titleItem = NSMenuItem()
        let titleText = L("app_subtitle")
        titleItem.title = titleText.isEmpty ? "NetworkSwitch" : titleText
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        print("🔧 添加标题项: \(titleItem.title)")
        
        menu.addItem(NSMenuItem.separator())
        
        // 主开关
        let toggleText = L("enable_auto_switch")
        toggleMenuItem = NSMenuItem(title: toggleText.isEmpty ? "Enable Auto Switch" : toggleText, 
                                    action: #selector(toggleAutoSwitch), keyEquivalent: "")
        toggleMenuItem.target = self
        menu.addItem(toggleMenuItem)
        print("🔧 添加主开关项: \(toggleMenuItem.title)")
        
        // 状态显示
        statusMenuItem = NSMenuItem()
        statusMenuItem.title = "Status"
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        print("🔧 添加状态项")
        
        menu.addItem(NSMenuItem.separator())
        
        // 开机启动选项
        let launchText = L("launch_at_login")
        launchAtLoginMenuItem = NSMenuItem(title: launchText.isEmpty ? "Launch at Login" : launchText, 
                                           action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginMenuItem.target = self
        menu.addItem(launchAtLoginMenuItem)
        print("🔧 添加开机启动项: \(launchAtLoginMenuItem.title)")
        
        menu.addItem(NSMenuItem.separator())
        
        // 偏好设置（齿轮图标）
        let prefsText = L("preferences_menu")
        preferencesMenuItem = NSMenuItem(title: prefsText.isEmpty ? "Preferences..." : prefsText, 
                                         action: #selector(openPreferences), keyEquivalent: ",")
        preferencesMenuItem.target = self
        // 添加齿轮图标
        if let gearImage = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil) {
            gearImage.isTemplate = true
            preferencesMenuItem.image = gearImage
        }
        menu.addItem(preferencesMenuItem)
        print("🔧 添加偏好设置项: \(preferencesMenuItem.title)")
        
        // 退出
        let quitText = L("quit_menu")
        quitMenuItem = NSMenuItem(title: quitText.isEmpty ? "Quit" : quitText, 
                                  action: #selector(quitApplication), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        print("🔧 添加退出项: \(quitMenuItem.title)")
        
        print("🔧 状态栏菜单创建完成，共 \(menu.items.count) 个菜单项")
        
        // 初始更新菜单状态
        updateMenuItems()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged),
            name: .networkStatusChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesChanged),
            name: .preferencesChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageChanged,
            object: nil
        )
    }
    
    // MARK: - Status Bar Icon
    private func updateStatusBarIcon() {
        guard let button = statusBarItem.button else { return }
        
        let iconName: String
        if networkManager.isAutoSwitchEnabled {
            iconName = networkManager.ethernetConnected ? "cable.connector" : "antenna.radiowaves.left.and.right"
        } else {
            iconName = "pause.circle"
        }
        
        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            image.isTemplate = true
            button.image = image
            button.title = ""
        } else {
            // 后备方案：使用文本图标
            let fallbackText: String
            if networkManager.isAutoSwitchEnabled {
                fallbackText = networkManager.ethernetConnected ? "🔌" : "📡"
            } else {
                fallbackText = "⏸"
            }
            button.image = nil
            button.title = fallbackText
        }
        
        // 更新工具提示
        let tooltip = networkManager.isAutoSwitchEnabled ? 
                     L("status_bar_auto_switch_on") : 
                     L("status_bar_auto_switch_off")
        button.toolTip = tooltip
    }
    
    // MARK: - Menu Actions
    @objc private func toggleAutoSwitch() {
        networkManager.toggleAutoSwitch()
        updateMenuItems()
        updateStatusBarIcon()
    }
    
    @objc private func toggleLaunchAtLogin() {
        let newState = !PreferencesManager.shared.launchAtLogin
        PreferencesManager.shared.launchAtLogin = newState
        launchAtLoginMenuItem.state = newState ? .on : .off
        
        // 实际的开机启动设置
        LaunchAtLoginHelper.setLaunchAtLogin(enabled: newState)
    }
    
    @objc private func openPreferences() {
        delegate?.statusBarControllerDidRequestMainWindow()
    }
    
    @objc private func quitApplication() {
        delegate?.statusBarControllerDidRequestQuit()
    }
    
    // MARK: - Menu Updates
    private func updateMenuItems() {
        let isEnabled = networkManager.isAutoSwitchEnabled
        
        // 更新主开关 - 添加默认值保护
        let enableText = L("enable_auto_switch")
        let disableText = L("disable_auto_switch")
        toggleMenuItem.title = isEnabled ? 
            (disableText.isEmpty ? "Disable Auto Switch" : disableText) : 
            (enableText.isEmpty ? "Enable Auto Switch" : enableText)
        toggleMenuItem.state = isEnabled ? .on : .off
        
        // 更新状态显示 - 添加默认值保护
        var statusText = ""
        if isEnabled {
            let ethConnectedText = L("ethernet_connected")
            let ethDisconnectedText = L("ethernet_disconnected")
            let wifiOnText = L("wifi_on")
            let wifiOffText = L("wifi_off")
            
            let ethernetStatus = networkManager.ethernetConnected ? 
                (ethConnectedText.isEmpty ? "🔌 Ethernet: Connected" : ethConnectedText) : 
                (ethDisconnectedText.isEmpty ? "🔌 Ethernet: Disconnected" : ethDisconnectedText)
            let wifiStatus = networkManager.wifiEnabled ? 
                (wifiOnText.isEmpty ? "📶 WiFi: On" : wifiOnText) : 
                (wifiOffText.isEmpty ? "📶 WiFi: Off" : wifiOffText)
            statusText = "\(ethernetStatus)\n\(wifiStatus)"
        } else {
            let disabledText = L("auto_switch_disabled")
            statusText = disabledText.isEmpty ? "🔴 Auto Switch Disabled" : disabledText
        }
        statusMenuItem.title = statusText
        print("🔧 状态菜单项更新: \(statusText)")
        
        // 更新开机启动菜单项状态
        launchAtLoginMenuItem.state = PreferencesManager.shared.launchAtLogin ? .on : .off
    }
    
    // MARK: - Notifications
    @objc private func networkStatusChanged() {
        DispatchQueue.main.async {
            self.updateStatusBarIcon()
            self.updateMenuItems()
        }
    }
    
    @objc private func preferencesChanged() {
        DispatchQueue.main.async {
            // 更新开机启动菜单项状态
            self.launchAtLoginMenuItem.state = PreferencesManager.shared.launchAtLogin ? .on : .off
        }
    }
    
    @objc private func languageDidChange() {
        DispatchQueue.main.async {
            self.updateLocalizedText()
        }
    }
    
    private func updateLocalizedText() {
        // 重新创建菜单以更新所有本地化文本
        setupMenu()
        statusBarItem.menu = menu
        updateStatusBarIcon()
    }
    
    // MARK: - Cleanup
    func cleanup() {
        NotificationCenter.default.removeObserver(self)
        networkManager.stopMonitoring()
    }
    
    deinit {
        cleanup()
    }
} 