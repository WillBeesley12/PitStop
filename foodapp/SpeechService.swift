import Foundation
import AVFoundation
import Speech
import Combine

@MainActor
final class SpeechService: NSObject, ObservableObject {
    
    // MARK: - TTS (speaker)
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    // MARK: - STT (microphone)
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isListening = false
    @Published var transcribedText = ""
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // MARK: - Permissions
    func requestPermissions() async -> Bool {
        // 1. Speech recognition permission
        let speechAuth = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechAuth == .authorized else {
            print("❌ Speech recognition not authorized: \(speechAuth.rawValue)")
            return false
        }
        
        // 2. Microphone permission
        let micAuth = await AVAudioApplication.requestRecordPermission()
        guard micAuth else {
            print("❌ Microphone not authorized")
            return false
        }
        
        print("✅ All voice permissions granted")
        return true
    }
    
    // MARK: - Start Listening
    func startListening() throws {
        if isListening { stopListening() }
        
        guard let recognizer, recognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }
        
        // Configure audio session for recording + playback (driving context)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create a fresh recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request
        
        // Tap the mic and feed audio buffers into the request
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start the recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            
            if let result {
                Task { @MainActor in
                    self.transcribedText = result.bestTranscription.formattedString
                    print("🎤 Heard: \(self.transcribedText)")
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                Task { @MainActor in
                    self.stopListening()
                }
            }
        }
        
        isListening = true
        print("🎤 Listening…")
    }
    
    // MARK: - Stop Listening
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        print("🛑 Stopped listening")
    }
    
    // MARK: - TTS
    func speak(_ text: String) {
        // Configure audio session for playback.
        // .playback category bypasses the silent switch — same behavior as
        // Apple Maps voice nav, music apps, podcasts. Critical for a driving app.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try session.setActive(true)
        } catch {
            print("⚠️ Audio session setup for playback failed: \(error)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = bestAvailableVoice()
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Voice Selection
    // Picks the best available voice on this device, falling back gracefully.
    // Tries premium voices first, then enhanced, then default.
    private func bestAvailableVoice() -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        
        // Preferred voices in priority order. Evan first since it's downloaded.
        let preferredNames = ["Evan", "Ava", "Zoe", "Samantha"]
        
        // 1. Try premium voices by name
        for name in preferredNames {
            if let voice = allVoices.first(where: {
                $0.name == name &&
                $0.language.hasPrefix("en") &&
                $0.quality == .premium
            }) {
                print("🔊 Using premium voice: \(voice.name)")
                return voice
            }
        }
        
        // 2. Try enhanced voices
        for name in preferredNames {
            if let voice = allVoices.first(where: {
                $0.name == name &&
                $0.language.hasPrefix("en") &&
                $0.quality == .enhanced
            }) {
                print("🔊 Using enhanced voice: \(voice.name)")
                return voice
            }
        }
        
        // 3. Fall back to any English enhanced voice
        if let enhanced = allVoices.first(where: {
            $0.language.hasPrefix("en") && $0.quality == .enhanced
        }) {
            print("🔊 Using fallback enhanced voice: \(enhanced.name)")
            return enhanced
        }
        
        // 4. Last resort: system default
        print("🔊 Using system default voice")
        return AVSpeechSynthesisVoice(language: "en-US")
    }
}

// MARK: - Errors
enum SpeechError: Error {
    case recognizerUnavailable
}

// MARK: - Synthesizer Delegate
extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                        didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = true }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                        didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}
