//
//  MainWindowController.swift
//  NetworkSwitch
//
//  Created by 吕心言 on 26/6/2025.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    private let languageManager = LanguageManager.shared
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        setupWindow()
        setupNotifications()
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        // 设置窗口属性
        window.title = L("main_window_title")
        window.setContentSize(NSSize(width: 480, height: 640))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isRestorable = false
        window.center()
        
        // 设置窗口关闭行为
        window.delegate = self
        
        // 设置最小和最大尺寸
        window.minSize = NSSize(width: 400, height: 560)
        window.maxSize = NSSize(width: 600, height: 800)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageChanged,
            object: nil
        )
    }
    
    @objc private func languageDidChange() {
        DispatchQueue.main.async {
            self.window?.title = L("main_window_title")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - NSWindowDelegate
extension MainWindowController: NSWindowDelegate {
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 当用户点击关闭按钮时，隐藏窗口而不是关闭应用
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.hideMainWindow()
        }
        return false // 不实际关闭窗口
    }
    
    func windowWillClose(_ notification: Notification) {
        // 窗口即将关闭时的处理
    }
} 