//
//  SettingsView.swift
//  UniversalVideoTranscriber
//
//  Tabbed settings interface: General (model management), Advanced (Whisper parameters), About
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var whisperService = WhisperService.shared
    @ObservedObject var downloadState = DownloadStateManager.shared
    @ObservedObject var settings = SettingsManager.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            TabView(selection: $selectedTab) {
                GeneralTabView(whisperService: whisperService, downloadState: downloadState)
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }
                    .tag(0)

                AdvancedTabView(settings: settings)
                    .tabItem {
                        Label("Advanced", systemImage: "slider.horizontal.3")
                    }
                    .tag(1)

                AboutTabView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
                    .tag(2)
            }
        }
        .frame(width: 600, height: 600)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
