//
//  AboutTabView.swift
//  UniversalVideoTranscriber
//
//  About section with version info, credits, and copyright
//

import SwiftUI

struct AboutTabView: View {
    // Read version info from Bundle
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon and Name
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Universal Video Transcriber")
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    Text("Version \(appVersion) (Build \(buildNumber))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                Divider()

                // Copyright
                VStack(spacing: 8) {
                    Text("© 2026 mpcode")
                        .font(.system(size: 13, weight: .medium))

                    Text("All Rights Reserved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Credits
                VStack(alignment: .leading, spacing: 16) {
                    Text("Credits")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        CreditRow(
                            title: "Whisper",
                            subtitle: "OpenAI's open-source speech recognition model",
                            link: "https://github.com/openai/whisper"
                        )

                        CreditRow(
                            title: "whisper.cpp",
                            subtitle: "High-performance C/C++ port by Georgi Gerganov",
                            link: "https://github.com/ggerganov/whisper.cpp"
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)

                // License Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("License Information")
                        .font(.headline)

                    Text("This application uses the Whisper model (MIT License) and whisper.cpp (MIT License). See respective repositories for full license terms.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)

                Spacer()
            }
            .padding()
        }
    }
}

struct CreditRow: View {
    let title: String
    let subtitle: String
    let link: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            Link(link, destination: URL(string: link)!)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(6)
    }
}

#Preview {
    AboutTabView()
}
