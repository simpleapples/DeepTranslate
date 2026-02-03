//
//  AboutView.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import SwiftUI

struct AboutView: View {
    let appVersion: String
    let buildNumber: String
    let developerEmail: String
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        // 尝试显示应用图标
                        if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                           let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
                           let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
                           let lastIcon = iconFiles.last {
                            Image(uiImage: UIImage(named: lastIcon) ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .cornerRadius(16)
                                .shadow(radius: 4)
                        } else {
                            Image(systemName: "translate") // Fallback icon
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("DeepTranslate")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("版本 \(appVersion) (\(buildNumber))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .listRowBackground(Color.clear)
            }
            
            Section(header: Text("联系与支持")) {
                Button(action: sendEmail) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text("反馈与建议")
                            .foregroundColor(.primary)
                    }
                }
                
                Text("如有任何问题或建议，请随时通过邮件联系我，我会尽快回复。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Text("© \(String(Calendar.current.component(.year, from: Date()))) DeepTranslate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("应用信息")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func sendEmail() {
        if let url = URL(string: "mailto:\(developerEmail)?subject=[反馈]DeepTranslate") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

#Preview {
    NavigationView {
        AboutView(appVersion: "1.0", buildNumber: "1", developerEmail: "test@example.com")
    }
}
