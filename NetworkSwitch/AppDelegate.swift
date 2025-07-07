//
//  AppDelegate.swift
//  NetworkSwitch
//
//  Created by 吕心言 on 26/6/2025.
//

import Cocoa
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusBarController: StatusBarController!
    private var mainWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("🚀 NetworkSwitch 启动中...")

        // 关键：启动时立即设置为无Dock图标模式
        NSApp.setActivationPolicy(.accessory)
        
        // 初始化状态栏控制器
        statusBarController = StatusBarController()
        statusBarController.delegate = self
        statusBarController.setupStatusBar()

        // 请求通知权限
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                print("🔔 通知权限: \(granted), error: \(String(describing: error))")
            }
        }
        
        // 关键：应用启动时自动显示主窗口
        showMainWindow() 
        
        print("✅ NetworkSwitch 启动完成")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // 应用完全退出时的清理工作
        statusBarController.cleanup()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Window Management
    func showMainWindow() {
        // 关键：显示窗口前，先激活应用，确保它能被带到前台
        NSApp.activate(ignoringOtherApps: true)
        
        // 切换为带Dock图标的普通应用模式
        NSApp.setActivationPolicy(.regular)

        if mainWindowController == nil {
            let mainViewController = MainViewController()
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 520),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            window.delegate = self // 关键：设置代理以捕获关闭事件
            window.contentViewController = mainViewController
            window.title = "NetworkSwitch - 网络自动切换"
            window.minSize = NSSize(width: 400, height: 480)
            window.maxSize = NSSize(width: 500, height: 600)
            window.center()
            
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowFrame = window.frame
                let newX = screenFrame.midX - windowFrame.width / 2
                let newY = screenFrame.midY - windowFrame.height / 2 + 50
                window.setFrameOrigin(NSPoint(x: newX, y: newY))
            }
            
            mainWindowController = MainWindowController(window: window)
        }

        mainWindowController?.showWindow(nil)
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    func hideMainWindow() {
        mainWindowController?.window?.orderOut(nil)
        // 关键：隐藏窗口后，切换回无Dock图标的附件模式
        NSApp.setActivationPolicy(.accessory)
    }
}

// MARK: - StatusBarControllerDelegate
extension AppDelegate: StatusBarControllerDelegate {
    func statusBarControllerDidRequestMainWindow() {
        showMainWindow()
    }
    
    func statusBarControllerDidRequestQuit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
    // 关键：当用户点击窗口的关闭按钮时，调用隐藏逻辑，而不是退出应用
    func windowWillClose(_ notification: Notification) {
        hideMainWindow()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

