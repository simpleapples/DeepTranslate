//
//  WidgetExtensionBundle.swift
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
    func placeholder(in context: Context) -> TranslateWidgetEntry {
        TranslateWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (TranslateWidgetEntry) -> ()) {
        let entry = TranslateWidgetEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TranslateWidgetEntry>) -> ()) {
        let entry = TranslateWidgetEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Widget条目
struct TranslateWidgetEntry: TimelineEntry {
    let date: Date
}


// MARK: - Widget视图
struct TranslateWidgetEntryView: View {
    var entry: TranslateWidgetProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // 背景色 - 使用Google翻译相似的背景色
//            Color(UIColor.systemBackground)
//                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 输入框区域和按钮一行
                HStack(spacing: 8) {
                    // 输入框（包含语言选择）
                    Link(destination: URL(string: "translateapp://open")!) {
                        HStack(spacing: 4) {
                            // 翻译图标
                            Image(systemName: "character.book.closed")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                                .frame(width: 30, height: 30)
                                
                            
                            // 语言选择
                            HStack(spacing: 4) {
                                Text("中文")
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                
                                Text("英文")
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
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
                    Link(destination: URL(string: "translateapp://paste")!) {
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
                        Link(destination: URL(string: "translateapp://history")!) {
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
                        Link(destination: URL(string: "translateapp://settings")!) {
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
        .configurationDisplayName("翻译小工具")
        .description("快速翻译文本和剪贴板内容")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 预览
struct TranslateWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TranslateWidgetEntryView(entry: TranslateWidgetEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .light)
            
            TranslateWidgetEntryView(entry: TranslateWidgetEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.colorScheme, .light)
            
            TranslateWidgetEntryView(entry: TranslateWidgetEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.colorScheme, .dark)
        }
    }
}
