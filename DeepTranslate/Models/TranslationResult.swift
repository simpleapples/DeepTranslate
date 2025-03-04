//
//  TranslationResult.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import Foundation

struct TranslationResult: Identifiable, Codable {
    let id: UUID
    let sourceText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let provider: String
    let timestamp: Date
    
    init(sourceText: String, translatedText: String, sourceLanguage: Language, targetLanguage: Language, provider: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.provider = provider
        self.timestamp = timestamp
    }
}
