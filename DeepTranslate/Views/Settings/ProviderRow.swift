//
//  ProviderRow.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct ProviderRow: View {
    let provider: LLMProvider
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            // Selection Indicator (Radio Button style)
            Button(action: onActivate) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isActive ? AppColors.accent : .gray.opacity(0.5))
            }
            .buttonStyle(BorderlessButtonStyle()) // Prevent clicking row from triggering this
            
            VStack(alignment: .leading, spacing: 4) {
                Text(provider.name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(provider.modelName.isEmpty ? "未配置模型" : provider.modelName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Edit Button
            Button(action: onEdit) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(AppColors.accent)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ProviderRow(
            provider: LLMProvider(name: "OpenAI", type: .openai, apiKey: "sk-...", modelName: "gpt-4o", isActive: true),
            isActive: true,
            onActivate: {},
            onEdit: {}
        )
        ProviderRow(
            provider: LLMProvider(name: "DeepSeek", type: .deepseek, apiKey: "", modelName: "deepseek-chat", isActive: false),
            isActive: false,
            onActivate: {},
            onEdit: {}
        )
    }
}
