//
//  AddProviderView.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct AddProviderView: View {
    // MARK: - Properties
    
    // Callback to handle saving
    let onSave: (LLMProvider) -> Void
    
    // Input state
    @State private var name = ""
    @State private var type = LLMProvider.ProviderType.openai
    @State private var apiKey = ""
    @State private var isKeyVisible = false
    @State private var modelName = ""
    @State private var customEndpoint = ""
    
    // UI state
    @State private var alertItem: AlertItem?
    @State private var isShowingAlert = false
    
    // Environment
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !apiKey.isEmpty &&
        !modelName.isEmpty &&
        (type != .custom || !customEndpoint.isEmpty)
    }
    
    // MARK: - View
    
    var body: some View {
        NavigationView {
            List {
                // Basic Info Section
                Section(header: Text("基本信息")) {
                    TextField("服务名称", text: $name)
                        .disableAutocorrection(true)
                    
                    providerTypePicker
                }
                
                // API Settings Section
                Section(header: Text("API设置")) {
                    apiKeyField
                    
                    TextField("模型名称", text: $modelName)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    
                    if type == .custom {
                        TextField("API端点", text: $customEndpoint)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .keyboardType(.URL)
                    }
                }
                
                // Help Section
                Section(header: Text("提示信息")) {
                    providerHelpText
                }
            }
            .listStyle(InsetGroupedListStyle())
            .onAppear(perform: setInitialModelName)
            .navigationTitle("添加服务提供商")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                saveButton
            }
            .alert(isPresented: $isShowingAlert) {
                Alert(
                    title: Text(alertItem?.title ?? "错误"),
                    message: Text(alertItem?.message ?? "发生未知错误"),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var providerTypePicker: some View {
        Picker("类型", selection: $type) {
            ForEach(LLMProvider.ProviderType.allCases, id: \.self) { providerType in
                Text(providerType.rawValue).tag(providerType)
            }
        }
        .onChange(of: type) { _ in
            updateModelNameForType()
        }
    }
    
    private var apiKeyField: some View {
        HStack {
            Group {
                if isKeyVisible {
                    TextField("API密钥", text: $apiKey)
                } else {
                    SecureField("API密钥", text: $apiKey)
                }
            }
            .disableAutocorrection(true)
            .autocapitalization(.none)
            
            Button(action: { isKeyVisible.toggle() }) {
                Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var providerHelpText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(helpTitleForType)
                .font(.subheadline)
            
            Text(helpModelSuggestionForType)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if type == .custom {
                Text("例如: https://api.example.com/v1/chat/completions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
    }
    
    private var cancelButton: ToolbarItem<(), some View> {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("取消") {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private var saveButton: ToolbarItem<(), some View> {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("保存") {
                saveProvider()
            }
            .disabled(!isFormValid)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setInitialModelName() {
        if modelName.isEmpty {
            updateModelNameForType()
        }
    }
    
    private func updateModelNameForType() {
        switch type {
        case .openai:
            modelName = "gpt-4o"
        case .deepseek:
            modelName = "deepseek-chat"
        case .anthropic:
            modelName = "claude-3-sonnet"
        case .gemini:
            modelName = "gemini-pro"
        case .mistral:
            modelName = "mistral-large"
        case .custom:
            // Don't set default for custom type
            break
        }
    }
    
    private var helpTitleForType: String {
        switch type {
        case .openai:
            return "填入您的OpenAI API密钥"
        case .deepseek:
            return "填入您的DeepSeek API密钥"
        case .anthropic:
            return "填入您的Anthropic API密钥"
        case .gemini:
            return "填入您的Google AI API密钥"
        case .mistral:
            return "填入您的Mistral API密钥"
        case .custom:
            return "填入自定义API服务的信息"
        }
    }
    
    private var helpModelSuggestionForType: String {
        switch type {
        case .openai:
            return "推荐模型: gpt-4o, gpt-4, gpt-3.5-turbo"
        case .deepseek:
            return "推荐模型: deepseek-chat, deepseek-coder"
        case .anthropic:
            return "推荐模型: claude-3-opus, claude-3-sonnet"
        case .gemini:
            return "推荐模型: gemini-pro, gemini-ultra"
        case .mistral:
            return "推荐模型: mistral-large, mistral-medium"
        case .custom:
            return "填入您希望使用的模型名称"
        }
    }
    
    private func saveProvider() {
        do {
            // Validate inputs
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedModelName = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedName.isEmpty else {
                throw ValidationError.emptyName
            }
            
            guard !trimmedApiKey.isEmpty else {
                throw ValidationError.emptyApiKey
            }
            
            guard !trimmedModelName.isEmpty else {
                throw ValidationError.emptyModelName
            }
            
            var endpoint: String? = nil
            
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
                
                endpoint = trimmedEndpoint
            }
            
            // Create provider
            let newProvider = LLMProvider(
                name: trimmedName,
                type: type,
                apiKey: trimmedApiKey,
                modelName: trimmedModelName,
                isActive: false,
                endpoint: endpoint
            )
            
            // Save provider
            onSave(newProvider)
            
            // Dismiss view
            presentationMode.wrappedValue.dismiss()
        } catch let error as ValidationError {
            // Show validation error
            alertItem = AlertItem(
                title: "验证失败",
                message: error.errorMessage
            )
            isShowingAlert = true
        } catch {
            // Show general error
            alertItem = AlertItem(
                title: "保存失败",
                message: error.localizedDescription
            )
            isShowingAlert = true
        }
    }
}

// MARK: - Supporting Types

extension AddProviderView {
    enum ValidationError: Error {
        case emptyName
        case emptyApiKey
        case emptyModelName
        case emptyEndpoint
        case invalidURL
        case invalidScheme
        
        var errorMessage: String {
            switch self {
            case .emptyName:
                return "服务名称不能为空"
            case .emptyApiKey:
                return "API密钥不能为空"
            case .emptyModelName:
                return "模型名称不能为空"
            case .emptyEndpoint:
                return "自定义服务需要填写API端点"
            case .invalidURL:
                return "无效的URL格式"
            case .invalidScheme:
                return "URL必须以http或https开头"
            }
        }
    }
    
    struct AlertItem {
        let title: String
        let message: String
    }
}

extension LLMProvider.ProviderType: CaseIterable {
    public static var allCases: [LLMProvider.ProviderType] {
        return [.openai, .deepseek, .anthropic, .gemini, .mistral, .custom]
    }
}

struct AddProviderView_Previews: PreviewProvider {
    static var previews: some View {
        AddProviderView { _ in }
    }
}
