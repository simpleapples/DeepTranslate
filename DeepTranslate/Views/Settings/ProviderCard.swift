//
//  ProviderCard.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct ProviderCard: View {
    let provider: LLMProvider
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.name)
                        .font(.headline)
                    
                    Text(provider.modelName)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                if isActive {
                    Button(action: {}) {
                        Text("当前使用")
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColors.accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(true)
                } else {
                    Button(action: onActivate) {
                        Text("启用")
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColors.accent.opacity(0.2))
                            .foregroundColor(AppColors.accent)
                            .cornerRadius(12)
                    }
                }
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppColors.accent)
                        .padding(8)
                        .background(AppColors.accent.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(isActive ? AppColors.cardBackground : AppColors.secondaryBackground)
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack {
        ProviderCard(
            provider: LLMProvider(
                name: "OpenAI",
                type: .openai,
                apiKey: "sk-1234",
                modelName: "gpt-4o",
                isActive: true
            ),
            isActive: true,
            onActivate: {},
            onEdit: {}
        )
        
        ProviderCard(
            provider: LLMProvider(
                name: "DeepSeek",
                type: .deepseek,
                apiKey: "sk-5678",
                modelName: "deepseek-chat",
                isActive: false
            ),
            isActive: false,
            onActivate: {},
            onEdit: {}
        )
    }
    .padding()
}
