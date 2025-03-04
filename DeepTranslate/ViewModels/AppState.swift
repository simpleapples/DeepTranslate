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
            saveProviders()
        }
    }
    
    @Published var selectedProviderIndex: Int {
        didSet {
            UserDefaults.standard.set(selectedProviderIndex, forKey: "selectedProviderIndex")
        }
    }
    
    @Published var translationHistory: [TranslationResult] = [] {
        didSet {
            saveHistory()
        }
    }
    
    // 添加自动语言检测设置
    @Published var autoDetectLanguage: Bool {
        didSet {
            UserDefaults.standard.set(autoDetectLanguage, forKey: "autoDetectLanguage")
        }
    }
    
    init() {
        // 从UserDefaults加载提供商配置
        if let savedData = UserDefaults.standard.data(forKey: "llmProviders"),
           let decodedProviders = try? JSONDecoder().decode([LLMProvider].self, from: savedData) {
            self.providers = decodedProviders
        } else {
            self.providers = LLMProvider.defaultProviders
        }
        
        // 加载选中的提供商索引
        self.selectedProviderIndex = UserDefaults.standard.integer(forKey: "selectedProviderIndex")
        
        // 确保索引有效
//        if self.selectedProviderIndex >= self.providers.count {
//            self.selectedProviderIndex = 0
//        }
        
        // 加载自动语言检测设置
        self.autoDetectLanguage = UserDefaults.standard.bool(forKey: "autoDetectLanguage", defaultValue: true)
        
        // 加载历史记录
        loadHistory()
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
    private func saveProviders() {
        if let encoded = try? JSONEncoder().encode(providers) {
            UserDefaults.standard.set(encoded, forKey: "llmProviders")
        }
    }
    
    // 添加翻译历史记录
    func addToHistory(result: TranslationResult) {
        translationHistory.insert(result, at: 0)
        // 限制历史记录数量
        if translationHistory.count > 100 {
            translationHistory.removeLast()
        }
        
        saveHistory()
    }
    
    // 清除历史记录
    func clearHistory() {
        translationHistory.removeAll()
        saveHistory()
    }
    
    // 保存历史记录
    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(translationHistory)
            UserDefaults.standard.set(data, forKey: "translationHistory")
        } catch {
            print("保存历史记录失败: \(error.localizedDescription)")
        }
    }
    
    // 加载历史记录
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "translationHistory") {
            do {
                let decoder = JSONDecoder()
                translationHistory = try decoder.decode([TranslationResult].self, from: data)
            } catch {
                print("加载历史记录失败: \(error.localizedDescription)")
            }
        }
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
