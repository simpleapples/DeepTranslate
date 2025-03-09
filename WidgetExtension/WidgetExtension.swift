//
//  WidgetExtension.swift
//  WidgetExtension
//
//  Created by Zzy on 04/03/2025.
//


import WidgetKit
import SwiftUI
import Intents


// MARK: - Widget入口点
@main
struct WidgetExtension: WidgetBundle {
    var body: some Widget {
        TranslateWidget()
    }
}

// MARK: - Widget提供者
struct TranslateWidgetProvider: TimelineProvider {
    // 创建共享的UserDefaults
    let sharedUserDefaults = UserDefaults(suiteName: "group.simpleapples.deeptranslate")
    
    // 默认语言
    let defaultSourceLanguage = Language.supportedLanguages[0]
    let defaultTargetLanguage = Language.supportedLanguages[1]
    
    func placeholder(in context: Context) -> TranslateWidgetEntry {
        // 使用默认值
        TranslateWidgetEntry(
            date: Date(),
            sourceLanguage: defaultSourceLanguage,
            targetLanguage: defaultTargetLanguage
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TranslateWidgetEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TranslateWidgetEntry>) -> ()) {
        let entry = getEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // 从App Group的UserDefaults中读取语言设置
    private func getEntry() -> TranslateWidgetEntry {
        var sourceLanguage = defaultSourceLanguage
        var targetLanguage = defaultTargetLanguage
        
        // 从UserDefaults读取数据并解码
        if let sourceData = sharedUserDefaults?.data(forKey: "sourceLanguage") {
            do {
                let decodedSource = try JSONDecoder().decode(Language.self, from: sourceData)
                sourceLanguage = decodedSource
            } catch {
                print("Error decoding sourceLanguage: \(error)")
            }
        }
        
        if let targetData = sharedUserDefaults?.data(forKey: "targetLanguage") {
            do {
                let decodedTarget = try JSONDecoder().decode(Language.self, from: targetData)
                targetLanguage = decodedTarget
            } catch {
                print("Error decoding targetLanguage: \(error)")
            }
        }
        
        return TranslateWidgetEntry(
            date: Date(),
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
    }
}

// MARK: - Widget条目
struct TranslateWidgetEntry: TimelineEntry {
    let date: Date
    let sourceLanguage: Language
    let targetLanguage: Language
}


// MARK: - Widget视图
struct TranslateWidgetEntryView: View {
    var entry: TranslateWidgetProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 输入框区域和按钮一行
                HStack(spacing: 8) {
                    // 输入框（包含语言选择）
                    Link(destination: URL(string: "deeptranslate://open")!) {
                        HStack(spacing: 4) {
                            // 翻译图标
                            Image(systemName: "globe")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                                .frame(width: 30, height: 30)
                                
                            // 语言选择 - 使用从UserDefaults读取的Language对象
                            HStack(spacing: 4) {
                                // 源语言显示
                                HStack(spacing: 2) {
                                    Text(entry.sourceLanguage.name)
                                        .font(.subheadline)
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                }
                                
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                
                                // 目标语言显示
                                HStack(spacing: 2) {
                                    Text(entry.targetLanguage.name)
                                        .font(.subheadline)
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                }
                            }
                            
                            Spacer()
                        }
                        .frame(height: 50)
                        .padding(.horizontal, 12)
                        .background(Color(UIColor.white))
                        .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 0)
                    }
                    
                    // 剪贴板按钮
                    Link(destination: URL(string: "deeptranslate://paste")!) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 18))
                            .foregroundColor(Color(UIColor.gray))
                            .frame(width: 50, height: 50)
                            .background(Color(UIColor.white))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 0)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
                
                // 底部功能按钮 - 历史和设置
                if widgetFamily != .systemSmall {
                    HStack(spacing: 6) {
                        // 历史按钮
                        Link(destination: URL(string: "deeptranslate://history")!) {
                            VStack(spacing: 6) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                Text("历史")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 138, height: 30, alignment: .center)
                            .padding(.vertical, 16)
                            .background(Color(UIColor.white))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 0)
                        }
                        
                        Spacer()
                        
                        // 设置按钮
                        Link(destination: URL(string: "deeptranslate://settings")!) {
                            VStack(spacing: 6) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                Text("设置")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 138, height: 30, alignment: .center)                            .padding(.vertical, 16)
                            .background(Color(UIColor.white))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 0)
                        }
                        
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .containerBackground(.gray.gradient.opacity(0.1), for: .widget)
    }
        
}

// MARK: - Widget配置
struct TranslateWidget: Widget {
    let kind: String = "WidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TranslateWidgetProvider()) { entry in
            TranslateWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("DeepTranslate")
        .description("快速翻译文本")
        .supportedFamilies([.systemMedium])
    }
}
