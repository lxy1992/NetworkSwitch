//
//  NetworkManager.swift
//  NetworkSwitch
//
//  Created by 吕心言 on 26/6/2025.
//

import Foundation
import Network
import SystemConfiguration
import UserNotifications

// 网络状态变化通知
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

class NetworkManager {
    static let shared = NetworkManager()
    
    // 网络状态
    private(set) var isAutoSwitchEnabled = false
    private(set) var ethernetConnected = false
    private(set) var wifiEnabled = true
    
    // 网络监控
    private let monitor = NWPathMonitor()
    private let ethernetMonitor = NWPathMonitor(requiredInterfaceType: .wiredEthernet)
    private let wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // 定时器用于轮询网络状态
    private var statusTimer: Timer?
    
    // 延迟切换定时器，避免频繁切换
    private var switchTimer: Timer?
    
    private init() {
        loadSettings()
        if isAutoSwitchEnabled {
            startMonitoring()
        }
    }
    
    // MARK: - 公共方法
    func toggleAutoSwitch() {
        isAutoSwitchEnabled.toggle()
        saveSettings()
        
        if isAutoSwitchEnabled {
            startMonitoring()
        } else {
            stopMonitoring()
        }
        
        postNetworkStatusChanged()
    }
    
    func startMonitoring() {
        guard isAutoSwitchEnabled else { return }
        
        print("开始网络监控...")
        
        // 监控总体网络状态
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handleNetworkPathUpdate(path)
        }
        monitor.start(queue: queue)
        
        // 监控以太网
        ethernetMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.ethernetConnected = path.status == .satisfied
                self?.handleNetworkChange()
            }
        }
        ethernetMonitor.start(queue: queue)
        
        // 监控WiFi
        wifiMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let newWifiStatus = path.status == .satisfied
                if self?.wifiEnabled != newWifiStatus {
                    self?.wifiEnabled = newWifiStatus
                    self?.handleNetworkChange()
                }
            }
        }
        wifiMonitor.start(queue: queue)
        
        // 启动状态轮询定时器
        startStatusTimer()
        
        // 立即检查一次状态
        checkNetworkStatus()
    }
    
    func stopMonitoring() {
        print("停止网络监控...")
        
        monitor.cancel()
        ethernetMonitor.cancel()
        wifiMonitor.cancel()
        
        statusTimer?.invalidate()
        statusTimer = nil
        
        switchTimer?.invalidate()
        switchTimer = nil
    }
    
    // MARK: - 私有方法
    private func handleNetworkPathUpdate(_ path: NWPath) {
        DispatchQueue.main.async {
            let hasEthernet = path.availableInterfaces.contains { $0.type == .wiredEthernet }
            let hasWifi = path.availableInterfaces.contains { $0.type == .wifi }
            
            let ethernetChanged = self.ethernetConnected != hasEthernet
            let wifiChanged = self.wifiEnabled != hasWifi
            
            self.ethernetConnected = hasEthernet
            self.wifiEnabled = hasWifi
            
            if ethernetChanged || wifiChanged {
                self.handleNetworkChange()
            }
        }
    }
    
    private func handleNetworkChange() {
        guard isAutoSwitchEnabled else { return }
        
        print("网络状态变化 - 以太网: \(ethernetConnected), WiFi: \(wifiEnabled)")
        
        // 取消之前的切换计划
        switchTimer?.invalidate()
        
        // 延迟1秒执行切换，避免网络状态快速变化时的频繁切换
        switchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.performAutoSwitch()
        }
        
        postNetworkStatusChanged()
    }
    
    private func performAutoSwitch() {
        guard isAutoSwitchEnabled else { return }
        
        // 检查当前WiFi实际状态
        let currentWifiStatus = getWiFiStatus()
        
        if ethernetConnected && currentWifiStatus {
            // 有线连接且WiFi开启时，关闭WiFi
            print("检测到以太网连接，关闭WiFi...")
            setWiFiEnabled(false)
            
        } else if !ethernetConnected && !currentWifiStatus {
            // 无有线连接且WiFi关闭时，开启WiFi
            print("检测到以太网断开，开启WiFi...")
            setWiFiEnabled(true)
        }
    }
    
    private func startStatusTimer() {
        statusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkNetworkStatus()
        }
    }
    
    private func checkNetworkStatus() {
        DispatchQueue.global(qos: .background).async {
            let newWifiStatus = self.getWiFiStatus()
            let newEthernetStatus = self.getEthernetStatus()
            
            DispatchQueue.main.async {
                let statusChanged = (self.wifiEnabled != newWifiStatus) || (self.ethernetConnected != newEthernetStatus)
                
                self.wifiEnabled = newWifiStatus
                self.ethernetConnected = newEthernetStatus
                
                if statusChanged {
                    // 状态变化时既发送通知也重新评估自动切换
                    self.handleNetworkChange()
                }
            }
        }
    }
    
    // MARK: - Wi-Fi 相关
    private func wifiDevice() -> String {
        // 缓存结果避免频繁解析
        if let cached = _wifiDevice { return cached }
        let list = executeCommandSync("networksetup -listallhardwareports")
        var currentPort = ""
        for line in list.components(separatedBy: .newlines) {
            if line.hasPrefix("Hardware Port:") {
                currentPort = line.replacingOccurrences(of: "Hardware Port: ", with: "")
            }
            if line.hasPrefix("Device:") {
                let dev = line.replacingOccurrences(of: "Device: ", with: "")
                if currentPort.lowercased().contains("wi-fi") || currentPort.lowercased().contains("wifi") || currentPort.lowercased().contains("airport") {
                    _wifiDevice = dev
                    return dev
                }
            }
        }
        // 默认回退 en0
        _wifiDevice = "en0"
        return "en0"
    }
    private var _wifiDevice: String?

    private func setWiFiEnabled(_ enabled: Bool) {
        let device = wifiDevice()
        let command = "networksetup -setairportpower \(device) \(enabled ? "on" : "off")"
        executeCommand(command) { success in
            let appName: String = {
                if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String { return name }
                if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String { return name }
                return "NetworkSwitch"
            }()
            let operation = enabled ? "开启WiFi" : "关闭WiFi"
            if success {
                print("WiFi \(operation)成功")
                self.showNotification(title: "\(appName) - \(operation)", message: "WiFi已\(enabled ? "开启" : "关闭")")
            } else {
                print("WiFi \(operation)失败")
                self.showNotification(title: "\(appName) - \(operation)失败", message: "请检查系统权限")
            }
        }
    }
    
    private func getWiFiStatus() -> Bool {
        let device = wifiDevice()
        let output = executeCommandSync("networksetup -getairportpower \(device)")
        // 兼容多语言：On/Off、打开/关闭
        let lowered = output.lowercased()
        return lowered.contains("on") || lowered.contains("打开") || lowered.contains("已开")
    }
    
    private func getEthernetStatus() -> Bool {
        // 通过 networksetup 获取所有硬件端口，提取带有 Ethernet/LAN/Thunderbolt 字样的设备
        let portList = executeCommandSync("networksetup -listallhardwareports")
        let rows = portList.components(separatedBy: .newlines)
        var candidateDevices: [String] = []
        var currentPort = ""
        for line in rows {
            if line.hasPrefix("Hardware Port:") {
                currentPort = line.replacingOccurrences(of: "Hardware Port: ", with: "")
            }
            if line.hasPrefix("Device:") {
                let device = line.replacingOccurrences(of: "Device: ", with: "")
                if currentPort.lowercased().contains("ethernet") || currentPort.lowercased().contains("lan") || currentPort.lowercased().contains("thunderbolt") {
                    candidateDevices.append(device)
                }
            }
        }
        // 检查这些设备是否 active
        for dev in candidateDevices {
            let status = executeCommandSync("ifconfig \(dev) | grep 'status: active'")
            if !status.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
        }
        return false
    }
    
    // MARK: - 命令执行
    private func executeCommand(_ command: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            var success = false
            let process = Process()
            process.standardOutput = Pipe()
            process.standardError = Pipe()
            process.arguments = ["-c", command]
            process.launchPath = "/bin/bash"
            do {
                try process.run()
                process.waitUntilExit()
                success = process.terminationStatus == 0
            } catch {
                print("命令执行错误: \(error)")
                success = false
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    private func executeCommandSync(_ command: String) -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-c", command]
        process.launchPath = "/bin/bash"
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            print("命令执行错误: \(error)")
            return ""
        }
    }
    
    // MARK: - 通知
    private func showNotification(title: String, message: String) {
        // 遵循用户偏好设置：若关闭通知开关，则不发送系统通知
        let showNotifications = UserDefaults.standard.bool(forKey: "ShowNotifications")
        guard showNotifications else {
            return
        }
        
        // 使用现代的 UserNotifications 框架，首先确保已获授权
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                // 首次请求权限
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if granted {
                        self.scheduleNotification(title: title, message: message)
                    } else {
                        print("用户拒绝了本地通知权限")
                    }
                }
            case .denied:
                print("用户已禁用本地通知")
            case .authorized, .provisional, .ephemeral:
                self.scheduleNotification(title: title, message: message)
            @unknown default:
                break
            }
        }
    }
    
    // 使用 UNUserNotificationCenter 发送通知
    private func scheduleNotification(title: String, message: String) {
        print("🔔 scheduleNotification 被调用")
        print("🔔 创建通知内容: 标题=\(title), 消息=\(message)")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        print("🔔 通知请求已创建，ID: \(request.identifier)")
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("🔔 通知发送失败: \(error.localizedDescription)")
            } else {
                print("🔔 通知发送成功")
            }
        }
    }
    
    // 发送测试通知的公共方法（不检查用户设置，因为这是测试通知）
    func sendTestNotification(title: String, message: String) {
        print("🔔 NetworkManager.sendTestNotification 被调用")
        print("🔔 标题: \(title)")
        print("🔔 消息: \(message)")
        
        // 测试通知不需要检查用户设置，因为这是用户主动触发的
        print("🔔 这是测试通知，跳过用户设置检查")
        
        // 使用现代的 UserNotifications 框架，首先确保已获授权
        let center = UNUserNotificationCenter.current()
        print("🔔 正在获取通知设置...")
        
        center.getNotificationSettings { settings in
            print("🔔 通知授权状态: \(settings.authorizationStatus.rawValue)")
            
            switch settings.authorizationStatus {
            case .notDetermined:
                print("🔔 通知权限未确定，正在请求权限...")
                // 首次请求权限
                center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    print("🔔 权限请求结果: granted=\(granted), error=\(String(describing: error))")
                    if granted {
                        print("🔔 权限获得，发送通知")
                        self.scheduleNotification(title: title, message: message)
                    } else {
                        print("🔔 用户拒绝了本地通知权限")
                    }
                }
            case .denied:
                print("🔔 用户已禁用本地通知")
            case .authorized, .provisional, .ephemeral:
                print("🔔 通知权限已授权，发送通知")
                self.scheduleNotification(title: title, message: message)
            @unknown default:
                print("🔔 未知的通知授权状态")
                break
            }
        }
    }
    
    private func postNetworkStatusChanged() {
        NotificationCenter.default.post(name: .networkStatusChanged, object: self)
    }
    
    // MARK: - 设置持久化
    private func saveSettings() {
        UserDefaults.standard.set(isAutoSwitchEnabled, forKey: "NetworkAutoSwitchEnabled")
    }
    
    private func loadSettings() {
        isAutoSwitchEnabled = UserDefaults.standard.bool(forKey: "NetworkAutoSwitchEnabled")
    }
} 