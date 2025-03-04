//
//  AppDelegate.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 应用启动逻辑
        return true
    }
    
    // 处理URL打开请求
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.scheme == "aitranslator", url.host == "translate" else {
            return false
        }
        
        // 解析URL参数
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        var textToTranslate: String?
        var sourceLanguage: String?
        var targetLanguage: String?
        
        if let queryItems = components?.queryItems {
            for item in queryItems {
                if item.name == "text" {
                    textToTranslate = item.value
                } else if item.name == "from" {
                    sourceLanguage = item.value
                } else if item.name == "to" {
                    targetLanguage = item.value
                }
            }
        }
        
        // 如果获取到必要参数，则处理翻译请求
        if let text = textToTranslate,
           let source = sourceLanguage,
           let target = targetLanguage {
            handleTranslationRequest(text: text, sourceLanguage: source, targetLanguage: target)
            return true
        }
        
        return false
    }
    
    // 处理翻译请求
    private func handleTranslationRequest(text: String, sourceLanguage: String, targetLanguage: String) {
        // 查找匹配的语言对象
        let sourceLanguageObj = findLanguageByCode(sourceLanguage)
        let targetLanguageObj = findLanguageByCode(targetLanguage)
        
        // 发送通知，使主应用可以接收这些数据
        NotificationCenter.default.post(
            name: Notification.Name("HandleTranslationRequest"),
            object: nil,
            userInfo: [
                "text": text,
                "sourceLanguage": sourceLanguageObj,
                "targetLanguage": targetLanguageObj
            ]
        )
    }
    
    // 根据语言代码查找对应的Language对象
    private func findLanguageByCode(_ code: String) -> Language {
        // 默认返回第一个语言（如果找不到匹配的）
        var result = Language.supportedLanguages[0]
        
        // 查找匹配的语言
        for language in Language.supportedLanguages {
            if language.code.lowercased() == code.lowercased() {
                result = language
                break
            }
        }
        
        return result
    }
}
