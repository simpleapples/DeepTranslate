//
//  AppDelegate.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 应用启动逻辑
        return true
    }
    
    // 处理URL打开请求
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.scheme == "deeptranslate" else {
            return false
        }
        if let host = url.host {
            switch host {
            case "open":
                handleAppOpenRequest(page: "open")
                return true
            case "paste":
                handleAppOpenRequest(page: "paste")
                return true
            case "settings":
                handleAppOpenRequest(page: "settings")
                return true
            case "history":
                handleAppOpenRequest(page: "history")
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    // 处理跳转
    private func handleAppOpenRequest(page: String) {
        
        // 发送通知，使主应用可以接收这些数据
        NotificationCenter.default.post(
            name: Notification.Name("HandleAppOpenRequest"),
            object: nil,
            userInfo: nil
        )
    }
}
