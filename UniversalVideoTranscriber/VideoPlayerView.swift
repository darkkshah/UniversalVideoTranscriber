//
//  VideoPlayerView.swift
//  UniversalVideoTranscriber
//
//  Video player with AVKit and timestamp jumping capability
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let videoURL: URL?
    @Binding var currentTime: TimeInterval
    let showSubtitles: Bool
    let transcriptItems: [TranscriptItem]
    @State private var player: AVPlayer?
    @State private var timeObserver: Any?
    @State private var currentVideoURL: URL?  // Track current video to detect changes

    var body: some View {
        Group {
            if videoURL != nil, let player = player {
                ZStack {
                    VideoPlayer(player: player)
                        .id(videoURL?.absoluteString ?? "")
                        .onAppear {
                            setupTimeObserver()
                        }
                        .onDisappear {
                            cleanupPlayer()
                        }

                    // Invisible overlay for tap gesture (click-to-pause/play)
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            togglePlayPause()
                        }

                    // Subtitle overlay
                    if showSubtitles, let subtitle = getCurrentSubtitle() {
                        VStack {
                            Spacer()

                            Text(subtitle.text)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.75))
                                )
                                .padding(.bottom, 40)
                                .padding(.horizontal, 40)
                                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                        }
                        .allowsHitTesting(false)  // Allow clicks to pass through to video
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    Text("No video selected")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("Select a video file to begin")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
        .onChange(of: videoURL) { oldValue, newValue in
            // Always reload when videoURL changes, even if it's the same URL
            if let url = newValue, url != currentVideoURL {
                print("🎬 [VIDEO] Loading new video: \(url.lastPathComponent)")
                currentVideoURL = url
                loadVideo(url: url)
            } else if newValue == nil {
                // Clean up player when video is unloaded
                print("🎬 [VIDEO] Cleaning up player")
                currentVideoURL = nil
                cleanupPlayer()
            }
        }
        .onAppear {
            // Load video if one is already selected when view appears
            if let url = videoURL, currentVideoURL != url {
                print("🎬 [VIDEO] Loading video on appear: \(url.lastPathComponent)")
                currentVideoURL = url
                loadVideo(url: url)
            }
        }
        .onChange(of: currentTime) { oldValue, newValue in
            // Only seek if the time difference is significant (more than 0.5 seconds)
            // This prevents continuous seeking during normal playback
            if abs(newValue - oldValue) > 0.5 {
                seekToTime(newValue, shouldPlay: false)  // Don't auto-play on seek
            }
        }
    }

    private func cleanupPlayer() {
        if let currentPlayer = player {
            currentPlayer.pause()
            removeTimeObserver()
            currentPlayer.replaceCurrentItem(with: nil)
            player = nil
        }
    }
    
    private func loadVideo(url: URL) {
        // Stop and clean up old player
        if let oldPlayer = player {
            oldPlayer.pause()
            removeTimeObserver()
            oldPlayer.replaceCurrentItem(with: nil)
        }

        _ = url.startAccessingSecurityScopedResource()

        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])

        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 5.0

        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        newPlayer.preventsDisplaySleepDuringVideoPlayback = true

        player = newPlayer
        setupTimeObserver()
    }

    private func setupTimeObserver() {
        guard let player = player else { return }

        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func seekToTime(_ time: TimeInterval, shouldPlay: Bool = false) {
        guard let player = player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        if shouldPlay {
            player.play()
        }
    }

    private func togglePlayPause() {
        guard let player = player else { return }

        if player.timeControlStatus == .playing {
            print("🎬 [VIDEO] Pausing video")
            player.pause()
        } else {
            print("🎬 [VIDEO] Playing video")
            player.play()
        }
    }

    private func getCurrentSubtitle() -> TranscriptItem? {
        guard !transcriptItems.isEmpty else { return nil }

        // Find the subtitle whose timestamp is closest to but not greater than currentTime
        // and would still be displayed (before the next subtitle starts)
        var currentSubtitle: TranscriptItem?

        for (index, item) in transcriptItems.enumerated() {
            // Check if this subtitle should be displayed
            // Display if: currentTime >= item.timestamp AND currentTime < next item timestamp
            if currentTime >= item.timestamp {
                // Check if there's a next item
                if index < transcriptItems.count - 1 {
                    let nextItem = transcriptItems[index + 1]
                    if currentTime < nextItem.timestamp {
                        currentSubtitle = item
                        break
                    }
                } else {
                    // Last item - show if within 3 seconds of timestamp
                    if currentTime - item.timestamp <= 3.0 {
                        currentSubtitle = item
                    }
                }
            }
        }

        return currentSubtitle
    }
}

#Preview {
    VideoPlayerView(
        videoURL: nil,
        currentTime: .constant(0.0),
        showSubtitles: false,
        transcriptItems: []
    )
}
