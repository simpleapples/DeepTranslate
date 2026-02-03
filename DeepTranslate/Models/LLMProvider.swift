//
//  LLMProvider.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import Foundation

struct LLMProvider: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var type: ProviderType
    var apiKey: String
    var modelName: String
    var isActive: Bool
    var endpoint: String?
    var cachedModels: [String]? // 缓存的模型列表
    var lastFetchDate: Date? // 上次获取模型的时间
    
    enum ProviderType: String, Codable {
        case openai = "OpenAI"
        case deepseek = "DeepSeek"
        case anthropic = "Anthropic"
        case gemini = "Gemini"
        case mistral = "Mistral"
        case custom = "自定义"
    }
    
    init(id: UUID = UUID(), name: String, type: ProviderType, apiKey: String, modelName: String, isActive: Bool, endpoint: String? = nil, cachedModels: [String]? = nil, lastFetchDate: Date? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.apiKey = apiKey
        self.modelName = modelName
        self.isActive = isActive
        self.endpoint = endpoint
        self.cachedModels = cachedModels
        self.lastFetchDate = lastFetchDate
    }
    
    static let defaultProviders: [LLMProvider] = [
        LLMProvider(name: "OpenAI", type: .openai, apiKey: "", modelName: "", isActive: true),
        LLMProvider(name: "DeepSeek", type: .deepseek, apiKey: "", modelName: "", isActive: false),
        LLMProvider(name: "Anthropic", type: .anthropic, apiKey: "", modelName: "", isActive: false),
        LLMProvider(name: "Gemini", type: .gemini, apiKey: "", modelName: "", isActive: false),
        LLMProvider(name: "Mistral", type: .mistral, apiKey: "", modelName: "", isActive: false)
    ]
    
    // 获取API端点
    var apiEndpoint: String {
        if type == .custom, let customEndpoint = endpoint, !customEndpoint.isEmpty {
            return customEndpoint
        }
        
        switch type {
        case .openai:
            return "https://api.openai.com/v1/chat/completions"
        case .deepseek:
            return "https://api.deepseek.com/chat/completions"
        case .anthropic:
            return "https://api.anthropic.com/v1/messages"
        case .gemini:
            return "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent"
        case .mistral:
            return "https://api.mistral.ai/v1/chat/completions"
        case .custom:
            return "" // 用户需要提供完整URL
        }
    }
}
