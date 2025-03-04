//
//  SettingsView.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showAddProvider = false
    @State private var editingProvider: LLMProvider? = nil
    @State private var appearance: String = UserDefaults.standard.string(forKey: "appearance") ?? "系统"
    @AppStorage("autoDetectLanguage") private var autoDetectLanguage = true
    
    let appearanceOptions = ["浅色", "深色", "系统"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // LLM服务提供商设置
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("LLM服务提供商")
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    showAddProvider = true
                                }) {
                                    Label("添加", systemImage: "plus")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.accent)
                                }
                            }
                            .padding(.horizontal)
                            
                            ForEach(Array(appState.providers.enumerated()), id: \.element.id) { index, provider in
                                ProviderCard(
                                    provider: provider,
                                    isActive: index == appState.selectedProviderIndex,
                                    onActivate: {
                                        appState.setProviderActive(at: index)
                                    },
                                    onEdit: {
                                        print("准备编辑提供商: \(provider.name)")
                                        editingProvider = provider
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        
                        // 应用设置
                        VStack(alignment: .leading, spacing: 12) {
                            Text("应用设置")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                // 外观设置
                                HStack {
                                    Image(systemName: "paintbrush")
                                        .frame(width: 30)
                                        .foregroundColor(AppColors.accent)
                                    
                                    Text("外观模式")
                                    
                                    Spacer()
                                    
                                    Picker("外观", selection: $appearance) {
                                        ForEach(appearanceOptions, id: \.self) {
                                            Text($0)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .onChange(of: appearance) { _ in
                                        UserDefaults.standard.set(appearance, forKey: "appearance")
                                        updateAppearance()
                                    }
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(12, corners: [.topLeft, .topRight])
                                
                                Divider()
                                    .padding(.leading, 60)
                                    .opacity(0.5)
                                
                                // 自动检测语言开关
                                Toggle(isOn: $autoDetectLanguage) {
                                    HStack {
                                        Image(systemName: "text.magnifyingglass")
                                            .frame(width: 30)
                                            .foregroundColor(AppColors.accent)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("自动检测语言")
                                            
                                            Text("输入文本后自动识别源语言")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                                .tint(AppColors.accent)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        
                        // 关于应用
                        VStack(alignment: .leading, spacing: 12) {
                            Text("关于")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                // 版本信息
                                HStack {
                                    Image(systemName: "info.circle")
                                        .frame(width: 30)
                                        .foregroundColor(AppColors.accent)
                                    
                                    Text("版本")
                                    
                                    Spacer()
                                    
                                    Text("1.0.0")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(12, corners: [.topLeft, .topRight])
                                
                                Divider()
                                    .padding(.leading, 60)
                                    .opacity(0.5)
                                
                                // 源代码
                                Link(destination: URL(string: "https://github.com")!) {
                                    HStack {
                                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                                            .frame(width: 30)
                                            .foregroundColor(AppColors.accent)
                                        
                                        Text("源代码")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.forward")
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                
                                Divider()
                                    .padding(.leading, 60)
                                    .opacity(0.5)
                                
                                // 应用信息
                                NavigationLink(
                                    destination:
                                        ScrollView {
                                            VStack(alignment: .leading, spacing: 16) {
                                                Text("AI翻译")
                                                    .font(.title.bold())
                                                
                                                Text("这是一个类似Apple自带翻译应用的高级实现，支持接入多种LLM模型作为翻译后端，包括OpenAI、DeepSeek、Anthropic等。")
                                                
                                                Text("功能特点：")
                                                    .font(.headline)
                                                
                                                VStack(alignment: .leading, spacing: 8) {
                                                    FeatureRow(icon: "globe", text: "支持多种语言翻译")
                                                    FeatureRow(icon: "server.rack", text: "支持多种LLM服务提供商")
                                                    FeatureRow(icon: "text.magnifyingglass", text: "智能语言检测")
                                                    FeatureRow(icon: "mic", text: "语音输入支持")
                                                    FeatureRow(icon: "speaker.wave.2", text: "文本朗读功能")
                                                    FeatureRow(icon: "clock", text: "翻译历史记录")
                                                    FeatureRow(icon: "key", text: "API密钥安全存储")
                                                }
                                                
                                                Text("© 2025 AI翻译团队")
                                                    .font(.footnote)
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            .padding()
                                        }
                                        .navigationTitle("关于应用")
                                        .navigationBarTitleDisplayMode(.inline)
                                ) {
                                    HStack {
                                        Image(systemName: "app.badge")
                                            .frame(width: 30)
                                            .foregroundColor(AppColors.accent)
                                        
                                        Text("应用信息")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showAddProvider) {
            AddProviderView(onSave: { provider in
                appState.addProvider(provider)
            })
        }
        // 使用独立的sheet修饰符，确保编辑提供商的sheet是独立的
        .sheet(item: $editingProvider) { provider in
            EditProviderView(
                provider: provider,
                onSave: { updatedProvider in
                    appState.updateProvider(updatedProvider)
                },
                onDelete: {
                    if let index = appState.providers.firstIndex(where: { $0.id == provider.id }) {
                        appState.removeProvider(at: index)
                    }
                }
            )
        }
    }
    
    private func updateAppearance() {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        if let window = windowScene?.windows.first {
            switch appearance {
            case "浅色":
                window.overrideUserInterfaceStyle = .light
            case "深色":
                window.overrideUserInterfaceStyle = .dark
            default:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}

// 为 LLMProvider 添加 Identifiable 支持
//extension LLMProvider: Identifiable { }

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
