//
//  FeatureRow.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.accent)
                .frame(width: 24)
            Text(text)
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        FeatureRow(icon: "globe", text: "支持多种语言翻译")
        FeatureRow(icon: "server.rack", text: "支持多种服务提供商")
        FeatureRow(icon: "mic", text: "语音输入支持")
    }
    .padding()
}
