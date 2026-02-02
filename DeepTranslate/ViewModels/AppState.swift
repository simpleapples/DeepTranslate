//
//  AppState.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import Foundation
import Combine

class AppState: ObservableObject {
    @Published var providers: [LLMProvider] {
        didSet {
            saveProviders(providers)
        }
    }
    
    @Published var selectedTab: Int = 0
    
    @Published var selectedProviderIndex: Int {
        didSet {
            let index = selectedProviderIndex
            DispatchQueue.global(qos: .background).async {
                let defaults = UserDefaults(suiteName: "group.simpleapples.deeptranslate")
                if let defaults = defaults {
                    defaults.set(index, forKey: "selectedProviderIndex")
                }
            }
        }
    }
    
    @Published var sourceLanguage: Language {
        didSet {
            let language = sourceLanguage
            DispatchQueue.global(qos: .background).async {
                if let encoded = try? JSONEncoder().encode(language) {
                    let defaults = UserDefaults(suiteName: "group.simpleapples.deeptranslate")
                    if let defaults = defaults {
                        defaults.set(encoded, forKey: "sourceLanguage")
                    }
                }
            }
        }
    }
    
    @Published var targetLanguage: Language {
        didSet {
            let language = targetLanguage
            DispatchQueue.global(qos: .background).async {
                if let encoded = try? JSONEncoder().encode(language) {
                    let defaults = UserDefaults(suiteName: "group.simpleapples.deeptranslate")
                    if let defaults = defaults {
                        defaults.set(encoded, forKey: "targetLanguage")
                    }
                }
            }
        }
    }
    
    @Published var translationHistory: [TranslationResult] = [] {
        didSet {
            saveHistory(translationHistory)
        }
    }
    
    // 添加自动语言检测设置
    @Published var autoDetectLanguage: Bool {
        didSet {
            let value = autoDetectLanguage
            DispatchQueue.global(qos: .background).async {
                let defaults = UserDefaults(suiteName: "group.simpleapples.deeptranslate")
                if let defaults = defaults {
                    defaults.set(value, forKey: "autoDetectLanguage")
                }
            }
        }
    }
    
    init() {
        let defaults = UserDefaults(suiteName: "group.simpleapples.deeptranslate")
        if let defaults = defaults {
            // 从UserDefaults加载提供商配置
            if let savedData = defaults.data(forKey: "llmProviders"),
               let decodedProviders = try? JSONDecoder().decode([LLMProvider].self, from: savedData) {
                self.providers = decodedProviders
            } else {
                self.providers = LLMProvider.defaultProviders
            }
            
            // 从UserDefaults加载源语言
            if let savedData = defaults.data(forKey: "sourceLanguage"),
               let decodedLanguage = try? JSONDecoder().decode(Language.self, from: savedData) {
                self.sourceLanguage = decodedLanguage
            } else {
                self.sourceLanguage = Language.supportedLanguages[0]
            }
            
            // 从UserDefaults加载目标语言
            if let savedData = defaults.data(forKey: "targetLanguage"),
               let decodedLanguage = try? JSONDecoder().decode(Language.self, from: savedData) {
                self.targetLanguage = decodedLanguage
            } else {
                self.targetLanguage = Language.supportedLanguages[1]
            }
            
            // 加载选中的提供商索引
            self.selectedProviderIndex = defaults.integer(forKey: "selectedProviderIndex")
            
            // 加载自动语言检测设置
            self.autoDetectLanguage = defaults.bool(forKey: "autoDetectLanguage", defaultValue: true)
            
            // 加载历史记录
            if let data = defaults.data(forKey: "translationHistory") {
                do {
                    let decoder = JSONDecoder()
                    translationHistory = try decoder.decode([TranslationResult].self, from: data)
                } catch {
                    print("加载历史记录失败: \(error.localizedDescription)")
                }
            }
        } else {
            self.providers = LLMProvider.defaultProviders
            self.selectedProviderIndex = 0
            self.autoDetectLanguage = true
            self.sourceLanguage = Language.supportedLanguages[0]
            self.targetLanguage = Language.supportedLanguages[1]
        }
    }
    
    // 获取共享 UserDefaults
    public func getSharedUserDefaults() -> UserDefaults {
        return UserDefaults(suiteName: "group.simpleapples.deeptranslate") ?? .standard
    }
    
    // 获取当前活跃的提供商
    var activeProvider: LLMProvider {
        if selectedProviderIndex < providers.count {
            return providers[selectedProviderIndex]
        }
        return providers[0]
    }
    
    // 更新提供商配置
    func updateProvider(_ provider: LLMProvider) {
        if let index = providers.firstIndex(where: { $0.id == provider.id }) {
            providers[index] = provider
        }
    }
    
    // 添加新提供商
    func addProvider(_ provider: LLMProvider) {
        providers.append(provider)
    }
    
    // 删除提供商
    func removeProvider(at index: Int) {
        guard index < providers.count else { return }
        providers.remove(at: index)
        
        // 如果删除了选中的提供商，需要更新selectedProviderIndex
        if index == selectedProviderIndex {
            selectedProviderIndex = 0
        } else if index < selectedProviderIndex {
            selectedProviderIndex -= 1
        }
    }
    
    // 设置提供商为活跃
    func setProviderActive(at index: Int) {
        selectedProviderIndex = index
    }
    
    // 保存提供商配置到UserDefaults
    private func saveProviders(_ providers: [LLMProvider]) {
        DispatchQueue.global(qos: .background).async {
            if let encoded = try? JSONEncoder().encode(providers) {
                let defaults = UserDefaults(suiteName: "group.simpleapples.deeptranslate")
                if let defaults = defaults {
                    defaults.set(encoded, forKey: "llmProviders")
                }
            }
        }
    }
    
    // 添加翻译历史记录
    func addToHistory(result: TranslationResult) {
        translationHistory.insert(result, at: 0)
        // 限制历史记录数量
        if translationHistory.count > 100 {
            translationHistory.removeLast()
        }
        
        saveHistory(translationHistory)
    }
    
    // 清除历史记录
    func clearHistory() {
        translationHistory.removeAll()
        saveHistory(translationHistory)
    }
    
    // 保存历史记录
    private func saveHistory(_ history: [TranslationResult]) {
        DispatchQueue.global(qos: .background).async {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(history)
                let defaults = UserDefaults(suiteName: "group.simpleapples.deeptranslate")
                if let defaults = defaults {
                    defaults.set(data, forKey: "translationHistory")
                }
            } catch {
                print("保存历史记录失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 加载历史记录
    private func loadHistory() {
        
    }
}

// 为 UserDefaults 添加扩展，提供具有默认值的 bool 方法
extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            set(defaultValue, forKey: key)
            return defaultValue
        }
        return bool(forKey: key)
    }
}
