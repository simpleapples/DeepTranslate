//
//  TranslationStrategies.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import Foundation

class BaseTranslationStrategy: TranslationStrategy {
    let provider: LLMProvider
    
    init(provider: LLMProvider) {
        self.provider = provider
    }
    
    func translate(text: String, from sourceLanguage: Language, to targetLanguage: Language) async throws -> String {
        fatalError("Must be overridden by subclass")
    }
    
    func createRequest(url: URL, method: String = "POST", headers: [String: String], body: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = body
        return request
    }
    
    func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "TranslationError", code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                          userInfo: [NSLocalizedDescriptionKey: "\(provider.name) API Error: \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

class OpenAITranslationStrategy: BaseTranslationStrategy {
    override func translate(text: String, from sourceLanguage: Language, to targetLanguage: Language) async throws -> String {
        let url = URL(string: provider.apiEndpoint)!
        
        let prompt = """
        Please translate the following \(sourceLanguage.name) text to \(targetLanguage.name):
        
        \(text)
        
        Return only the translated text, no extra content.
        """
        
        let requestBody: [String: Any] = [
            "model": provider.modelName,
            "messages": [
                ["role": "system", "content": "You are a professional translator. Just provide the accurate translation, no extra content."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(provider.apiKey)"
        ]
        
        let request = createRequest(url: url, headers: headers, body: jsonData)
        let response = try await performRequest(request, responseType: OpenAIResponse.self)
        
        guard let choice = response.choices.first else {
            throw NSError(domain: "TranslationError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Empty response from OpenAI"])
        }
        return choice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

class DeepSeekTranslationStrategy: OpenAITranslationStrategy {
    // DeepSeek API is compatible with OpenAI, reusing logic
}

class MistralTranslationStrategy: OpenAITranslationStrategy {
    // Mistral API is compatible with OpenAI, reusing logic
}

class AnthropicTranslationStrategy: BaseTranslationStrategy {
    override func translate(text: String, from sourceLanguage: Language, to targetLanguage: Language) async throws -> String {
        let url = URL(string: provider.apiEndpoint)!
        
        let prompt = """
        Please translate the following \(sourceLanguage.name) text to \(targetLanguage.name):
        
        \(text)
        
        Return only the translated text, no extra content.
        """
        
        let requestBody: [String: Any] = [
            "model": provider.modelName,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 1000,
            "temperature": 0.1
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        let headers = [
            "Content-Type": "application/json",
            "x-api-version": "2023-06-01",
            "Authorization": "Bearer \(provider.apiKey)"
        ]
        
        let request = createRequest(url: url, headers: headers, body: jsonData)
        let response = try await performRequest(request, responseType: AnthropicResponse.self)
        
        guard let content = response.content.first else {
            throw NSError(domain: "TranslationError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Empty response from Anthropic"])
        }
        return content.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

class GeminiTranslationStrategy: BaseTranslationStrategy {
    override func translate(text: String, from sourceLanguage: Language, to targetLanguage: Language) async throws -> String {
        let url = URL(string: provider.apiEndpoint + "?key=\(provider.apiKey)")!
        
        let prompt = """
        Please translate the following \(sourceLanguage.name) text to \(targetLanguage.name):
        
        \(text)
        
        Return only the translated text, no extra content.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.1
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        let headers = ["Content-Type": "application/json"]
        
        let request = createRequest(url: url, headers: headers, body: jsonData)
        let response = try await performRequest(request, responseType: GeminiResponse.self)
        
        guard let candidate = response.candidates.first, let part = candidate.content.parts.first else {
            throw NSError(domain: "TranslationError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Empty response from Gemini"])
        }
        return part.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

class CustomTranslationStrategy: BaseTranslationStrategy {
    override func translate(text: String, from sourceLanguage: Language, to targetLanguage: Language) async throws -> String {
        guard let endpoint = provider.endpoint, !endpoint.isEmpty else {
             throw NSError(domain: "TranslationError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Custom endpoint not set"])
        }
        
        let url = URL(string: endpoint)!
        
        let prompt = """
        Please translate the following \(sourceLanguage.name) text to \(targetLanguage.name):
        
        \(text)
        
        Return only the translated text, no extra content.
        """
        
        // Assuming OpenAI-compatible format for custom providers as a safe default or make it generic?
        // Using "system" + "user" messages is standard for many local LLMs (like via LM Studio/Ollama)
        let requestBody: [String: Any] = [
            "model": provider.modelName,
            "messages": [
                ["role": "system", "content": "You are a professional translator. Just provide the accurate translation, no extra content."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(provider.apiKey)"
        ]
        
        let request = createRequest(url: url, headers: headers, body: jsonData)
        
        // For custom, we might need manual parsing if it doesn't strictly follow OpenAI.
        // But for now, let's try OpenAIResponse as it's the most common target.
        // Fallback to plain text if JSON fails?
        
        do {
            let response = try await performRequest(request, responseType: OpenAIResponse.self)
            return response.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
             // Fallback: try to read raw string if it's not JSON
             let (data, _) = try await URLSession.shared.data(for: request)
             if let str = String(data: data, encoding: .utf8) {
                 return str.trimmingCharacters(in: .whitespacesAndNewlines)
             }
             throw error
        }
    }
}
