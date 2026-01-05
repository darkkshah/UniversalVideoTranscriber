//
//  SettingsManager.swift
//  UniversalVideoTranscriber
//
//  Manages app settings for Whisper transcription
//

import Foundation

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var hasAttemptedAutoDownload: Bool {
        didSet {
            UserDefaults.standard.set(hasAttemptedAutoDownload, forKey: "hasAttemptedAutoDownload")
        }
    }

    // Whisper Advanced Parameters
    @Published var whisperTemperature: Double {
        didSet {
            UserDefaults.standard.set(whisperTemperature, forKey: "whisperTemperature")
        }
    }

    @Published var whisperSuppressNonSpeech: Bool {
        didSet {
            UserDefaults.standard.set(whisperSuppressNonSpeech, forKey: "whisperSuppressNonSpeech")
        }
    }

    @Published var whisperBeamSize: Int {
        didSet {
            UserDefaults.standard.set(whisperBeamSize, forKey: "whisperBeamSize")
        }
    }

    private init() {
        // Load auto-download attempt status
        self.hasAttemptedAutoDownload = UserDefaults.standard.bool(forKey: "hasAttemptedAutoDownload")

        // Load Whisper advanced parameters with defaults
        self.whisperTemperature = UserDefaults.standard.object(forKey: "whisperTemperature") as? Double ?? 0.0
        self.whisperSuppressNonSpeech = UserDefaults.standard.object(forKey: "whisperSuppressNonSpeech") as? Bool ?? true
        self.whisperBeamSize = UserDefaults.standard.object(forKey: "whisperBeamSize") as? Int ?? 5
    }
}
