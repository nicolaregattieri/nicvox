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
        SFSpeechRecognizer.requestAuthorization { status in
            Logger.shared.log("Auth status: \(status.rawValue)")
        }
        
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
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId)) else {
            throw NSError(domain: "NicVox", code: 1, userInfo: [NSLocalizedDescriptionKey: "Locale not supported"])
        }
        speechRecognizer = recognizer
        speechRecognizer?.delegate = self
        currentLocaleId = localeId
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else { return }
        
        if #available(macOS 10.15, *) {
            req.requiresOnDeviceRecognition = false
        }
        req.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        recognitionTask = speechRecognizer?.recognitionTask(with: req) { [weak self] result, error in
            guard let self = self else { return }
            var isFinal = false
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                if isFinal {
                    self.onTextRecognized?(text)
                }
            }
            
            if error != nil || isFinal {
                self.stopAudioEngineSafe()
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
        Logger.shared.log("Recording started in \(localeId)")
        
        let soundName = UserDefaults.standard.string(forKey: "startSound") ?? "Tink"
        playSound(name: soundName)
    }
    
    func stopRecording() {
        if isRecording {
            stopAudioEngineSafe()
            isRecording = false
            
            let soundName = UserDefaults.standard.string(forKey: "stopSound") ?? "Pop"
            playSound(name: soundName)
        }
    }
    
    private func stopAudioEngineSafe() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
    }
    
    private func playSound(name: String) {
        if UserDefaults.standard.bool(forKey: "playSounds") {
            NSSound(named: name)?.play()
        }
    }
}
