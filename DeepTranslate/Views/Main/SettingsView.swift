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
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    // 获取应用构建号
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // 开发者邮箱
    let developerEmail = "zangzhiya@gmail.com"
    
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
                                // 源代码
                                Link(destination: URL(string: "https://github.com/simpleapples/DeepTranslate")!) {
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
                                .cornerRadius(12, corners: [.topLeft, .topRight])
                                
                                Divider()
                                    .padding(.leading, 60)
                                    .opacity(0.5)
                                
                                // 应用信息
                                NavigationLink(
                                    destination:
                                        ScrollView {
                                            VStack(spacing: 30) {
                                                // 应用logo - 使用AppIcon
                                                Group {
                                                    // 尝试从Info.plist获取应用图标
                                                    if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                                                       let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
                                                       let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
                                                       let lastIcon = iconFiles.last {
                                                        Image(uiImage: UIImage(named: lastIcon) ?? UIImage())
                                                            .resizable()
                                                            .scaledToFit()
                                                    } else {
                                                        // 备选方案：直接尝试使用"AppIcon"
                                                        Image(uiImage: UIImage(named: "AppIcon") ?? UIImage(systemName: "text.bubble.fill")!)
                                                            .resizable()
                                                            .scaledToFit()
                                                            .foregroundColor(UIImage(named: "AppIcon") == nil ? .blue : .primary)
                                                    }
                                                }
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(20)
                                                .shadow(radius: 5)
                                                .padding(.top, 40)
                                                // 确保最大尺寸不超过512px
                                                .frame(maxWidth: 512, maxHeight: 512)
                                                
                                                // 应用名称和版本信息
                                                VStack(spacing: 8) {
                                                    Text("DeepTranslate")
                                                        .font(.title)
                                                        .fontWeight(.bold)
                                                    
                                                    Text("版本 \(appVersion) (\(buildNumber))")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Divider()
                                                    .padding(.horizontal)
                                                
                                                // 联系信息部分
                                                VStack(alignment: .leading, spacing: 15) {
                                                    Text("联系与支持")
                                                        .font(.headline)
                                                        .padding(.leading)
                                                    
                                                    // 邮箱联系卡片
                                                    Button(action: {
                                                        sendEmail()
                                                    }) {
                                                        HStack {
                                                            Image(systemName: "envelope.fill")
                                                                .foregroundColor(.blue)
                                                                .font(.system(size: 20))
                                                            
                                                            VStack(alignment: .leading, spacing: 4) {
                                                                Text("反馈与建议")
                                                                    .font(.headline)
                                                                    .foregroundColor(.primary)
                                                                
                                                                Text(developerEmail)
                                                                    .font(.subheadline)
                                                                    .foregroundColor(.secondary)
                                                            }
                                                            
                                                            Spacer()
                                                            
                                                            Image(systemName: "chevron.right")
                                                                .foregroundColor(.gray)
                                                                .font(.footnote)
                                                        }
                                                        .padding()
                                                        .background(Color(.systemBackground))
                                                        .cornerRadius(10)
                                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                                    }
                                                    .padding(.horizontal)
                                                    
                                                    Text("如有任何问题或建议，请随时通过邮件联系我，我会尽快回复。")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                        .padding(.horizontal)
                                                }
                                                
                                                Spacer()
                                                
                                                // 版权信息
                                                Text("© \(String(Calendar.current.component(.year, from: Date()))) DeepTranslate")
                                                    .font(.footnote)
                                                    .foregroundColor(.secondary)
                                                    .padding(.bottom, 20)
                                            }
                                            .padding()
                                        }
                                        .navigationTitle("关于")
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
    
    func sendEmail() {
        // 创建邮件URL
        if let url = URL(string: "mailto:\(developerEmail)?subject=[反馈]DeepTranslate") {
            // 检查设备是否可以打开URL
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
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
