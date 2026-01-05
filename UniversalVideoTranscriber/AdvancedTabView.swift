//
//  AdvancedTabView.swift
//  UniversalVideoTranscriber
//
//  Advanced Whisper parameter controls for quality/performance tuning
//

import SwiftUI

struct AdvancedTabView: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Advanced Whisper Parameters")
                        .font(.headline)
                    Text("Fine-tune transcription quality and performance. Changes apply to new transcriptions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Temperature Control
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "thermometer")
                            .foregroundColor(.orange)
                        Text("Temperature")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text(String(format: "%.1f", settings.whisperTemperature))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $settings.whisperTemperature, in: 0.0...1.0, step: 0.1)

                    HStack {
                        Text("Accurate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Creative")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("Lower values (0.0-0.3) produce more accurate, deterministic results. Higher values increase variability.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)

                // Suppress Non-Speech Toggle
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $settings.whisperSuppressNonSpeech) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Suppress Non-Speech Tokens")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Filter out background music, noise, and non-verbal sounds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .toggleStyle(.switch)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)

                // Beam Size Control
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.purple)
                        Text("Beam Size")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Stepper("\(settings.whisperBeamSize)", value: $settings.whisperBeamSize, in: 1...8)
                            .labelsHidden()
                            .frame(width: 100)
                        Text("\(settings.whisperBeamSize)")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                    }

                    HStack {
                        Text("Faster")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Higher Quality")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("Controls search width during decoding. Higher values (5-8) improve quality but slow down transcription.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)

                // Reset to Defaults Button
                Button(action: {
                    settings.whisperTemperature = 0.0
                    settings.whisperSuppressNonSpeech = true
                    settings.whisperBeamSize = 5
                }) {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}

#Preview {
    AdvancedTabView(settings: SettingsManager.shared)
}
