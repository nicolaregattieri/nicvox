import Foundation
import Speech
import AVFoundation
import AppKit

class SpeechManager: NSObject, SFSpeechRecognizerDelegate, ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var isRecording = false
    var currentLocaleId = ""
    
    var onTextRecognized: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    override init() {
        super.init()
        SFSpeechRecognizer.requestAuthorization { _ in }
        
        // Ensure defaults exist
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "playSounds") == nil { defaults.set(true, forKey: "playSounds") }
        if defaults.object(forKey: "startSound") == nil { defaults.set("Tink", forKey: "startSound") }
        if defaults.object(forKey: "stopSound") == nil { defaults.set("Pop", forKey: "stopSound") }
    }
    
    func startRecording(localeId: String) throws {
        if isRecording {
            stopRecording()
            return 
        }
        
        // Setup Recognizer
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId))
        speechRecognizer?.delegate = self
        currentLocaleId = localeId
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create request") }
        
        if #available(macOS 10.15, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                if isFinal {
                    self.onTextRecognized?(text)
                }
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isRecording = false
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        print("Recording started in \(localeId)...")
        
        // Play Start Sound
        let soundName = UserDefaults.standard.string(forKey: "startSound") ?? "Tink"
        playSound(name: soundName)
    }
    
    func stopRecording() {
        if isRecording {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            isRecording = false
            print("Recording stopped.")
            
            // Play Stop Sound
            let soundName = UserDefaults.standard.string(forKey: "stopSound") ?? "Pop"
            playSound(name: soundName)
        }
    }
    
    private func playSound(name: String) {
        if UserDefaults.standard.bool(forKey: "playSounds") {
            NSSound(named: name)?.play()
        }
    }
}