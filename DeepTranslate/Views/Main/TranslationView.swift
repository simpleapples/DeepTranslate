//
//  TranslationView.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct TranslationView: View {
    @EnvironmentObject private var translationService: TranslationService
    @EnvironmentObject private var appState: AppState
    
    // 文本和翻译状态
    @State private var sourceText = ""
    @State private var translatedText = ""
    
    @Binding var sourceLanguage: Language
    @Binding var targetLanguage: Language
    
    // UI 状态
    @State private var error: String?
    @State private var showingLanguageSelector = false
    @State private var selectingSource = true
    @State private var isEditing = false
    @State private var showingSettingsView = false
    @State private var showingHistoryView = false
    
    // 朗读源控制 - 跟踪哪个文本在朗读
    @State private var speakingSource = false // true = 源文本朗读, false = 目标文本朗读
    
    // 添加FocusState来管理输入框焦点
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // 语言选择区域
                    HStack(spacing: 0) {
                        // 源语言选择
                        Button(action: {
                            selectingSource = true
                            showingLanguageSelector = true
                        }) {
                            HStack {
                                Text(sourceLanguage.name)
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .lineLimit(1)           // 限制为单行
                                    .truncationMode(.tail)  // 文本过长时在尾部显示省略号
                                    .allowsTightening(true) // 允许字符间距微调以适应空间
                                
                                Image(systemName: "chevron.down")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.cardBackground)
                            .cornerRadius(12)
                        }
                        
                        // 语言交换按钮
                        Button(action: {
                            swapLanguages()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.cardBackground)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        
                        Button(action: {
                            selectingSource = false
                            showingLanguageSelector = true
                        }) {
                            HStack {
                                Text(targetLanguage.name)
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .lineLimit(1)           // 限制为单行
                                    .truncationMode(.tail)  // 文本过长时在尾部显示省略号
                                    .allowsTightening(true) // 允许字符间距微调以适应空间
                                
                                Image(systemName: "chevron.down")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.cardBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // 输入区域
                            VStack(spacing: 0) {
                                // 源语言标签
                                HStack {
                                    Text(sourceLanguage.name)
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                
                                // 输入框和占位符
                                // 输入区域 - 让光标可见但保持占位文本功能
                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $sourceText)
                                        .padding(.horizontal)
                                        .frame(height: 100)
                                        .background(Color.clear)
                                        .font(.system(size: 18))
                                        .focused($isInputFocused)
                                    
                                    if sourceText.isEmpty && !isInputFocused {
                                        Text("输入文本...")
                                            .foregroundColor(.gray)
                                            .padding(.horizontal)
                                            .padding(.top, 8)
                                            .allowsHitTesting(false) // 允许点击穿透到下层TextEditor
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                                    isInputFocused = true
                                }
                                
                                // 工具栏 - 不包含在可点击区域内
                                HStack(spacing: 20) {
                                    if !sourceText.isEmpty {
                                        Button(action: {
                                            clearSourceText()
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // 读取剪贴板按钮
                                    Button(action: {
                                        handleClipboardContent()
                                    }) {
                                        Image(systemName: "doc.on.clipboard")
                                            .font(.system(size: 18))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    // 朗读按钮 - 源文本
                                    Button(action: {
                                        if !sourceText.isEmpty {
                                            toggleSourceSpeaking()
                                        }
                                    }) {
                                        Image(systemName: translationService.isSpeaking && speakingSource ? "speaker.wave.2.fill" : "speaker.wave.2")
                                            .font(.system(size: 20))
                                            .foregroundColor(.blue)
                                    }
                                    .disabled(sourceText.isEmpty)
                                    .opacity(sourceText.isEmpty ? 0.5 : 1)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            
                            
                            // 翻译按钮
                            Button(action: {
                                translateText()
                            }) {
                                if translationService.isTranslating {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text("翻译中...")
                                            .font(.headline)
                                            .padding(.leading, 6)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                } else if !sourceText.isEmpty {
                                    Text("翻译")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .disabled(sourceText.isEmpty || translationService.isTranslating)
                            .padding(.horizontal)
                            
                            // 错误提示
                            if let error = error {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            
                            // 翻译结果区域
                            if !translatedText.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    // 目标语言标签
                                    HStack {
                                        Text(targetLanguage.name)
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal)
                                            .padding(.vertical, 10)
                                        
                                        Spacer()
                                    }
                                    
                                    Text(translatedText)
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .padding(.bottom, 10)
                                    
                                    // 工具栏
                                    HStack {
                                        Button(action: {
                                            UIPasteboard.general.string = translatedText
                                            let generator = UINotificationFeedbackGenerator()
                                            generator.notificationOccurred(.success)
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 20))
                                                .foregroundColor(.blue)
                                                .padding(10)
                                        }
                                        
                                        Spacer()
                                        
                                        // 朗读按钮 - 目标文本
                                        Button(action: {
                                            toggleTargetSpeaking()
                                        }) {
                                            Image(systemName: translationService.isSpeaking && !speakingSource ? "speaker.wave.2.fill" : "speaker.wave.2")
                                                .font(.system(size: 20))
                                                .foregroundColor(.blue)
                                                .padding(10)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .clipped()
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        hideKeyboard()
                        isEditing = false
                        isInputFocused = false
                    }
                }
            }
        }
        .onAppear {
            // 清理任务 - 暂时没有需要清理的任务，保留结构
        }
        .onDisappear {
            // 确保停止朗读
            if translationService.isSpeaking {
                translationService.stopSpeaking()
            }
        }
        // 使用 onReceive 自动管理通知及其生命周期
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("PerformTranslation"))) { notification in
            handleSharedTranslation(notification: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("PerformReadingClipboard"))) { _ in
            handleClipboardContent()
        }
        .sheet(isPresented: $showingLanguageSelector) {
            LanguageSelectorView(
                selectedLanguage: selectingSource ? $sourceLanguage : $targetLanguage,
                isSource: selectingSource
            )
        }
        .sheet(isPresented: $showingSettingsView) {
            SettingsView()
        }
        .sheet(isPresented: $showingHistoryView) {
            HistoryView()
        }
    }
    
    // MARK: - 朗读功能
    
    // 源文本朗读切换
    private func toggleSourceSpeaking() {
        if translationService.isSpeaking && speakingSource {
            // 如果源文本正在朗读，停止它
            translationService.stopSpeaking()
        } else {
            // 停止任何正在进行的朗读
            if translationService.isSpeaking {
                translationService.stopSpeaking()
            }
            // 开始朗读源文本并标记
            speakingSource = true
            translationService.speak(text: sourceText, language: sourceLanguage)
        }
    }
    
    // 目标文本朗读切换
    private func toggleTargetSpeaking() {
        if translationService.isSpeaking && !speakingSource {
            // 如果目标文本正在朗读，停止它
            translationService.stopSpeaking()
        } else {
            // 停止任何正在进行的朗读
            if translationService.isSpeaking {
                translationService.stopSpeaking()
            }
            // 开始朗读目标文本并标记
            speakingSource = false
            translationService.speak(text: translatedText, language: targetLanguage)
        }
    }
    
    
    // MARK: - 辅助方法
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 添加一个方法来处理文本编辑的开始
    private func activateInput() {
        // 使用延迟来避免可能的布局冲突
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInputFocused = true
            isEditing = true
        }
    }
    
    private func clearSourceText() {
        // 如果正在朗读，停止朗读
        if translationService.isSpeaking {
            translationService.stopSpeaking()
        }
        
        sourceText = ""
        translatedText = ""
        error = nil
    }
    
    private func swapLanguages() {
        // 如果正在朗读，停止朗读
        if translationService.isSpeaking {
            translationService.stopSpeaking()
        }
        
        // 如果源语言是Auto，不允许交换，或者交换后目标变成Auto（这应该被阻止）
        // 这里我们简单规定：如果源是Auto，交换时先把它变成默认语言或者不做操作？
        // 通常交换意味着 A -> B 变成 B -> A
        // 如果是 Auto -> B， 交换后变成 B -> Auto？目标语言通常不支持Auto
        // 所以如果源是Auto，我们可能需要先检测出语言再交换，或者提示用户
        
        if sourceLanguage.code == "auto" {
             // 如果当前是自动检测，尝试检测后再交换，或者不做任何事
             // 为了简单起见，如果是自动检测，暂时禁止交换，或者交换后源语言变为目标语言，目标语言变为检测到的（如果已翻译）
             // 让我们简单点：如果源是Auto，点击交换按钮时，如果已经有翻译结果且知道语言，就用那个。否则不做。
             return
        }
        
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
        
        if !translatedText.isEmpty {
            let tempText = sourceText
            sourceText = translatedText
            translatedText = tempText
        }
    }
    
    private func translateText() {
        // 隐藏键盘
        hideKeyboard()
        isInputFocused = false
        isEditing = false
        
        Task {
            do {
                // 确定实际的源语言
                var actualSourceLanguage = sourceLanguage
                
                // 如果是自动检测
                if sourceLanguage.code == "auto" {
                    if let code = LanguageDetectionService.detectLanguage(for: sourceText),
                       let detected = LanguageDetectionService.findLanguage(code: code) {
                        actualSourceLanguage = detected
                    } else {
                        // 降级策略：默认为英语
                        actualSourceLanguage = Language.supportedLanguages.first { $0.code == "en" } ?? sourceLanguage
                    }
                }
                
                // 确定实际的目标语言
                var actualTargetLanguage = targetLanguage
                
                if targetLanguage.code == "auto" {
                    // 获取系统语言代码 - 使用更兼容的方式
                    let systemLocale = Locale.current
                    let systemLangCode = systemLocale.languageCode ?? "en" // 使用languageCode属性，兼容性更好
                    
                    // 尝试匹配系统语言到我们需要支持的语言
                    let matchedSystemLang = Language.supportedLanguages.first { lang in
                        systemLangCode.lowercased().starts(with: lang.code.split(separator: "-")[0].lowercased())
                    } ?? Language.supportedLanguages.first { $0.code == "en" }!
                    
                    // 智能逻辑：
                    // 1. 如果源语言(实际) != 系统语言 -> 目标 = 系统语言
                    // 2. 如果源语言(实际) == 系统语言 -> 目标 = 英语 (作为通用Fallback)
                    
                    let sourceBase = actualSourceLanguage.code.split(separator: "-")[0].lowercased()
                    let systemBase = matchedSystemLang.code.split(separator: "-")[0].lowercased()
                    
                    if sourceBase != systemBase {
                        actualTargetLanguage = matchedSystemLang
                    } else {
                        // 如果源语言就是系统语言，则翻译成英文
                        actualTargetLanguage = Language.supportedLanguages.first { $0.code == "en" }!
                    }
                }
                
                // 防止源语言和目标语言完全相同
                // 确保我们不会传递 "auto" 给服务
                if actualSourceLanguage.code == "auto" {
                     actualSourceLanguage = Language.supportedLanguages.first { $0.code == "en" }!
                }
                
                if actualSourceLanguage.code == actualTargetLanguage.code {
                     // 冲突解决：如果目标是自动推导的，强制切换
                     if targetLanguage.code == "auto" {
                         if actualSourceLanguage.code.lowercased().starts(with: "en") {
                             actualTargetLanguage = Language.supportedLanguages.first { $0.code == "zh-CN" }!
                         } else {
                             actualTargetLanguage = Language.supportedLanguages.first { $0.code == "en" }!
                         }
                     }
                }
                
                let result = try await translationService.translate(
                    text: sourceText,
                    from: actualSourceLanguage,
                    to: actualTargetLanguage,
                    using: appState.activeProvider
                )
                
                translatedText = result
                
                // 添加到历史记录
                if !result.isEmpty {
                    let translation = TranslationResult(
                        sourceText: sourceText,
                        translatedText: result,
                        sourceLanguage: actualSourceLanguage,
                        targetLanguage: actualTargetLanguage,
                        provider: appState.activeProvider.name
                    )
                    appState.addToHistory(result: translation)
                }
                
                error = nil
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    private func handleSharedTranslation(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let text = userInfo["text"] as? String,
              let sourceLanguage = userInfo["sourceLanguage"] as? Language,
              let targetLanguage = userInfo["targetLanguage"] as? Language else {
            return
        }
        
        // 更新UI状态
        self.sourceText = text
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        
        // 触发翻译
        translateText()
    }
    
    // 添加处理剪贴板内容的方法
    private func handleClipboardContent() {
        // 请求访问剪贴板
        if let clipboardText = UIPasteboard.general.string, !clipboardText.isEmpty {
            // 更新源文本为剪贴板内容
            sourceText = clipboardText
            
            // 延迟一点时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 自动触发翻译
                translateText()
            }
        }
    }
}
