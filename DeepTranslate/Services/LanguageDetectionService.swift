//
//  LanguageDetectionService.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import Foundation
import NaturalLanguage

class LanguageDetectionService {
    static func detectLanguage(for text: String) -> String? {
        guard !text.isEmpty else { return nil }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        // 获取可能性最高的语言代码
        guard let languageCode = recognizer.dominantLanguage?.rawValue else {
            return nil
        }
        
        return languageCode
    }
    
    static func findLanguage(code: String) -> Language? {
        return Language.supportedLanguages.first {
            $0.code.hasPrefix(code) || code.hasPrefix($0.code)
        }
    }
    
    static func getReadableLanguageName(for code: String) -> String {
        if let language = findLanguage(code: code) {
            return language.name
        } else {
            // 如果没有找到匹配的语言，返回语言代码
            let locale = Locale(identifier: "zh-CN")
            if let displayName = locale.localizedString(forLanguageCode: code) {
                return displayName
            }
            return code
        }
    }
}
