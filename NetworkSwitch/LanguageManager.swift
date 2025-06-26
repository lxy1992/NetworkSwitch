//
//  LanguageManager.swift
//  NetworkSwitch
//
//  Created by 吕心言 on 26/6/2025.
//

import Foundation

// 语言变化通知
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// 支持的语言枚举
enum AppLanguage: String, CaseIterable {
    case system = "system"
    case chinese = "zh-Hans"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .system:
            return "跟随系统 / Follow System"
        case .chinese:
            return "中文"
        case .english:
            return "English"
        }
    }
    
    var code: String {
        return self.rawValue
    }
}

class LanguageManager {
    static let shared = LanguageManager()
    
    private let userDefaults = UserDefaults.standard
    private let languageKey = "AppLanguage"
    
    private init() {}
    
    // MARK: - 当前语言设置
    var currentLanguage: AppLanguage {
        get {
            if let languageCode = userDefaults.string(forKey: languageKey),
               let language = AppLanguage(rawValue: languageCode) {
                return language
            }
            return .system
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: languageKey)
            postLanguageChanged()
        }
    }
    
    // MARK: - 获取实际使用的语言
    var effectiveLanguage: String {
        switch currentLanguage {
        case .system:
            return getSystemLanguage()
        case .chinese:
            return "zh-Hans"
        case .english:
            return "en"
        }
    }
    
    // MARK: - 本地化字符串
    func localizedString(for key: String) -> String {
        let language = effectiveLanguage
        
        // 获取对应语言的本地化字符串
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: bundle, comment: "")
        }
        
        // 如果找不到对应语言包，使用英文作为默认
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: bundle, comment: "")
        }
        
        // 最后的默认返回
        return key
    }
    
    // MARK: - 私有方法
    private func getSystemLanguage() -> String {
        let systemLanguages = Locale.preferredLanguages
        if let primaryLanguage = systemLanguages.first {
            // 如果系统语言是中文相关，返回中文
            if primaryLanguage.hasPrefix("zh") {
                return "zh-Hans"
            }
        }
        // 其他情况返回英文
        return "en"
    }
    
    private func postLanguageChanged() {
        NotificationCenter.default.post(name: .languageChanged, object: self)
    }
    
    // MARK: - 便捷方法
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
}

// MARK: - 本地化字符串便捷函数
func L(_ key: String) -> String {
    return LanguageManager.shared.localizedString(for: key)
} 