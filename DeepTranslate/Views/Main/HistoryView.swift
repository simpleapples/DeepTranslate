//
//  HistoryView.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var translationService: TranslationService
    @State private var selectedResult: TranslationResult?
    @State private var searchText = ""
    
    var filteredHistory: [TranslationResult] {
        if searchText.isEmpty {
            return appState.translationHistory
        } else {
            return appState.translationHistory.filter { result in
                result.sourceText.localizedCaseInsensitiveContains(searchText) ||
                result.translatedText.localizedCaseInsensitiveContains(searchText) ||
                result.sourceLanguage.name.localizedCaseInsensitiveContains(searchText) ||
                result.targetLanguage.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if appState.translationHistory.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                            .padding()
                        
                        Text("尚无翻译历史记录")
                            .font(.title3)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("您的翻译记录将显示在此处")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 0) {
                        // 搜索栏
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.textSecondary)
                            
                            TextField("搜索历史记录", text: $searchText)
                                .font(.body)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        
                        if filteredHistory.isEmpty && !searchText.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                    .padding()
                                
                                Text("未找到匹配结果")
                                    .font(.title3)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(filteredHistory) { result in
                                    Button(action: {
                                        selectedResult = result
                                    }) {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack(alignment: .top) {
                                                Text(result.sourceLanguage.flag)
                                                    .font(.title3)
                                                    .padding(.trailing, 4)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(result.sourceText)
                                                        .font(.body)
                                                        .foregroundColor(AppColors.textPrimary)
                                                        .lineLimit(2)
                                                }
                                            }
                                            
                                            HStack(alignment: .top) {
                                                Text(result.targetLanguage.flag)
                                                    .font(.title3)
                                                    .padding(.trailing, 4)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(result.translatedText)
                                                        .font(.body)
                                                        .foregroundColor(AppColors.textSecondary)
                                                        .lineLimit(2)
                                                }
                                            }
                                            
                                            HStack(spacing: 12) {
                                                Text(formatDate(result.timestamp))
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                                
                                                Text("•")
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                                
                                                Text(result.provider)
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.accent)
                                            }
                                        }
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .onDelete { indexSet in
                                    deleteItems(at: indexSet)
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                }
            }
            .navigationTitle("翻译历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        appState.clearHistory()
                    }) {
                        Text("清除")
                            .foregroundColor(AppColors.accent)
                            .fontWeight(.medium)
                    }
                    .disabled(appState.translationHistory.isEmpty)
                }
            }
            .sheet(item: $selectedResult) { result in
                TranslationDetailView(result: result)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func deleteItems(at offsets: IndexSet) {
        // 创建一个临时数组来执行删除操作
        var tempHistory = appState.translationHistory
        tempHistory.remove(atOffsets: offsets)
        
        // 更新应用状态
        appState.translationHistory = tempHistory
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
        .environmentObject(TranslationService())
}
