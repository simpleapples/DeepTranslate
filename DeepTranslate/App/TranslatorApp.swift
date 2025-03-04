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
