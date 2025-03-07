//
//  ContentView.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            TranslationView()
                .tabItem {
                    Image(systemName: "globe")
                    Text("翻译")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("历史")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
                .tag(2)
        }
        .accentColor(AppColors.accent)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(TranslationService())
}
