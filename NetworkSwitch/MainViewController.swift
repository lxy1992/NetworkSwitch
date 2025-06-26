//
//  MainViewController.swift
//  NetworkSwitch
//
//  Created by 吕心言 on 26/6/2025.
//

import Cocoa
import UserNotifications

class MainViewController: NSViewController {
    
    // MARK: - Properties
    private let networkManager = NetworkManager.shared
    private let preferencesManager = PreferencesManager.shared
    private let languageManager = LanguageManager.shared
    
    override func loadView() {
        // 创建主视图 - 增加高度以适应语言设置
        let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 560))
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        self.view = mainView
        
        setupUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        
        // 初始化语言设置
        if let languagePopup = view.viewWithTag(202) as? NSPopUpButton {
            setupLanguagePopup(languagePopup)
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        let margin: CGFloat = 20
        let sectionSpacing: CGFloat = 16
        var currentY: CGFloat = view.bounds.height - margin
        
        // 1. 应用图标
        let iconView = NSImageView(frame: NSRect(x: (view.bounds.width - 64) / 2, y: currentY - 64, width: 64, height: 64))
        if let appIcon = NSApp.applicationIconImage {
            iconView.image = appIcon
        } else if let networkIcon = NSImage(systemSymbolName: "network", accessibilityDescription: nil) {
            networkIcon.size = NSSize(width: 64, height: 64)
            iconView.image = networkIcon
        }
        iconView.imageScaling = .scaleProportionallyUpOrDown
        view.addSubview(iconView)
        currentY -= 64 + 12
        
        // 2. 应用标题
        let titleLabel = NSTextField(labelWithString: L("app_title"))
        titleLabel.frame = NSRect(x: margin, y: currentY - 24, width: view.bounds.width - 2 * margin, height: 24)
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.alignment = .center
        titleLabel.tag = 50 // 用于本地化更新
        view.addSubview(titleLabel)
        currentY -= 24 + 8
        
        // 3. 应用描述
        let descLabel = createMultilineLabel(text: L("app_description"), 
                                           frame: NSRect(x: margin, y: currentY - 80, width: view.bounds.width - 2 * margin, height: 80))
        descLabel.font = NSFont.systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.tag = 51 // 用于本地化更新
        view.addSubview(descLabel)
        currentY -= 80 + sectionSpacing
        
        // 4. 状态区域
        let statusSection = createSectionView(frame: NSRect(x: margin, y: currentY - 100, width: view.bounds.width - 2 * margin, height: 100))
        view.addSubview(statusSection)
        
        // 主开关按钮
        let sectionWidth = statusSection.bounds.width
        let switchButtonWidth: CGFloat = 200
        let switchButton = NSButton(frame: NSRect(x: (sectionWidth - switchButtonWidth) / 2,
                                                  y: 60,
                                                  width: switchButtonWidth,
                                                  height: 32))
        switchButton.title = L("enable_auto_switch")
        switchButton.bezelStyle = .rounded
        switchButton.target = self
        switchButton.action = #selector(toggleAutoSwitch)
        switchButton.tag = 60 // 用于本地化更新
        statusSection.addSubview(switchButton)
        
        // 状态标签
        let statusLabelWidth: CGFloat = 310
        let statusLabel = NSTextField(labelWithString: L("auto_switch_disabled"))
        statusLabel.frame = NSRect(x: (sectionWidth - statusLabelWidth) / 2,
                                    y: 35,
                                    width: statusLabelWidth,
                                    height: 20)
        statusLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        statusLabel.alignment = .center
        statusLabel.tag = 100 // 用于后续更新
        statusSection.addSubview(statusLabel)
        
        // 网络状态
        let ethernetLabelWidth: CGFloat = 140
        let wifiLabelWidth: CGFloat = 140
        let totalNetworkWidth = ethernetLabelWidth + 10 + wifiLabelWidth
        let startX = (sectionWidth - totalNetworkWidth) / 2
        let ethernetLabel = NSTextField(labelWithString: L("ethernet_detecting"))
        ethernetLabel.frame = NSRect(x: startX, y: 10, width: ethernetLabelWidth, height: 16)
        ethernetLabel.font = NSFont.systemFont(ofSize: 11)
        ethernetLabel.tag = 101
        statusSection.addSubview(ethernetLabel)
        
        let wifiLabel = NSTextField(labelWithString: L("wifi_detecting"))
        wifiLabel.frame = NSRect(x: startX + ethernetLabelWidth + 10, y: 10, width: wifiLabelWidth, height: 16)
        wifiLabel.font = NSFont.systemFont(ofSize: 11)
        wifiLabel.tag = 102
        statusSection.addSubview(wifiLabel)
        
        currentY -= 100 + sectionSpacing
        
        // 5. 偏好设置区域
        let prefsSection = createSectionView(frame: NSRect(x: margin, y: currentY - 120, width: view.bounds.width - 2 * margin, height: 120))
        view.addSubview(prefsSection)
        
        let prefsTitle = NSTextField(labelWithString: L("preferences"))
        prefsTitle.frame = NSRect(x: 16, y: 90, width: 100, height: 20)
        prefsTitle.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        prefsTitle.tag = 70 // 用于本地化更新
        prefsSection.addSubview(prefsTitle)
        
        let launchCheckbox = NSButton(checkboxWithTitle: L("launch_at_login"), target: self, action: #selector(toggleLaunchAtLogin))
        launchCheckbox.frame = NSRect(x: 16, y: 65, width: 150, height: 20)
        launchCheckbox.font = NSFont.systemFont(ofSize: 12)
        launchCheckbox.tag = 200
        prefsSection.addSubview(launchCheckbox)
        
        let notificationCheckbox = NSButton(checkboxWithTitle: L("show_notifications"), target: self, action: #selector(toggleShowNotifications))
        notificationCheckbox.frame = NSRect(x: 16, y: 45, width: 150, height: 20)
        notificationCheckbox.font = NSFont.systemFont(ofSize: 12)
        notificationCheckbox.tag = 201

        prefsSection.addSubview(notificationCheckbox)
        
        // 语言设置
        let languageLabel = NSTextField(labelWithString: L("language_setting"))
        languageLabel.frame = NSRect(x: 16, y: 20, width: 80, height: 20)
        languageLabel.font = NSFont.systemFont(ofSize: 12)
        languageLabel.tag = 71 // 用于本地化更新
        prefsSection.addSubview(languageLabel)
        
        let languagePopup = NSPopUpButton(frame: NSRect(x: 100, y: 18, width: 200, height: 24))
        languagePopup.font = NSFont.systemFont(ofSize: 12)
        languagePopup.tag = 202
        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)
        prefsSection.addSubview(languagePopup)
        
        currentY -= 120 + sectionSpacing
        
        // 6. 操作区域
        let actionsSection = createSectionView(frame: NSRect(x: margin, y: currentY - 60, width: view.bounds.width - 2 * margin, height: 60))
        view.addSubview(actionsSection)
        
        // 计算水平居中位置
        let actionsSectionWidth = actionsSection.bounds.width
        let hideButtonWidth: CGFloat = 150
        let quitButtonWidth: CGFloat = 120
        let buttonsGap: CGFloat = 30
        let totalButtonsWidth = hideButtonWidth + buttonsGap + quitButtonWidth
        let startButtonsX = (actionsSectionWidth - totalButtonsWidth) / 2

        let hideButton = NSButton(frame: NSRect(x: startButtonsX, y: 20, width: hideButtonWidth, height: 32))
        hideButton.title = L("hide_to_status_bar")
        hideButton.bezelStyle = .rounded
        hideButton.target = self
        hideButton.action = #selector(hideToStatusBar)
        hideButton.tag = 80 // 用于本地化更新
        actionsSection.addSubview(hideButton)
        
        let quitButton = NSButton(frame: NSRect(x: startButtonsX + hideButtonWidth + buttonsGap, y: 20, width: quitButtonWidth, height: 32))
        quitButton.title = L("quit_app")
        quitButton.bezelStyle = .rounded
        quitButton.contentTintColor = .systemRed
        quitButton.target = self
        quitButton.action = #selector(quitApp)
        quitButton.tag = 81 // 用于本地化更新
        actionsSection.addSubview(quitButton)
        
        // 设置通知监听
        setupNotifications()
        
        print("UI创建完成，视图数量: \(view.subviews.count)")
    }
    
    private func createSectionView(frame: NSRect) -> NSView {
        let section = NSView(frame: frame)
        section.wantsLayer = true
        section.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.1).cgColor
        section.layer?.cornerRadius = 8
        section.layer?.borderWidth = 0.5
        section.layer?.borderColor = NSColor.separatorColor.cgColor
        return section
    }
    
    private func createMultilineLabel(text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(frame: frame)
        label.stringValue = text
        label.isEditable = false
        label.isSelectable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
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
    
    // MARK: - UI Updates
    private func updateUI() {
        DispatchQueue.main.async {
            self.updateSwitchButton()
            self.updateNetworkStatus()
            self.updatePreferences()
        }
    }
    
    private func updateSwitchButton() {
        // 更新主开关按钮状态
        if let switchButton = view.viewWithTag(60) as? NSButton {
            let isEnabled = networkManager.isAutoSwitchEnabled
            switchButton.title = isEnabled ? L("disable_auto_switch") : L("enable_auto_switch")
        }
    }
    
    private func updateNetworkStatus() {
        // 更新状态标签
        if let statusLabel = view.viewWithTag(100) as? NSTextField {
            let isEnabled = networkManager.isAutoSwitchEnabled
            statusLabel.stringValue = isEnabled ? L("auto_switch_enabled") : L("auto_switch_disabled")
            statusLabel.textColor = isEnabled ? .systemGreen : .systemRed
        }
        
        // 更新以太网状态
        if let ethernetLabel = view.viewWithTag(101) as? NSTextField {
            let statusKey = networkManager.ethernetConnected ? "ethernet_connected" : "ethernet_disconnected"
            ethernetLabel.stringValue = L(statusKey)
        }
        
        // 更新WiFi状态
        if let wifiLabel = view.viewWithTag(102) as? NSTextField {
            let statusKey = networkManager.wifiEnabled ? "wifi_on" : "wifi_off"
            wifiLabel.stringValue = L(statusKey)
        }
    }
    
    private func updatePreferences() {
        // 更新复选框状态
        if let launchCheckbox = view.viewWithTag(200) as? NSButton {
            launchCheckbox.state = preferencesManager.launchAtLogin ? .on : .off
        }
        
        if let notificationCheckbox = view.viewWithTag(201) as? NSButton {
            notificationCheckbox.state = preferencesManager.showNotifications ? .on : .off
        }
        
        // 更新语言选择
        if let languagePopup = view.viewWithTag(202) as? NSPopUpButton {
            setupLanguagePopup(languagePopup)
        }
    }
    
    private func findButtonWithTitle(_ title: String) -> NSButton? {
        return view.subviews.compactMap { $0.subviews }.flatMap { $0 }.compactMap { $0 as? NSButton }.first { $0.title == title }
    }
    
    // MARK: - Actions
    @objc private func toggleAutoSwitch() {
        networkManager.toggleAutoSwitch()
        updateUI()
    }
    
    @objc private func toggleLaunchAtLogin() {
        let newState = !preferencesManager.launchAtLogin
        preferencesManager.launchAtLogin = newState
        LaunchAtLoginHelper.setLaunchAtLogin(enabled: newState)
        updateUI()
    }
    
    @objc private func toggleShowNotifications() {
        print("🔔 toggleShowNotifications 被调用")
        
        preferencesManager.showNotifications = !preferencesManager.showNotifications
        print("🔔 通知设置状态: \(preferencesManager.showNotifications)")
        
        // 如果用户开启了通知，检查系统权限并发送测试通知
        if preferencesManager.showNotifications {
            checkNotificationPermissionAndSendTest()
        } else {
            print("🔔 通知已关闭")
        }
        
        updateUI()
    }
    
    private func checkNotificationPermissionAndSendTest() {
        print("🔔 检查通知权限状态...")
        
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("🔔 当前通知权限状态: \(settings.authorizationStatus.rawValue)")
                
                switch settings.authorizationStatus {
                case .denied:
                    self.showNotificationPermissionAlert()
                case .notDetermined:
                    self.requestNotificationPermission()
                case .authorized, .provisional, .ephemeral:
                    self.sendTestNotification()
                @unknown default:
                    print("🔔 未知的权限状态")
                }
            }
        }
    }
    
    private func showNotificationPermissionAlert() {
        print("🔔 显示权限被拒绝的提示")
        
        let alert = NSAlert()
        alert.messageText = "通知权限被拒绝"
        alert.informativeText = "要接收通知，请按以下步骤操作：\n\n1. 打开\"系统设置\"\n2. 选择\"通知\"\n3. 找到\"NetworkSwitch\"\n4. 开启\"允许通知\"\n\n开启后，请重新勾选此选项。"
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "取消")
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 打开系统设置的通知面板
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func requestNotificationPermission() {
        print("🔔 请求通知权限")
        
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                print("🔔 权限请求结果: granted=\(granted), error=\(String(describing: error))")
                
                if granted {
                    self.sendTestNotification()
                } else {
                    print("🔔 用户拒绝了通知权限")
                }
            }
        }
    }
    
    private func sendTestNotification() {
        print("🔔 发送测试通知")
        
        let appName: String = {
            if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String { return name }
            if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String { return name }
            return "NetworkSwitch"
        }()
        
        let title = "\(appName) - \(L("show_notifications"))"
        let message = L("notification_test_message")
        
        networkManager.sendTestNotification(title: title, message: message)
    }
    

    
    @objc private func hideToStatusBar() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.hideMainWindow()
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func languageChanged() {
        if let languagePopup = view.viewWithTag(202) as? NSPopUpButton {
            let selectedIndex = languagePopup.indexOfSelectedItem
            let language = AppLanguage.allCases[selectedIndex]
            languageManager.setLanguage(language)
        }
    }
    
    // MARK: - Language Support
    private func setupLanguagePopup(_ popup: NSPopUpButton) {
        popup.removeAllItems()
        
        for language in AppLanguage.allCases {
            popup.addItem(withTitle: language.displayName)
        }
        
        // 设置当前选中的语言
        let currentLanguage = languageManager.currentLanguage
        if let index = AppLanguage.allCases.firstIndex(of: currentLanguage) {
            popup.selectItem(at: index)
        }
    }
    
    private func updateLocalizedText() {
        DispatchQueue.main.async {
            // 更新标题
            if let titleLabel = self.view.viewWithTag(50) as? NSTextField {
                titleLabel.stringValue = L("app_title")
            }
            
            // 更新描述
            if let descLabel = self.view.viewWithTag(51) as? NSTextField {
                descLabel.stringValue = L("app_description")
            }
            
            // 更新按钮
            if let switchButton = self.view.viewWithTag(60) as? NSButton {
                let isEnabled = self.networkManager.isAutoSwitchEnabled
                switchButton.title = isEnabled ? L("disable_auto_switch") : L("enable_auto_switch")
            }
            
            // 更新偏好设置标题
            if let prefsTitle = self.view.viewWithTag(70) as? NSTextField {
                prefsTitle.stringValue = L("preferences")
            }
            
            // 更新复选框
            if let launchCheckbox = self.view.viewWithTag(200) as? NSButton {
                launchCheckbox.title = L("launch_at_login")
            }
            
            if let notificationCheckbox = self.view.viewWithTag(201) as? NSButton {
                notificationCheckbox.title = L("show_notifications")
            }
            
            // 更新语言标签
            if let languageLabel = self.view.viewWithTag(71) as? NSTextField {
                languageLabel.stringValue = L("language_setting")
            }
            
            // 更新语言选择
            if let languagePopup = self.view.viewWithTag(202) as? NSPopUpButton {
                self.setupLanguagePopup(languagePopup)
            }
            
            // 更新操作按钮
            if let hideButton = self.view.viewWithTag(80) as? NSButton {
                hideButton.title = L("hide_to_status_bar")
            }
            
            if let quitButton = self.view.viewWithTag(81) as? NSButton {
                quitButton.title = L("quit_app")
            }
            
            // 更新状态显示
            self.updateNetworkStatus()
        }
    }
    
    // MARK: - Notifications
    @objc private func networkStatusChanged() {
        updateUI()
    }
    
    @objc private func preferencesChanged() {
        updateUI()
    }
    
    @objc private func languageDidChange() {
        updateLocalizedText()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 