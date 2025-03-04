//
//  LangujageSelectorView.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct LanguageSelectorView: View {
    @Binding var selectedLanguage: Language
    let isSource: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    var filteredLanguages: [Language] {
        if searchText.isEmpty {
            return Language.supportedLanguages
        } else {
            return Language.supportedLanguages.filter { language in
                language.name.localizedCaseInsensitiveContains(searchText) ||
                language.code.localizedCaseInsensitiveContains(searchText) ||
                language.flag.contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("搜索语言", text: $searchText)
                        .font(.body)
                        .disableAutocorrection(true)
                    
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
                
                List {
                    ForEach(filteredLanguages) { language in
                        Button(action: {
                            selectedLanguage = language
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Text(language.flag)
                                    .font(.title2)
                                
                                Text(language.name)
                                    .font(.body)
                                
                                Spacer()
                                
                                if language.id == selectedLanguage.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.accent)
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(isSource ? "选择源语言" : "选择目标语言")
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
}

#Preview {
    LanguageSelectorView(
        selectedLanguage: .constant(Language.supportedLanguages[0]),
        isSource: true
    )
}
