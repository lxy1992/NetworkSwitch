//
//  AppDelegate.swift
//  NetworkSwitch
//
//  Created by 吕心言 on 26/6/2025.
//

import Cocoa
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    private var statusBarController: StatusBarController!
    private var mainWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("🚀 NetworkSwitch 启动中...")
        
        // 确保请求通知权限时应用处于前台，以便系统弹窗能够显示
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        NSApp.activate(ignoringOtherApps: true) // 将应用置于前台，便于弹窗
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                print("🔔 通知权限: \(granted), error: \(String(describing: error))")
                // 获得授权后（或用户已做出选择）再将应用返回 accessory 模式
                NSApp.setActivationPolicy(.accessory)
            }
        }
        
        // 首先初始化状态栏控制器（在设置activation policy之前）
        statusBarController = StatusBarController()
        statusBarController.delegate = self
        statusBarController.setupStatusBar()
        
        // 显示主窗口（偏好设置界面）
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
        if mainWindowController == nil {
            // 创建主窗口和视图控制器
            let mainViewController = MainViewController()
            
            // 调整窗口大小 - 减小尺寸，确保内容合理显示
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 520),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            window.contentViewController = mainViewController
            window.title = "NetworkSwitch - 网络自动切换"
            
            // 设置窗口最小和最大尺寸
            window.minSize = NSSize(width: 400, height: 480)
            window.maxSize = NSSize(width: 500, height: 600)
            
            // 居中显示窗口
            window.center()
            
            // 设置窗口位置稍微靠上一些，避免被底部Dock遮挡
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowFrame = window.frame
                let newX = screenFrame.midX - windowFrame.width / 2
                let newY = screenFrame.midY - windowFrame.height / 2 + 50 // 稍微向上偏移
                window.setFrameOrigin(NSPoint(x: newX, y: newY))
            }
            
            // 创建窗口控制器
            mainWindowController = MainWindowController(window: window)
            mainWindowController?.window?.delegate = mainWindowController as? NSWindowDelegate
        }
        
        mainWindowController?.showWindow(nil)
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
        
        // 激活应用，使窗口置顶显示，但保持 accessory 模式
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideMainWindow() {
        mainWindowController?.window?.orderOut(nil)
        // 重新设置为accessory，从Dock中隐藏
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

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 允许前台展示通知横幅和声音
        completionHandler([.banner, .sound])
    }
}

