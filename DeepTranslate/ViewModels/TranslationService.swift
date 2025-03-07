//
//  TranslationService.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import Foundation
import AVFoundation
import Combine

class TranslationService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isTranslating = false
    @Published var isSpeaking = false
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        // 设置语音合成器的代理
        speechSynthesizer.delegate = self
    }
    
    // 实现 AVSpeechSynthesizerDelegate 方法
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    // 翻译方法
    func translate(text: String, from sourceLanguage: Language, to targetLanguage: Language,
                   using provider: LLMProvider) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ""
        }
        
        guard !provider.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "TranslationError", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "未设置\(provider.name) API密钥"])
        }
        
        DispatchQueue.main.async {
            self.isTranslating = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isTranslating = false
            }
        }
        
        // 根据不同的提供商使用不同的API调用方式
        switch provider.type {
        case .openai:
            return try await translateWithOpenAI(text: text, from: sourceLanguage, to: targetLanguage, provider: provider)
        case .deepseek:
            return try await translateWithDeepSeek(text: text, from: sourceLanguage, to: targetLanguage, provider: provider)
        case .anthropic:
            return try await translateWithAnthropic(text: text, from: sourceLanguage, to: targetLanguage, provider: provider)
        case .gemini:
            return try await translateWithGemini(text: text, from: sourceLanguage, to: targetLanguage, provider: provider)
        case .mistral:
            return try await translateWithMistral(text: text, from: sourceLanguage, to: targetLanguage, provider: provider)
        case .custom:
            return try await translateWithCustomAPI(text: text, from: sourceLanguage, to: targetLanguage, provider: provider)
        }
    }
    
    // OpenAI翻译实现
    private func translateWithOpenAI(text: String, from sourceLanguage: Language, to targetLanguage: Language,
                                   provider: LLMProvider) async throws -> String {
        let url = URL(string: provider.apiEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        
        // 构建翻译提示
        let prompt = """
        请将以下\(sourceLanguage.name)文本翻译成\(targetLanguage.name)：
        
        \(text)
        
        仅返回翻译后的文本，不要包含任何解释或额外信息。
        """
        
        let requestBody: [String: Any] = [
            "model": provider.modelName,
            "messages": [
                ["role": "system", "content": "你是一个专业的翻译助手，只需提供准确的翻译，不要添加任何额外内容。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "TranslationError", code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                          userInfo: [NSLocalizedDescriptionKey: "\(provider.name) API错误: \(errorMessage)"])
        }
        
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = jsonResponse["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let translatedText = message["content"] as? String else {
            throw NSError(domain: "TranslationError", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "无法解析\(provider.name) API响应"])
        }
        
        return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // DeepSeek翻译实现
    private func translateWithDeepSeek(text: String, from sourceLanguage: Language, to targetLanguage: Language,
                                     provider: LLMProvider) async throws -> String {
        let url = URL(string: provider.apiEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        
        // 构建翻译提示
        let prompt = """
        请将以下\(sourceLanguage.name)文本翻译成\(targetLanguage.name)：
        
        \(text)
        
        仅返回翻译后的文本，不要包含任何解释或额外信息。
        """
        
        let requestBody: [String: Any] = [
            "model": provider.modelName,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "TranslationError", code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                          userInfo: [NSLocalizedDescriptionKey: "\(provider.name) API错误: \(errorMessage)"])
        }
        
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = jsonResponse["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let translatedText = message["content"] as? String else {
            throw NSError(domain: "TranslationError", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "无法解析\(provider.name) API响应"])
        }
        
        return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Anthropic翻译实现
    private func translateWithAnthropic(text: String, from sourceLanguage: Language, to targetLanguage: Language,
                                       provider: LLMProvider) async throws -> String {
        let url = URL(string: provider.apiEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("anthropic-version: 2023-06-01", forHTTPHeaderField: "x-api-version")
        request.addValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        
        // 构建翻译提示
        let prompt = """
        请将以下\(sourceLanguage.name)文本翻译成\(targetLanguage.name)：
        
        \(text)
        
        仅返回翻译后的文本，不要包含任何解释或额外信息。
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
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "TranslationError", code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                          userInfo: [NSLocalizedDescriptionKey: "\(provider.name) API错误: \(errorMessage)"])
        }
        
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = jsonResponse["content"] as? [[String: Any]],
              let firstContent = content.first,
              let translatedText = firstContent["text"] as? String else {
            throw NSError(domain: "TranslationError", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "无法解析\(provider.name) API响应"])
        }
        
        return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Gemini翻译实现
    private func translateWithGemini(text: String, from sourceLanguage: Language, to targetLanguage: Language,
                                    provider: LLMProvider) async throws -> String {
        let url = URL(string: provider.apiEndpoint + "?key=\(provider.apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 构建翻译提示
        let prompt = """
        请将以下\(sourceLanguage.name)文本翻译成\(targetLanguage.name)：
        
        \(text)
        
        仅返回翻译后的文本，不要包含任何解释或额外信息。
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
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "TranslationError", code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                          userInfo: [NSLocalizedDescriptionKey: "\(provider.name) API错误: \(errorMessage)"])
        }
        
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = jsonResponse["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let translatedText = firstPart["text"] as? String else {
            throw NSError(domain: "TranslationError", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "无法解析\(provider.name) API响应"])
        }
        
        return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Mistral翻译实现
    private func translateWithMistral(text: String, from sourceLanguage: Language, to targetLanguage: Language,
                                     provider: LLMProvider) async throws -> String {
        let url = URL(string: provider.apiEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        
        // 构建翻译提示
        let prompt = """
        请将以下\(sourceLanguage.name)文本翻译成\(targetLanguage.name)：
        
        \(text)
        
        仅返回翻译后的文本，不要包含任何解释或额外信息。
        """
        
        let requestBody: [String: Any] = [
            "model": provider.modelName,
            "messages": [
                ["role": "system", "content": "你是一个专业的翻译助手，只需提供准确的翻译，不要添加任何额外内容。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "TranslationError", code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                          userInfo: [NSLocalizedDescriptionKey: "\(provider.name) API错误: \(errorMessage)"])
        }
        
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = jsonResponse["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let translatedText = message["content"] as? String else {
            throw NSError(domain: "TranslationError", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "无法解析\(provider.name) API响应"])
        }
        
        return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // 自定义API翻译实现
    private func translateWithCustomAPI(text: String, from sourceLanguage: Language, to targetLanguage: Language,
                                       provider: LLMProvider) async throws -> String {
        guard let endpoint = provider.endpoint, !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "TranslationError", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "未设置自定义API端点"])
        }
        
        let url = URL(string: endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        
        // 构建翻译提示
        let prompt = """
        请将以下\(sourceLanguage.name)文本翻译成\(targetLanguage.name)：
        
        \(text)
        
        仅返回翻译后的文本，不要包含任何解释或额外信息。
        """
        
        let requestBody: [String: Any] = [
            "model": provider.modelName,
            "messages": [
                ["role": "system", "content": "你是一个专业的翻译助手，只需提供准确的翻译，不要添加任何额外内容。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "TranslationError", code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                          userInfo: [NSLocalizedDescriptionKey: "\(provider.name) API错误: \(errorMessage)"])
        }
        
        // 简化处理，实际应用中需要根据API的实际响应格式进行解析
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "TranslationError", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "无法解析\(provider.name) API响应"])
        }
        
        return responseString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // 文本转语音
    func speak(text: String, language: Language) {
        // 如果已经在说话，先停止
        if isSpeaking {
            stopSpeaking()
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language.code)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // 代理方法会处理状态更新
        speechSynthesizer.speak(utterance)
    }
    
    // 停止语音播放
    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
}
