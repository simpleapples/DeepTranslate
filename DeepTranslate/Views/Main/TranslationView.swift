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
    @State private var sourceLanguage = Language.supportedLanguages[0]
    @State private var targetLanguage = Language.supportedLanguages[1]
    
    // UI 状态
    @State private var isRecording = false
    @State private var error: String?
    @State private var showingLanguageSelector = false
    @State private var selectingSource = true
    @State private var isEditing = false
    @State private var showingSettingsView = false
    @State private var showingHistoryView = false
    
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
                    // 标题与控制按钮
//                    HStack {
//                        Text("DeepTranslate")
//                            .font(.title)
//                            .fontWeight(.bold)
//                            .foregroundColor(AppColors.accent)
//                        Spacer()
//                    }
//                    .padding(.horizontal)
//                    .padding(.top)
                    
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
//                                    .foregroundColor(.white)
                                
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
                        
                        // 目标语言选择
                        Button(action: {
                            selectingSource = false
                            showingLanguageSelector = true
                        }) {
                            HStack {
                                Text(targetLanguage.name)
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
//                                    .foregroundColor(.white)
                                
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
//                    .padding(.top, 2)
                    
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
                                
                                ZStack(alignment: .topLeading) {
                                    if sourceText.isEmpty {
                                        Text("输入文本...")
                                            .padding(.horizontal)
                                            .padding(.top, 8)
                                    }
                                    
                                    TextEditor(text: $sourceText)
                                        .font(.system(size: 18))
                                        .background(Color.clear)
                                        .frame(minHeight: 100)
                                        .padding(.horizontal)
                                        .onChange(of: sourceText) { newValue in
                                            handleTextChange(newValue)
                                        }
                                        .onTapGesture {
                                            isEditing = true
                                        }
                                }
                                
                                // 工具栏
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
                                    
                                    // 语音输入按钮
                                    Button(action: {
                                        handleVoiceInput()
                                    }) {
                                        Image(systemName: isRecording ? "mic.fill" : "mic")
                                            .font(.system(size: 20))
                                            .foregroundColor(isRecording ? .red : .blue)
                                    }
                                    
                                    // 朗读按钮
                                    Button(action: {
                                        if !sourceText.isEmpty {
                                            toggleSpeaking(text: sourceText, language: sourceLanguage)
                                        }
                                    }) {
                                        Image(systemName: translationService.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
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
                                    
//                                    Button(action: {
//                                        showDetectedLanguage = false
//                                    }) {
//                                        Image(systemName: "xmark.circle.fill")
//                                            .foregroundColor(AppColors.cardBackground)
//                                    }
//                                    .padding(.leading, 8)
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
                                        
                                        Button(action: {
                                            toggleSpeaking(text: translatedText, language: targetLanguage)
                                        }) {
                                            Image(systemName: translationService.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
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
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            // 清理任何可能存在的文本变化任务
            textChangeTask?.cancel()
            textChangeTask = nil
            
            // 添加通知观察者
            NotificationCenter.default.addObserver(
                    forName: Notification.Name("PerformTranslation"),
                    object: nil,
                    queue: .main
                ) { notification in
                    // 不需要使用 [weak self]，因为 TranslationView 是结构体
                    handleSharedTranslation(notification: notification)
                }
        }
        .onDisappear {
            // 移除通知观察者
            NotificationCenter.default.removeObserver(self, name: Notification.Name("PerformTranslation"), object: nil)

            // 取消任何正在进行的任务
            textChangeTask?.cancel()
            textChangeTask = nil
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
//        .preferredColorScheme(.dark)
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
    
    private func clearSourceText() {
        sourceText = ""
        translatedText = ""
        error = nil
        showDetectedLanguage = false
        isDetecting = false
    }
    
    private func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
        
        if !translatedText.isEmpty {
            let tempText = sourceText
            sourceText = translatedText
            translatedText = tempText
        }
    }
    
    private func handleVoiceInput() {
        isRecording.toggle()
        if isRecording {
            Task {
                if let recognizedText = await translationService.startSpeechRecognition(language: sourceLanguage) {
                    sourceText = recognizedText
                    isRecording = false
                    
                    // 语音识别后尝试检测语言
                    if autoDetectLanguage && !recognizedText.isEmpty && recognizedText.count >= 5 {
                        handleTextChange(recognizedText)
                    }
                }
            }
        }
    }
    
    private func toggleSpeaking(text: String, language: Language) {
        if translationService.isSpeaking {
            translationService.stopSpeaking()
        } else {
            translationService.speak(text: text, language: language)
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
}

#Preview {
    TranslationView()
        .environmentObject(AppState())
        .environmentObject(TranslationService())
}
