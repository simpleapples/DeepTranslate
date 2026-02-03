//
//  TranslationProtocol.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import Foundation

/// Defines the strategy for translating text
protocol TranslationStrategy {
    var provider: LLMProvider { get }
    func translate(text: String, from sourceLanguage: Language, to targetLanguage: Language) async throws -> String
}

// MARK: - API Response Models

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

struct AnthropicResponse: Codable {
    struct Content: Codable {
        let text: String
    }
    let content: [Content]
}

struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}

// Mistral and DeepSeek use the same format as OpenAI
typealias DeepSeekResponse = OpenAIResponse

typealias MistralResponse = OpenAIResponse

struct OpenAIModelListResponse: Codable {
    struct Model: Codable {
        let id: String
    }
    let data: [Model]
}

struct GeminiModelListResponse: Codable {
    struct Model: Codable {
        let name: String // e.g. "models/gemini-pro"
        let displayName: String?
    }
    let models: [Model]
}
