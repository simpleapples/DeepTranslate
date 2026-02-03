//
//  EditProviderView.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct EditProviderView: View {
    // 传入的提供商和回调函数
    let provider: LLMProvider
    let onSave: (LLMProvider) -> Void
    
    // 状态变量
    @State private var name: String
    @State private var type: LLMProvider.ProviderType
    @State private var apiKey: String
    @State private var isKeyVisible = false
    @State private var modelName: String
    @State private var customEndpoint: String
    // No delete alert needed
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // 动态模型获取
    @State private var fetchedModels: [String] = []
    @State private var lastFetchedDate: Date?
    @State private var isFetchingModels = false
    
    @Environment(\.dismiss) var dismiss
    
    // 初始化函数 - 在这里设置所有状态变量的初始值
    init(provider: LLMProvider, onSave: @escaping (LLMProvider) -> Void) {
        print("EditProviderView初始化: \(provider.name)")
        self.provider = provider
        self.onSave = onSave
        // No delete callback
        
        // 初始化状态变量
        _name = State(initialValue: provider.name)
        _type = State(initialValue: provider.type)
        _apiKey = State(initialValue: provider.apiKey)
        _modelName = State(initialValue: provider.modelName)
        _customEndpoint = State(initialValue: provider.endpoint ?? "")
        _fetchedModels = State(initialValue: provider.cachedModels ?? [])
        _lastFetchedDate = State(initialValue: provider.lastFetchDate)
    }
    
    
    private var isFormValid: Bool {
        let isNameValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isModelValid = !modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // 对于自定义类型，API Key可以为空
        let isKeyValid: Bool
        if type == .custom {
            isKeyValid = !customEndpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            isKeyValid = !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        return isNameValid && isKeyValid && isModelValid
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    HStack {
                        Text("名称")
                        Spacer()
                        Text(name)
                            .foregroundColor(.secondary)
                    }
                    // 类型不再允许修改，已由提供商名称决定
                }
                
                Section(header: Text("API设置")) {
                    HStack {
                        if isKeyVisible {
                            TextField("API密钥", text: $apiKey)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("API密钥", text: $apiKey)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button(action: {
                            isKeyVisible.toggle()
                        }) {
                            Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        if type == .anthropic {
                            TextField("模型名称", text: $modelName)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            Text("模型名称")
                            Spacer()
                            
                            Menu {
                                Button(action: {
                                    fetchModels()
                                }) {
                                    Label(fetchedModels.isEmpty ? "获取模型列表" : "刷新列表", systemImage: "arrow.triangle.2.circlepath")
                                }
                                
                                Divider()
                                
                                if isFetchingModels {
                                    Text("加载中...")
                                } else if fetchedModels.isEmpty {
                                    Text("暂无可用模型")
                                } else {
                                    ForEach(fetchedModels, id: \.self) { model in
                                        Button(action: {
                                            modelName = model
                                        }) {
                                            HStack {
                                                Text(model)
                                                if modelName == model {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(modelName.isEmpty ? "点击选择模型" : modelName)
                                        .foregroundColor(modelName.isEmpty ? .secondary : .primary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .onAppear {
                                // 展开时如果列表为空，或者缓存过期(超过3天)，且(有API Key 或 类型为Custom)，自动获取
                                if !apiKey.isEmpty || type == .custom {
                                    if fetchedModels.isEmpty || isCacheExpired {
                                        print("Cache expired or empty, fetching models...")
                                        fetchModels()
                                    }
                                }
                            }
                        }
                    }
                    
                    if type == .custom {
                        TextField("自定义API端点", text: $customEndpoint)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                    }
                }
                
                Section(header: Text("提示信息"), footer: Text("所有API密钥都会安全地存储在您的设备上，不会上传到任何服务器")) {
                    switch type {
                    case .openai:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("填入您的OpenAI API密钥")
                            Text("推荐模型: gpt-4o, gpt-4, gpt-3.5-turbo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    case .deepseek:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("填入您的DeepSeek API密钥")
                            Text("推荐模型: deepseek-chat, deepseek-coder")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    case .anthropic:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("填入您的Anthropic API密钥")
                            Text("推荐模型: claude-3-opus, claude-3-sonnet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    case .gemini:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("填入您的Google AI API密钥")
                            Text("推荐模型: gemini-pro, gemini-ultra")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    case .mistral:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("填入您的Mistral API密钥")
                            Text("推荐模型: mistral-large, mistral-medium")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    case .custom:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("自定义API提供商需要完整的API端点URL")
                            Text("例如: https://api.example.com/v1/chat/completions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                   // Delete button removed
                }
            }
            .navigationTitle("编辑服务提供商")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveProvider()
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .blue : .gray)
                }
            }
            // Delete alert removed
            .alert("错误", isPresented: $showErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            print("EditProviderView出现: \(name), 类型: \(type.rawValue)")
        }
    }
    

    

    
    private func saveProvider() {
        do {
            // 验证自定义端点是否是有效URL
            if type == .custom {
                let trimmedEndpoint = customEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedEndpoint.isEmpty else {
                    throw ValidationError.emptyEndpoint
                }
                
                guard let url = URL(string: trimmedEndpoint) else {
                    throw ValidationError.invalidURL
                }
                
                guard url.scheme == "http" || url.scheme == "https" else {
                    throw ValidationError.invalidScheme
                }
            }
            
            // 构建更新后的提供商对象
            let updatedProvider = LLMProvider(
                id: provider.id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                modelName: modelName.trimmingCharacters(in: .whitespacesAndNewlines),
                isActive: provider.isActive,
                endpoint: type == .custom ? customEndpoint.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                cachedModels: fetchedModels.isEmpty ? nil : fetchedModels,
                lastFetchDate: fetchedModels.isEmpty ? nil : lastFetchedDate
            )
            
            // 调用保存回调
            onSave(updatedProvider)
            
            // 关闭视图
            dismiss()
        } catch let error as ValidationError {
            // 显示验证错误
            errorMessage = error.errorMessage
            showErrorAlert = true
        } catch {
            // 显示通用错误
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private func fetchModels() {
        guard !apiKey.isEmpty || type == .custom else {
            errorMessage = "请先输入API密钥"
            showErrorAlert = true
            return
        }
        
        isFetchingModels = true
        
        Task {
            do {
                let models = try await ModelFetcher.fetchModels(for: type, apiKey: apiKey, customEndpoint: customEndpoint)
                
                await MainActor.run {
                    self.fetchedModels = models
                    self.lastFetchedDate = Date() // 更新获取时间
                    self.isFetchingModels = false
                    
                    if models.isEmpty {
                        self.errorMessage = "未找到可用的模型列表，请检查API密钥或手动输入"
                        self.showErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isFetchingModels = false
                    self.errorMessage = "获取失败: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    // 检查缓存是否过期 (3天)
    private var isCacheExpired: Bool {
        guard let date = lastFetchedDate else { return true }
        // 3天 = 3 * 24 * 60 * 60 秒
        // return Date().timeIntervalSince(date) > 10 // For testing
        return Date().timeIntervalSince(date) > 259200
    }
}

// 验证错误类型
enum ValidationError: Error {
    case emptyEndpoint
    case invalidURL
    case invalidScheme
    
    var errorMessage: String {
        switch self {
        case .emptyEndpoint:
            return "自定义服务需要填写API端点"
        case .invalidURL:
            return "无效的URL格式"
        case .invalidScheme:
            return "URL必须以http或https开头"
        }
    }
}

struct EditProviderView_Previews: PreviewProvider {
    static var previews: some View {
        EditProviderView(
            provider: LLMProvider(
                name: "OpenAI",
                type: .openai,
                apiKey: "sk-1234",
                modelName: "gpt-4o",
                isActive: true
            ),
            onSave: { _ in }
        )
    }
}
