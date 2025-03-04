//
//  AppColors.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct AppColors {
    static let accent = Color.blue
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let background = Color(.systemGray6).opacity(0.8)
    static let secondaryBackground = Color(.systemGray6)
    static let inputBackground = Color(.systemGray6).opacity(0.8)
    static let cardBackground = Color(.systemBackground)
    static let divider = Color.gray.opacity(0.2)
    
    // 获取主题色的不同色调
    static func accentShade(_ opacity: Double = 1.0) -> Color {
        return accent.opacity(opacity)
    }
}
