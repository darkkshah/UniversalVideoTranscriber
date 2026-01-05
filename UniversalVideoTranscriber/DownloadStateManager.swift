//
//  DownloadStateManager.swift
//  UniversalVideoTranscriber
//
//  Global singleton to track Whisper model download state across all views
//

import Foundation

@MainActor
class DownloadStateManager: ObservableObject {
    static let shared = DownloadStateManager()

    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadError: String?
    @Published var statusMessage: String = ""

    private init() {}

    func startDownload() {
        isDownloading = true
        downloadProgress = 0.0
        downloadError = nil
        statusMessage = "Starting download of Whisper Medium model..."
    }

    func updateProgress(_ progress: Double, message: String) {
        downloadProgress = progress
        statusMessage = message
    }

    func completeDownload() {
        isDownloading = false
        downloadProgress = 1.0
        statusMessage = "Whisper Medium model downloaded successfully"
    }

    func failDownload(error: String) {
        isDownloading = false
        downloadError = error
        statusMessage = "Download failed: \(error)"
    }

    func resetState() {
        isDownloading = false
        downloadProgress = 0.0
        downloadError = nil
        statusMessage = ""
    }
}
