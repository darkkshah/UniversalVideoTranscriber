//
//  SettingsView.swift
//  UniversalVideoTranscriber
//
//  Settings panel for Whisper model management
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var whisperService = WhisperService.shared
    @ObservedObject var downloadState = DownloadStateManager.shared

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

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Whisper Model Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Whisper Transcription")
                            .font(.headline)

                        HStack {
                            Image(systemName: "waveform")
                                .font(.system(size: 32))
                                .foregroundColor(.purple)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Whisper Medium")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("1.5 GB • ~94% accuracy")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if whisperService.isModelDownloaded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 24))
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 24))
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)

                        // Model status and actions
                        if whisperService.isModelDownloaded {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Model downloaded and ready")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Button(action: {
                                Task {
                                    do {
                                        try whisperService.deleteMediumModel()
                                        try await whisperService.downloadMediumModel()
                                    } catch {
                                        print("Re-download failed: \(error)")
                                    }
                                }
                            }) {
                                Label("Re-download Model", systemImage: "arrow.clockwise")
                            }
                            .disabled(downloadState.isDownloading)

                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Model not downloaded")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Button(action: {
                                Task {
                                    do {
                                        try await whisperService.downloadMediumModel()
                                    } catch {
                                        print("Download failed: \(error)")
                                    }
                                }
                            }) {
                                Label("Download Model (\(WhisperService.mediumModelSize))", systemImage: "arrow.down.circle")
                            }
                            .disabled(downloadState.isDownloading)
                            .buttonStyle(.borderedProminent)
                        }

                        // Download progress
                        if downloadState.isDownloading {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .controlSize(.small)
                                    Text(downloadState.statusMessage)
                                        .font(.caption)
                                }

                                ProgressView(value: downloadState.downloadProgress)
                                    .progressViewStyle(.linear)

                                Text("\(Int(downloadState.downloadProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Download error
                        if let error = downloadState.downloadError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)

                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Whisper")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(icon: "lock.fill", text: "Runs entirely offline - no internet required for transcription", color: .green)
                            InfoRow(icon: "arrow.down.circle.fill", text: "Initial model download: 1.5 GB (one-time, automatic)", color: .blue)
                            InfoRow(icon: "globe", text: "Supports 99 languages with auto-detection", color: .purple)
                            InfoRow(icon: "folder.fill", text: "Models stored in Application Support folder", color: .gray)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
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
