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
    
    // 语言检测相关
    @State private var detectedLanguage: Language? = nil
    @State private var showDetectedLanguage = false
    @State private var isDetecting = false
    @AppStorage("autoDetectLanguage") private var autoDetectLanguage = true
    
    // 异步任务跟踪
    @State private var textChangeTask: Task<Void, Never>? = nil
    
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
                                // 源语言标签与检测状态
                                HStack {
                                    Text(sourceLanguage.name)
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    if isDetecting && autoDetectLanguage {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                                            .scaleEffect(0.7)
                                            .padding(.leading, 4)
                                    }
                                    Spacer()
                                    
                                    if autoDetectLanguage {
                                        
                                        Text("自动检测已开启")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
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
                                        .onChange(of: sourceText) { newValue in
                                            handleTextChange(newValue)
                                        }
                                    
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
                                    
                                    // 自动检测开关
                                    Button(action: {
                                        autoDetectLanguage.toggle()
                                        if !autoDetectLanguage {
                                            showDetectedLanguage = false
                                            isDetecting = false
                                        } else if !sourceText.isEmpty && sourceText.count >= 5 {
                                            handleTextChange(sourceText)
                                        }
                                    }) {
                                        Image(systemName: autoDetectLanguage ? "text.magnifyingglass" : "slash.circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(autoDetectLanguage ? .blue : .gray)
                                    }
                                    
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
                            
                            // 语言检测提示
                            if showDetectedLanguage, let detected = detectedLanguage {
                                HStack {
                                    Image(systemName: "text.magnifyingglass")
                                        .foregroundColor(.blue)
                                        .padding(.trailing, 4)
                                    
                                    Text("检测到语言：\(detected.name)")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        applyDetectedLanguage()
                                    }) {
                                        Text("应用")
                                            .font(.subheadline)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 4)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .animation(.easeInOut(duration: 0.2), value: showDetectedLanguage)
                                .transition(.opacity)
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
            // 清理任何可能存在的文本变化任务
            textChangeTask?.cancel()
            textChangeTask = nil
        }
        .onDisappear {
            // 取消任何正在进行的任务
            textChangeTask?.cancel()
            textChangeTask = nil
            
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
    
    // MARK: - 文本变化处理
    
    private func handleTextChange(_ newText: String) {
        // 取消之前的任务
        textChangeTask?.cancel()
        textChangeTask = nil
        
        // 如果自动检测关闭或文本太短，则不进行检测
        if !autoDetectLanguage || newText.count < 5 {
            isDetecting = false
            showDetectedLanguage = false
            return
        }
        
        // 设置正在检测状态
        isDetecting = true
        
        // 创建新任务
        textChangeTask = Task {
            do {
                // 防抖：等待800毫秒
                try await Task.sleep(nanoseconds: 800_000_000)
                
                // 检查任务是否被取消
                try Task.checkCancellation()
                
                // 执行语言检测
                await detectLanguage(for: newText)
                
                // 检测完成后更新状态
                await MainActor.run {
                    isDetecting = false
                }
            } catch {
                // 任务被取消或出错
                await MainActor.run {
                    isDetecting = false
                }
            }
        }
    }
    
    // MARK: - 语言检测
    
    private func detectLanguage(for text: String) async {
        guard !text.isEmpty, text.count >= 5, autoDetectLanguage else {
            await MainActor.run {
                showDetectedLanguage = false
            }
            return
        }
        
        // 在分离的任务中进行检测，避免阻塞UI
        let detectedInfo = await Task.detached(priority: .userInitiated) { () -> (Language?, Bool) in
            if let detectedCode = LanguageDetectionService.detectLanguage(for: text),
               let detected = LanguageDetectionService.findLanguage(code: detectedCode) {
                return (detected, true)
            }
            return (nil, false)
        }.value
        
        // 在主线程更新UI
        await MainActor.run {
            if let detected = detectedInfo.0, detectedInfo.1 {
                // 只有当检测到的语言与当前选择的不同时才显示提示
                if detected.id != sourceLanguage.id {
                    detectedLanguage = detected
                    showDetectedLanguage = true
                } else {
                    showDetectedLanguage = false
                }
            } else {
                showDetectedLanguage = false
            }
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
        showDetectedLanguage = false
        isDetecting = false
    }
    
    private func swapLanguages() {
        // 如果正在朗读，停止朗读
        if translationService.isSpeaking {
            translationService.stopSpeaking()
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
    
    private func applyDetectedLanguage() {
        guard let detected = detectedLanguage, detected.id != sourceLanguage.id else {
            return
        }
        
        // 如果目标语言与检测到的语言相同，则自动交换
        if detected.id == targetLanguage.id {
            swapLanguages()
        } else {
            sourceLanguage = detected
        }
        
        showDetectedLanguage = false
    }
    
    private func translateText() {
        // 隐藏键盘
        hideKeyboard()
        isInputFocused = false
        isEditing = false
        
        // 在翻译前检测语言并应用
        if autoDetectLanguage && !sourceText.isEmpty && showDetectedLanguage {
            applyDetectedLanguage()
        }
        
        Task {
            do {
                let result = try await translationService.translate(
                    text: sourceText,
                    from: sourceLanguage,
                    to: targetLanguage,
                    using: appState.activeProvider
                )
                
                translatedText = result
                
                // 添加到历史记录
                if !result.isEmpty {
                    let translation = TranslationResult(
                        sourceText: sourceText,
                        translatedText: result,
                        sourceLanguage: sourceLanguage,
                        targetLanguage: targetLanguage,
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
            
            // 如果开启了自动检测功能，触发文本变化处理
            if autoDetectLanguage && clipboardText.count >= 5 {
                handleTextChange(clipboardText)
            }
            
            // 延迟一点时间以便可能的语言检测完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // 自动触发翻译
                translateText()
            }
        }
    }
}
