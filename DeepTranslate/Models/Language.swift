//
//  Language.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import Foundation

struct Language: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let code: String
    let flag: String
    
    init(name: String, code: String, flag:String) {
        self.id = UUID()
        self.name = name
        self.code = code
        self.flag = flag
    }
    
    static let supportedLanguages: [Language] = [
        Language(name: "简体中文", code: "zh-CN", flag: "🇨🇳"),
        Language(name: "English", code: "en", flag: "🇺🇸"),
        Language(name: "日本語", code: "ja", flag: "🇯🇵"),
        Language(name: "Español", code: "es", flag: "🇪🇸"),
        Language(name: "Français", code: "fr", flag: "🇫🇷"),
        Language(name: "Deutsch", code: "de", flag: "🇩🇪"),
        Language(name: "Italiano", code: "it", flag: "🇮🇹"),
        Language(name: "한국어", code: "ko", flag: "🇰🇷"),
        Language(name: "Русский", code: "ru", flag: "🇷🇺"),
        Language(name: "Português", code: "pt", flag: "🇵🇹"),
        Language(name: "العربية", code: "ar", flag: "🇸🇦"),
        Language(name: "हिन्दी", code: "hi", flag: "🇮🇳"),
        Language(name: "Türkçe", code: "tr", flag: "🇹🇷"),
        Language(name: "Tiếng Việt", code: "vi", flag: "🇻🇳"),
        Language(name: "Nederlands", code: "nl", flag: "🇳🇱")
    ]
    
    static let auto = Language(name: "自动检测", code: "auto", flag: "✨")
}
