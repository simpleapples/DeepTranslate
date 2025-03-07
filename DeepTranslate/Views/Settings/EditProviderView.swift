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
    let onDelete: () -> Void
    
    // 状态变量
    @State private var name: String
    @State private var type: LLMProvider.ProviderType
    @State private var apiKey: String
    @State private var isKeyVisible = false
    @State private var modelName: String
    @State private var customEndpoint: String
    @State private var showDeleteAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) var dismiss
    
    // 初始化函数 - 在这里设置所有状态变量的初始值
    init(provider: LLMProvider, onSave: @escaping (LLMProvider) -> Void, onDelete: @escaping () -> Void) {
        print("EditProviderView初始化: \(provider.name)")
        self.provider = provider
        self.onSave = onSave
        self.onDelete = onDelete
        
        // 初始化状态变量
        _name = State(initialValue: provider.name)
        _type = State(initialValue: provider.type)
        _apiKey = State(initialValue: provider.apiKey)
        _modelName = State(initialValue: provider.modelName)
        _customEndpoint = State(initialValue: provider.endpoint ?? "")
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (type != .custom || !customEndpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("名称", text: $name)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Picker("类型", selection: $type) {
                        Text("OpenAI").tag(LLMProvider.ProviderType.openai)
                        Text("DeepSeek").tag(LLMProvider.ProviderType.deepseek)
                        Text("Anthropic").tag(LLMProvider.ProviderType.anthropic)
                        Text("Gemini").tag(LLMProvider.ProviderType.gemini)
                        Text("Mistral").tag(LLMProvider.ProviderType.mistral)
                        Text("自定义").tag(LLMProvider.ProviderType.custom)
                    }
                    .onChange(of: type) { _ in
                        updateModelNameForType()
                    }
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
                    
                    TextField("模型名称", text: $modelName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
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
                    Button(role: .destructive, action: {
                        showDeleteAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("删除此提供商")
                            Spacer()
                        }
                    }
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
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("您确定要删除此服务提供商吗？此操作无法撤销。")
            }
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
    
    // 根据类型更新默认的模型名称
    private func updateModelNameForType() {
        // 如果用户更改了类型，并且模型名称尚未手动更改（仍为默认值），则更新它
        switch type {
        case .openai:
            if modelName == defaultModelName(for: provider.type) || modelName.isEmpty {
                modelName = "gpt-4o"
            }
        case .deepseek:
            if modelName == defaultModelName(for: provider.type) || modelName.isEmpty {
                modelName = "deepseek-chat"
            }
        case .anthropic:
            if modelName == defaultModelName(for: provider.type) || modelName.isEmpty {
                modelName = "claude-3-sonnet"
            }
        case .gemini:
            if modelName == defaultModelName(for: provider.type) || modelName.isEmpty {
                modelName = "gemini-pro"
            }
        case .mistral:
            if modelName == defaultModelName(for: provider.type) || modelName.isEmpty {
                modelName = "mistral-large"
            }
        case .custom:
            break // 不更改自定义模型名称
        }
    }
    
    // 获取特定类型的默认模型名称
    private func defaultModelName(for type: LLMProvider.ProviderType) -> String {
        switch type {
        case .openai: return "gpt-4o"
        case .deepseek: return "deepseek-chat"
        case .anthropic: return "claude-3-sonnet"
        case .gemini: return "gemini-pro"
        case .mistral: return "mistral-large"
        case .custom: return ""
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
                endpoint: type == .custom ? customEndpoint.trimmingCharacters(in: .whitespacesAndNewlines) : nil
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
            onSave: { _ in },
            onDelete: {}
        )
    }
}
