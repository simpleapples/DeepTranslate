//
//  ModelFetcher.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import Foundation

class ModelFetcher {
    static func fetchModels(for type: LLMProvider.ProviderType, apiKey: String, customEndpoint: String? = nil) async throws -> [String] {
        // 对于非Custom类型，Key不能为空
        if type != .custom && apiKey.isEmpty { return [] }
        
        let url: URL
        var headers: [String: String] = [:]
        
        switch type {
        case .openai:
            url = URL(string: "https://api.openai.com/v1/models")!
            headers["Authorization"] = "Bearer \(apiKey)"
            return try await fetchOpenAIStyleModels(url: url, headers: headers)
            
        case .deepseek:
            // DeepSeek base models URL
            url = URL(string: "https://api.deepseek.com/models")!
            headers["Authorization"] = "Bearer \(apiKey)"
            return try await fetchOpenAIStyleModels(url: url, headers: headers)
            
        case .mistral:
            url = URL(string: "https://api.mistral.ai/v1/models")!
            headers["Authorization"] = "Bearer \(apiKey)"
            return try await fetchOpenAIStyleModels(url: url, headers: headers)
            
        case .gemini:
            url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)")!
            return try await fetchGeminiModels(url: url)
            
        case .custom:
            // 尝试从自定义端点推断models端点
            // 通常自定义端点是 .../chat/completions
            guard let endpoint = customEndpoint, !endpoint.isEmpty else { return [] }
            
            var modelsURLString = endpoint
            if modelsURLString.hasSuffix("/chat/completions") {
                modelsURLString = modelsURLString.replacingOccurrences(of: "/chat/completions", with: "/models")
            } else if modelsURLString.hasSuffix("/messages") { // Anthropic-like?
                 // Custom unlikely to support list models easily if not OpenAI compatible
                 return []
            } else {
                 // 尝试直接追加 /models ? 或者假设它是base url
                 if !modelsURLString.hasSuffix("/") {
                     modelsURLString += "/models"
                 } else {
                     modelsURLString += "models"
                 }
            }
            
            guard let validURL = URL(string: modelsURLString) else { return [] }
            
            // 只有当apiKey不为空时才添加Authorization头
            if !apiKey.isEmpty {
                headers["Authorization"] = "Bearer \(apiKey)"
            }
            return try await fetchOpenAIStyleModels(url: validURL, headers: headers)
            
        case .anthropic:
             // Anthropic API 不直接支持列出模型
            return []
        }
    }
    
    private static func fetchOpenAIStyleModels(url: URL, headers: [String: String]) async throws -> [String] {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "ModelFetchError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch models"])
        }
        
        let decoded = try JSONDecoder().decode(OpenAIModelListResponse.self, from: data)
        let models = decoded.data.map { $0.id }
        return filterModels(models).sorted()
    }
    
    private static func fetchGeminiModels(url: URL) async throws -> [String] {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "ModelFetchError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch Gemini models"])
        }
        
        let decoded = try JSONDecoder().decode(GeminiModelListResponse.self, from: data)
        // Strip "models/" prefix if present
        let models = decoded.models.map { model in
            return model.name.replacingOccurrences(of: "models/", with: "")
        }
        return filterModels(models).sorted()
    }
    
    // 过滤掉不适合翻译的模型（如画图、Embedding、音频、Coding等）
    private static func filterModels(_ models: [String]) -> [String] {
        let excludedKeywords = [
            "dall-e", "tts", "whisper", "embedding", "embed", "moderation", "davinci", "babbage", "curie", "ada", // OpenAI legacy/non-chat
            "image", "audio", "video", // General
            "vision", // General vision
            "coder", "code-", // Coding specific
        ]
        
        return models.filter { model in
            let lowercased = model.lowercased()
            // 排除包含关键词的模型
            for keyword in excludedKeywords {
                if lowercased.contains(keyword) {
                    return false
                }
            }
            return true
        }
    }
}
