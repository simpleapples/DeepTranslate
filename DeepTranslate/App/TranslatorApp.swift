//
//  TranslatorApp.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

@main
struct TranslatorApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var translationService = TranslationService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(translationService)
                .preferredColorScheme(.light) // 默认使用浅色模式，但也支持暗色模式
                .onOpenURL { url in
                    guard let host = url.host else { return }
                    
                    // 根据URL的host切换Tab
                    switch host {
                    case "open":
                        appState.selectedTab = 0
                    case "paste":
                        appState.selectedTab = 0
                        NotificationCenter.default.post(
                            name: Notification.Name("PerformReadingClipboard"),
                            object: nil,
                            userInfo: nil
                        )
                    case "settings":
                        appState.selectedTab = 2
                    case "history":
                        appState.selectedTab = 1
                    default:
                        appState.selectedTab = 0
                    }
                    
                }
                .onAppear {
                    // 设置全局UI样式
                    let appearance = UITabBarAppearance()
                    appearance.configureWithDefaultBackground()
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                    
                    // 设置导航栏外观
                    let navAppearance = UINavigationBarAppearance()
                    navAppearance.configureWithDefaultBackground()
                    UINavigationBar.appearance().standardAppearance = navAppearance
                    UINavigationBar.appearance().compactAppearance = navAppearance
                    UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
                }
        }
    }
}
