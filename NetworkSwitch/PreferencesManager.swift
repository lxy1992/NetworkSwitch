//
//  PreferencesManager.swift
//  NetworkSwitch
//
//  Created by 吕心言 on 26/6/2025.
//

import Foundation
import ServiceManagement

// 偏好设置变化通知
extension Notification.Name {
    static let preferencesChanged = Notification.Name("preferencesChanged")
}

class PreferencesManager {
    static let shared = PreferencesManager()
    
    private let userDefaults = UserDefaults.standard
    
    // 设置键名
    private enum Keys {
        static let launchAtLogin = "LaunchAtLogin"
        static let isFirstLaunch = "IsFirstLaunch"
        static let showNotifications = "ShowNotifications"
        static let autoSwitchDelay = "AutoSwitchDelay"
    }
    
    private init() {
        // 设置默认值
        registerDefaults()
    }
    
    // MARK: - 偏好设置属性
    var launchAtLogin: Bool {
        get {
            return userDefaults.bool(forKey: Keys.launchAtLogin)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.launchAtLogin)
            postPreferencesChanged()
        }
    }
    
    var isFirstLaunch: Bool {
        get {
            return !userDefaults.bool(forKey: Keys.isFirstLaunch)
        }
        set {
            userDefaults.set(!newValue, forKey: Keys.isFirstLaunch)
        }
    }
    
    var showNotifications: Bool {
        get {
            return userDefaults.bool(forKey: Keys.showNotifications)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.showNotifications)
            postPreferencesChanged()
        }
    }
    
    var autoSwitchDelay: Double {
        get {
            return userDefaults.double(forKey: Keys.autoSwitchDelay)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.autoSwitchDelay)
            postPreferencesChanged()
        }
    }
    
    // MARK: - 私有方法
    private func registerDefaults() {
        let defaults: [String: Any] = [
            Keys.launchAtLogin: false,
            Keys.isFirstLaunch: false,
            Keys.showNotifications: true,
            Keys.autoSwitchDelay: 1.0
        ]
        
        userDefaults.register(defaults: defaults)
    }
    
    private func postPreferencesChanged() {
        NotificationCenter.default.post(name: .preferencesChanged, object: self)
    }
    
    // MARK: - 重置设置
    func resetToDefaults() {
        userDefaults.removeObject(forKey: Keys.launchAtLogin)
        userDefaults.removeObject(forKey: Keys.showNotifications)
        userDefaults.removeObject(forKey: Keys.autoSwitchDelay)
        
        postPreferencesChanged()
    }
}

// MARK: - 开机启动助手
class LaunchAtLoginHelper {
    
    static func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                print("已添加到登录项")
            } else {
                try SMAppService.mainApp.unregister()
                print("已从登录项中移除")
            }
        } catch {
            print("设置登录项失败: \(error.localizedDescription)")
        }
    }
    
    static func isInLoginItems() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
} 