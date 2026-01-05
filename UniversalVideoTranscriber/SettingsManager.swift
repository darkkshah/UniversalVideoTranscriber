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

    private init() {
        // Load auto-download attempt status
        self.hasAttemptedAutoDownload = UserDefaults.standard.bool(forKey: "hasAttemptedAutoDownload")
    }
}
