//
//  HelpView.swift
//  UniversalVideoTranscriber
//
//  Comprehensive usage guide with getting started, features, shortcuts, and troubleshooting
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Help & Usage Guide")
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
                VStack(alignment: .leading, spacing: 32) {
                    // Getting Started Section
                    HelpSection(title: "Getting Started", icon: "play.circle.fill", color: .green) {
                        VStack(alignment: .leading, spacing: 16) {
                            HelpStep(number: 1, title: "Select a Video", description: "Click 'Select Video' or press Cmd+O to choose a video file from your Mac")
                            HelpStep(number: 2, title: "Choose Language", description: "Pick the language spoken in the video (or use Auto-Detect)")
                            HelpStep(number: 3, title: "Download Model (First Time)", description: "On first launch, the app will automatically download the Whisper Medium model (1.5 GB)")
                            HelpStep(number: 4, title: "Start Transcription", description: "Click 'Transcribe' and wait for the process to complete")
                            HelpStep(number: 5, title: "Export Results", description: "Once done, click 'Export Text' to save your transcription")
                        }
                    }

                    // Features Section
                    HelpSection(title: "Key Features", icon: "star.fill", color: .orange) {
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "lock.fill", title: "100% Offline", description: "All transcription happens locally on your Mac - no internet required after model download", color: .green)
                            FeatureRow(icon: "globe", title: "99 Languages", description: "Supports transcription in 99 languages with automatic language detection", color: .purple)
                            FeatureRow(icon: "waveform", title: "Whisper Medium Model", description: "Uses OpenAI's Whisper Medium model with ~94% accuracy (1.5 GB)", color: .blue)
                            FeatureRow(icon: "play.fill", title: "Video Playback", description: "Watch your video while reviewing the synchronized transcription", color: .red)
                            FeatureRow(icon: "magnifyingglass", title: "Search Transcripts", description: "Search through transcriptions with real-time highlighting", color: .cyan)
                            FeatureRow(icon: "slider.horizontal.3", title: "Advanced Tuning", description: "Adjust temperature, beam size, and noise suppression for optimal results", color: .pink)
                        }
                    }

                    // Keyboard Shortcuts Section
                    HelpSection(title: "Keyboard Shortcuts", icon: "command", color: .blue) {
                        VStack(spacing: 0) {
                            ShortcutRow(keys: "Cmd + O", action: "Select Video", showDivider: true)
                            ShortcutRow(keys: "Cmd + ,", action: "Open Settings", showDivider: true)
                            ShortcutRow(keys: "Cmd + ?", action: "Show Help", showDivider: true)
                            ShortcutRow(keys: "Cmd + Shift + E", action: "Export Text", showDivider: true)
                            ShortcutRow(keys: "Space", action: "Play/Pause Video", showDivider: false)
                        }
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }

                    // Advanced Whisper Settings Section
                    HelpSection(title: "Advanced Whisper Settings", icon: "gearshape.2.fill", color: .purple) {
                        VStack(alignment: .leading, spacing: 16) {
                            AdvancedSettingInfo(
                                title: "Temperature",
                                range: "0.0 - 1.0",
                                description: "Controls randomness in transcription. Lower values (0.0-0.3) produce more accurate, deterministic results. Higher values increase variability but may capture unclear speech better.",
                                recommendation: "Use 0.0 for accuracy, 0.5-0.8 if default misses words"
                            )

                            AdvancedSettingInfo(
                                title: "Suppress Non-Speech Tokens",
                                range: "On/Off",
                                description: "Filters out background music, noise, and non-verbal sounds from the transcription. Keeps only actual speech.",
                                recommendation: "Keep ON for clean transcripts, turn OFF if speech is being cut out"
                            )

                            AdvancedSettingInfo(
                                title: "Beam Size",
                                range: "1 - 8",
                                description: "Controls search width during decoding. Higher values (5-8) explore more possibilities and improve quality, but slow down transcription significantly.",
                                recommendation: "Use 5 (default) for balanced performance, 8 for maximum quality"
                            )
                        }
                    }

                    // Troubleshooting Section
                    HelpSection(title: "Troubleshooting", icon: "wrench.and.screwdriver.fill", color: .red) {
                        VStack(alignment: .leading, spacing: 16) {
                            TroubleshootItem(
                                problem: "Model not downloading",
                                solution: "Check your internet connection. The Whisper Medium model is 1.5 GB and may take time. If stuck, go to Settings > General and try re-downloading."
                            )

                            TroubleshootItem(
                                problem: "Transcription is inaccurate",
                                solution: "Try adjusting Advanced Settings: increase Beam Size to 8-10 for better quality, or adjust Temperature if speech is unclear. Ensure you've selected the correct language."
                            )

                            TroubleshootItem(
                                problem: "Transcription misses words",
                                solution: "Turn OFF 'Suppress Non-Speech Tokens' in Advanced Settings. This filter may be removing speech that sounds like noise."
                            )

                            TroubleshootItem(
                                problem: "App is slow/unresponsive",
                                solution: "Whisper transcription is CPU-intensive. Higher Beam Size values (8-10) significantly increase processing time. Try lowering Beam Size to 3-5 for faster results."
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 700, height: 700)
    }
}

// MARK: - Helper Views

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
            }

            content
        }
    }
}

struct HelpStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct ShortcutRow: View {
    let keys: String
    let action: String
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(keys)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 150, alignment: .leading)
                Text(action)
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if showDivider {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
}

struct AdvancedSettingInfo: View {
    let title: String
    let range: String
    let description: String
    let recommendation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text(range)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(4)
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)
                Text(recommendation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(6)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct TroubleshootItem: View {
    let problem: String
    let solution: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                Text(problem)
                    .font(.system(size: 14, weight: .semibold))
            }

            Text(solution)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    HelpView()
}
