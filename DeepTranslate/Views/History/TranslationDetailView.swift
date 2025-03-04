//
//  TranslationDetailView.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct TranslationDetailView: View {
    let result: TranslationResult
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var translationService: TranslationService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 源语言
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            Text(result.sourceLanguage.flag)
                                .font(.title)
                            
                            Text(result.sourceLanguage.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = result.sourceText
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppColors.accent)
                            }
                            
                            Button(action: {
                                translationService.speak(text: result.sourceText, language: result.sourceLanguage)
                            }) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                        .padding(.horizontal)
                        
                        Text(result.sourceText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // 分隔符
                    HStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(AppColors.accent)
                        
                        Text(result.provider)
                            .font(.subheadline)
                            .foregroundColor(AppColors.accent)
                    }
                    
                    // 目标语言
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            Text(result.targetLanguage.flag)
                                .font(.title)
                            
                            Text(result.targetLanguage.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = result.translatedText
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppColors.accent)
                            }
                            
                            Button(action: {
                                translationService.speak(text: result.translatedText, language: result.targetLanguage)
                            }) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                        .padding(.horizontal)
                        
                        Text(result.translatedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // 翻译时间
                    Text("翻译于 \(formatFullDate(result.timestamp))")
                        .font(.footnote)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top)
                }
                .padding(.vertical)
            }
            .navigationTitle("翻译详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    TranslationDetailView(
        result: TranslationResult(
            sourceText: "Hello, how are you?",
            translatedText: "你好，你怎么样？",
            sourceLanguage: Language.supportedLanguages[1],
            targetLanguage: Language.supportedLanguages[0],
            provider: "OpenAI"
        )
    )
    .environmentObject(TranslationService())
}
