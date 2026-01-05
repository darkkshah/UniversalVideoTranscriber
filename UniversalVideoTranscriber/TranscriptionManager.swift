//
//  TranscriptionManager.swift
//  UniversalVideoTranscriber
//
//  Manages audio extraction and Whisper transcription
//

import Foundation
import AVFoundation

@MainActor
class TranscriptionManager: ObservableObject {
    @Published var transcriptItems: [TranscriptItem] = []
    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0.0
    @Published var statusMessage = ""
    @Published var selectedLanguage: String = "auto" // Default to auto-detect

    private let whisperService = WhisperService.shared

    init() {
        // Simple initialization - Whisper only
        print("TranscriptionManager initialized with Whisper Medium model")
    }
    
    func transcribe(videoURL: URL) async throws -> [TranscriptItem] {
        // Whisper-only transcription
        // Reset progress to 0 at the start
        transcriptionProgress = 0.0
        isTranscribing = true
        transcriptItems = []
        statusMessage = "Preparing audio for Whisper..."

        // Start accessing security scoped resource
        let accessingResource = videoURL.startAccessingSecurityScopedResource()
        defer {
            if accessingResource {
                videoURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Extract audio from video
            let audioURL = try await extractAudio(from: videoURL)

            statusMessage = "Running Whisper..."

            // Use Whisper service with selected language and progress callback
            let items = try await whisperService.transcribe(
                audioURL: audioURL,
                language: selectedLanguage,
                onProgress: { [weak self] progress, message in
                    self?.transcriptionProgress = progress
                    self?.statusMessage = message
                }
            )

            transcriptItems = items

            // Clean up temporary audio file
            try? FileManager.default.removeItem(at: audioURL)

            isTranscribing = false
            return items

        } catch {
            isTranscribing = false
            transcriptionProgress = 0.0
            statusMessage = "Error: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Audio Extraction (Shared)

    private func extractAudio(from videoURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)

        // Check if audio track exists
        guard try await !asset.loadTracks(withMediaType: .audio).isEmpty else {
            throw TranscriptionError.noAudioTrack
        }
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw TranscriptionError.exportFailed
        }
        
        // Set output URL
        let tempDirectory = FileManager.default.temporaryDirectory
        let audioURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        
        exportSession.outputURL = audioURL
        exportSession.outputFileType = .m4a

        try await exportSession.export(to: audioURL, as: .m4a)

        return audioURL
    }
}

enum TranscriptionError: LocalizedError {
    case noAudioTrack
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .noAudioTrack:
            return "Video does not contain an audio track"
        case .exportFailed:
            return "Failed to extract audio from video"
        }
    }
}
