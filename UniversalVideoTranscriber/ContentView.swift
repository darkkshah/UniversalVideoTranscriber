//
//  ContentView.swift
//  UniversalVideoTranscriber
//
//  Main application view with modern, clean layout
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var transcriptionManager = TranscriptionManager()
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var downloadState = DownloadStateManager.shared
    @State private var selectedVideoURL: URL?
    @State private var currentTime: TimeInterval = 0.0
    @State private var searchQuery = ""
    @State private var selectedTab: ViewTab = .transcript
    @State private var showingFileImporter = false
    @State private var showingExporter = false
    @State private var showingSRTExporter = false
    @State private var showingSettings = false
    @State private var currentTranscription: TranscriptionData?
    @State private var showingPermissionAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var transcriptionStartTime: Date?
    @State private var isEditingTranscript = false
    @State private var showSubtitles = false

    enum ViewTab {
        case transcript
        case search
    }

    // MARK: - Language Organization

    private var commonAssemblyAILanguages: [String] {
        ["en", "es", "fr", "de", "it", "pt", "nl", "lt"]  // Lithuanian included in common
    }

    private var otherAssemblyAILanguages: [String] {
        let all = AssemblyAIService.supportedLanguages.keys.sorted { key1, key2 in
            let name1 = AssemblyAIService.supportedLanguages[key1] ?? key1
            let name2 = AssemblyAIService.supportedLanguages[key2] ?? key2
            return name1 < name2
        }
        return all.filter { !commonAssemblyAILanguages.contains($0) }
    }

    private var commonWhisperLanguages: [String] {
        ["en", "es", "fr", "de", "it", "pt", "nl", "lt", "auto"]  // Lithuanian + auto-detect
    }

    private var otherWhisperLanguages: [String] {
        let all = WhisperService.supportedLanguages.keys.sorted { key1, key2 in
            let name1 = WhisperService.supportedLanguages[key1] ?? key1
            let name2 = WhisperService.supportedLanguages[key2] ?? key2
            return name1 < name2
        }
        return all.filter { !commonWhisperLanguages.contains($0) }
    }

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Toolbar
                toolbarView
                
                Divider()

                // Main content area - 40% video / 60% transcript
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Video player (left side - 40%)
                        VideoPlayerView(
                            videoURL: selectedVideoURL,
                            currentTime: $currentTime,
                            showSubtitles: showSubtitles,
                            transcriptItems: transcriptionManager.transcriptItems
                        )
                        .frame(width: geometry.size.width * 0.4)

                        Divider()

                        // Transcript/Search panel (right side - 60%)
                        rightPanelView
                            .frame(width: geometry.size.width * 0.6)
                    }
                }
            }
            
            // Loading overlay
            if transcriptionManager.isTranscribing {
                loadingOverlay
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.movie, .video],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: TranscriptDocument(transcription: exportableTranscription),
            contentType: .plainText,
            defaultFilename: selectedVideoURL?.deletingPathExtension().lastPathComponent ?? "transcript"
        ) { result in
            handleExport(result)
        }
        .fileExporter(
            isPresented: $showingSRTExporter,
            document: SRTDocument(transcription: exportableTranscription, characterLimit: 42),
            contentType: .srt,
            defaultFilename: (selectedVideoURL?.deletingPathExtension().lastPathComponent ?? "transcript") + ".srt"
        ) { result in
            handleExport(result)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Speech recognition permission is required to transcribe videos. Please enable it in System Settings.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            if transcriptionManager.authorizationStatus == .notDetermined {
                await transcriptionManager.requestAuthorization()
            }
        }
    }
    
    private var exportableTranscription: TranscriptionData? {
        guard let base = currentTranscription else { return nil }
        return TranscriptionData(
            videoURL: base.videoURL,
            items: transcriptionManager.transcriptItems,
            videoDuration: base.videoDuration,
            transcriptionDuration: base.transcriptionDuration
        )
    }

    // MARK: - Toolbar

    private var toolbarView: some View {
        VStack(spacing: 12) {
            // FIRST ROW: App info, Engine, Language, Model, Download, Subtitles
            HStack(spacing: 20) {
                HStack(spacing: 10) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Universal Video Transcriber")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }

                Divider()
                    .frame(height: 28)

            HStack(spacing: 10) {
                Text("Engine:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    switch settings.transcriptionProvider {
                    case .apple:
                        Image(systemName: "applelogo")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Apple Speech")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    case .assemblyAI:
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("AssemblyAI")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    case .whisper:
                        Image(systemName: "waveform")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Whisper (\(settings.whisperModel.rawValue.capitalized))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: providerGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }

            Divider()
                .frame(height: 28)

            HStack(spacing: 10) {
                Text("Language:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                switch settings.transcriptionProvider {
                case .apple:
                    Picker("", selection: $transcriptionManager.selectedLocale) {
                        ForEach(transcriptionManager.availableLocales, id: \.identifier) { locale in
                            Text(displayName(for: locale))
                                .tag(locale)
                        }
                    }
                    .frame(width: 180)
                    .onChange(of: transcriptionManager.selectedLocale) { _, newLocale in
                        transcriptionManager.setLocale(newLocale)
                    }

                case .assemblyAI:
                    Picker("", selection: $transcriptionManager.assemblyAILanguage) {
                        // Common languages section
                        Section(header: Text("Common Languages")) {
                            ForEach(commonAssemblyAILanguages, id: \.self) { code in
                                Text(AssemblyAIService.supportedLanguages[code] ?? code).tag(code)
                            }
                        }

                        Divider()

                        // All other languages alphabetically
                        Section(header: Text("Other Languages")) {
                            ForEach(otherAssemblyAILanguages, id: \.self) { code in
                                Text(AssemblyAIService.supportedLanguages[code] ?? code).tag(code)
                            }
                        }
                    }
                    .frame(width: 180)

                case .whisper:
                    Picker("", selection: $transcriptionManager.assemblyAILanguage) {
                        // Common languages section
                        Section(header: Text("Common Languages")) {
                            ForEach(commonWhisperLanguages, id: \.self) { code in
                                Text(WhisperService.supportedLanguages[code] ?? code).tag(code)
                            }
                        }

                        Divider()

                        // All other languages alphabetically
                        Section(header: Text("Other Languages")) {
                            ForEach(otherWhisperLanguages, id: \.self) { code in
                                Text(WhisperService.supportedLanguages[code] ?? code).tag(code)
                            }
                        }
                    }
                    .frame(width: 180)
                }
            }

            // Whisper model selector (only for Whisper provider)
            if settings.transcriptionProvider == .whisper {
                Divider()
                    .frame(height: 28)

                HStack(spacing: 10) {
                    Text("Model:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    Picker("", selection: $settings.whisperModel) {
                        ForEach(WhisperService.WhisperModel.allCases, id: \.self) { model in
                            Text(model.rawValue.capitalized).tag(model)
                        }
                    }
                    .frame(width: 120)
                    .onChange(of: settings.whisperModel) {
                        WhisperService.shared.checkModelAvailability()
                    }

                    // Show download warning if model not downloaded
                    if !WhisperService.shared.isModelDownloaded {
                        Button(action: { showingSettings = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.blue)
                            }
                            .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .help("Model not downloaded - click to open Settings")
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                            .help("Model downloaded and ready")
                    }
                }
            }

            // Download indicator (persistent across Settings closing)
            if downloadState.isDownloading {
                Divider()
                    .frame(height: 28)

                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .controlSize(.small)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Downloading \(downloadState.downloadingModel?.rawValue.capitalized ?? "Model")...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)

                        ProgressView(value: downloadState.downloadProgress)
                            .frame(width: 120)
                            .progressViewStyle(.linear)

                        Text("\(Int(downloadState.downloadProgress * 100))%")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .help("Open Settings to view download details")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }

            // Subtitle toggle (only when transcript exists)
            if !transcriptionManager.transcriptItems.isEmpty {
                Divider()
                    .frame(height: 28)

                Button(action: {
                    showSubtitles.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showSubtitles ? "captions.bubble.fill" : "captions.bubble")
                            .foregroundColor(showSubtitles ? .blue : .secondary)
                        Text(showSubtitles ? "Hide Subtitles" : "Show Subtitles")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.plain)
                .help("Toggle subtitle preview on video")
            }

            Spacer()
        }

        // SECOND ROW: Action buttons
        HStack(spacing: 12) {
                Button(action: { showingFileImporter = true }) {
                    Label("Select Video", systemImage: "folder")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if selectedVideoURL != nil {
                    Button(action: { startTranscription() }) {
                        Label("Transcribe", systemImage: "waveform")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(transcriptionManager.isTranscribing || transcriptionManager.authorizationStatus != .authorized)
                }

                if !transcriptionManager.transcriptItems.isEmpty {
                    Menu {
                        Button(action: { showingExporter = true }) {
                            Label("As Text", systemImage: "doc.text")
                        }

                        Button(action: { showingSRTExporter = true }) {
                            Label("As SRT Subtitles", systemImage: "captions.bubble")
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .menuStyle(.borderlessButton)
                    .frame(height: 32)
                }

                Button(action: { showingSettings = true }) {
                    Label("Settings", systemImage: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            ZStack {
                Color(nsColor: .controlBackgroundColor)
                LinearGradient(
                    colors: [Color.white.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
    }

    private var providerGradientColors: [Color] {
        switch settings.transcriptionProvider {
        case .apple:
            return [.blue, .blue.opacity(0.8)]
        case .assemblyAI:
            return [.green, .green.opacity(0.8)]
        case .whisper:
            return [.purple, .purple.opacity(0.8)]
        }
    }
    
    // MARK: - Right Panel

    private var rightPanelView: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("", selection: $selectedTab) {
                Label("Transcript", systemImage: "text.alignleft").tag(ViewTab.transcript)
                Label("Search", systemImage: "magnifyingglass").tag(ViewTab.search)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case .transcript:
                    transcriptView
                case .search:
                    SearchView(
                        searchQuery: $searchQuery,
                        transcriptItems: transcriptionManager.transcriptItems,
                        onTimestampClick: { timestamp in
                            currentTime = timestamp
                        }
                    )
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Transcript View

    private var transcriptView: some View {
        Group {
            if transcriptionManager.transcriptItems.isEmpty {
                emptyTranscriptView
            } else {
                VStack(spacing: 0) {
                    // Transcription metadata header
                    if let transcription = currentTranscription,
                       let durationText = transcription.formattedTranscriptionDuration {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                            Text("Transcribed in \(durationText)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(transcription.items.count) segments")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)

                            Button(action: {
                                isEditingTranscript.toggle()
                            }) {
                                Label(isEditingTranscript ? "View" : "Edit", systemImage: isEditingTranscript ? "eye" : "pencil")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

                        Divider()
                    }

                    // Show editor or regular view based on edit mode
                    if isEditingTranscript {
                        TranscriptEditorView(
                            items: $transcriptionManager.transcriptItems,
                            isEditing: $isEditingTranscript
                        )
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                ForEach(transcriptionManager.transcriptItems) { item in
                                    TranscriptItemRow(item: item) {
                                        currentTime = item.timestamp
                                    }
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
        }
    }

    private var emptyTranscriptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "text.bubble")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("No Transcription Yet")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Select a video and click Transcribe to begin")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ProgressView(value: transcriptionManager.transcriptionProgress) {
                    Text(transcriptionManager.statusMessage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                .progressViewStyle(.linear)
                .frame(width: 320)
                .tint(.blue)

                Text(String(format: "%.0f%%", transcriptionManager.transcriptionProgress * 100))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                // Reset current time to beginning
                currentTime = 0.0
                // Set new video URL (this will trigger VideoPlayerView to reload)
                selectedVideoURL = url
                // Clear previous transcription when new video is selected
                transcriptionManager.transcriptItems = []
                currentTranscription = nil
            }
        case .failure(let error):
            print("Error selecting file: \(error.localizedDescription)")
        }
    }
    
    private func startTranscription() {
        guard let videoURL = selectedVideoURL else { return }

        if transcriptionManager.authorizationStatus != .authorized {
            showingPermissionAlert = true
            return
        }

        transcriptionStartTime = Date()

        Task {
            do {
                let items = try await transcriptionManager.transcribe(videoURL: videoURL)
                let transcriptionDuration = Date().timeIntervalSince(transcriptionStartTime ?? Date())

                let asset = AVURLAsset(url: videoURL)
                let duration = try await asset.load(.duration).seconds
                currentTranscription = TranscriptionData(
                    videoURL: videoURL,
                    items: items,
                    videoDuration: duration,
                    transcriptionDuration: transcriptionDuration
                )
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
                print("Transcription error: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Exported to: \(url)")
        case .failure(let error):
            print("Export error: \(error.localizedDescription)")
        }
    }

    private func displayName(for locale: Locale) -> String {
        let languageName = Locale.current.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
        return "\(languageName) (\(locale.identifier))"
    }
}

// MARK: - Transcript Item Row

struct TranscriptItemRow: View {
    let item: TranscriptItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                Text(item.formattedTimestamp)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(6)
                    .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)

                Text(item.text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(2)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Document for export

struct TranscriptDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var text: String = ""
    
    init(transcription: TranscriptionData?) {
        guard let transcription = transcription else { return }
        
        var content = "Lithuanian Video Transcription\n"
        content += "Video: \(transcription.videoURL.lastPathComponent)\n"
        content += "Created: \(transcription.createdAt.formatted())\n"
        content += "Duration: \(Self.formatDuration(transcription.videoDuration))\n"
        content += "\n" + String(repeating: "=", count: 60) + "\n\n"
        
        for item in transcription.items {
            content += "[\(item.formattedTimestamp)] \(item.text)\n"
        }
        
        self.text = content
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
    
    private static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    ContentView()
}
