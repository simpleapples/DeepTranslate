//
//  SettingsView.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var editingProvider: LLMProvider? = nil

    
    let appearanceOptions = ["浅色", "深色", "系统"]
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    // 获取应用构建号
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // 开发者邮箱
    let developerEmail = "zangzhiya@gmail.com"
    
    var body: some View {
        NavigationView {
            List {
                // LLM服务提供商设置
                Section(header: Text("LLM服务提供商"), footer: Text("仅支持编辑现有提供商配置")) {
                    ForEach(Array(appState.providers.enumerated()), id: \.element.id) { index, provider in
                        ProviderRow(
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
                    }
                }
                
                // 关于应用
                Section(header: Text("关于")) {
                    // 源代码
                    Link(destination: URL(string: "https://github.com/simpleapples/DeepTranslate")!) {
                        HStack {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .frame(width: 24)
                                .foregroundColor(AppColors.accent)
                            Text("源代码")
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 应用信息
                    NavigationLink(destination: AboutView(appVersion: appVersion, buildNumber: buildNumber, developerEmail: developerEmail)) {
                        HStack {
                            Image(systemName: "app.badge")
                                .frame(width: 24)
                                .foregroundColor(AppColors.accent)
                            Text("应用信息")
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle()) // 使用原生分组样式
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
//        .sheet(isPresented: $showAddProvider) {
//            AddProviderView(onSave: { provider in
//                appState.addProvider(provider)
//            })
//        }
        // 使用独立的sheet修饰符，确保编辑提供商的sheet是独立的
        .sheet(item: $editingProvider) { provider in
            EditProviderView(
                provider: provider,
                onSave: { updatedProvider in
                    appState.updateProvider(updatedProvider)
                }
            )
        }
    }
    
    func sendEmail() {
        // 创建邮件URL
        if let url = URL(string: "mailto:\(developerEmail)?subject=[反馈]DeepTranslate") {
            // 检查设备是否可以打开URL
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}
