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
        
        // 创建对应的策略
        let strategy = createStrategy(for: provider)
        return try await strategy.translate(text: text, from: sourceLanguage, to: targetLanguage)
    }
    
    // 策略工厂方法
    private func createStrategy(for provider: LLMProvider) -> TranslationStrategy {
        switch provider.type {
        case .openai:
            return OpenAITranslationStrategy(provider: provider)
        case .deepseek:
            return DeepSeekTranslationStrategy(provider: provider)
        case .anthropic:
            return AnthropicTranslationStrategy(provider: provider)
        case .gemini:
            return GeminiTranslationStrategy(provider: provider)
        case .mistral:
            return MistralTranslationStrategy(provider: provider)
        case .custom:
            return CustomTranslationStrategy(provider: provider)
        }
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
