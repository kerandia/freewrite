//
//  SpeechRecognitionManager.swift
//  freewrite
//
//  Created by thorfinn on 2/14/25.
//

import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecognitionManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcriptionText = ""
    @Published var isAuthorized = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var recognitionError: String?
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var originalText = "" // Store original text before speech recognition starts
    
    init() {
        // Initialize speech recognizer for current locale
        speechRecognizer = SFSpeechRecognizer()
        speechRecognizer?.delegate = self
    }
    
    func requestAuthorization() {
        // First request microphone permission on macOS
        #if os(macOS)
        requestMicrophonePermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.requestSpeechRecognitionAuthorization()
                } else {
                    self?.authorizationStatus = .denied
                    self?.isAuthorized = false
                    self?.recognitionError = "Microphone access denied"
                }
            }
        }
        #else
        requestSpeechRecognitionAuthorization()
        #endif
    }
    
    #if os(macOS)
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    #endif
    
    private func requestSpeechRecognitionAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                self?.isAuthorized = status == .authorized
                
                if status != .authorized {
                    switch status {
                    case .denied:
                        self?.recognitionError = "Speech recognition access denied"
                    case .restricted:
                        self?.recognitionError = "Speech recognition restricted on this device"
                    case .notDetermined:
                        self?.recognitionError = "Speech recognition not determined"
                    @unknown default:
                        self?.recognitionError = "Unknown speech recognition status"
                    }
                }
            }
        }
    }
    
    func startRecording(withCurrentText currentText: String = "") {
        guard isAuthorized else {
            recognitionError = "Speech recognition not authorized"
            return
        }
        
        #if os(macOS)
        // Check microphone permission on macOS
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            recognitionError = "Microphone access not authorized"
            return
        }
        #endif
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            recognitionError = "Speech recognizer not available"
            return
        }
        
        // Store the original text
        originalText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session (iOS only)
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            recognitionError = "Audio session setup failed: \(error.localizedDescription)"
            return
        }
        #endif
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            recognitionError = "Unable to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Get input node
        let inputNode = audioEngine.inputNode
        
        // Create recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcriptionText = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    self?.recognitionError = "Recognition error: \(error.localizedDescription)"
                    self?.stopRecording()
                }
                
                if result?.isFinal == true {
                    self?.stopRecording()
                }
            }
        }
        
        // Configure input node
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            recognitionError = nil
        } catch {
            recognitionError = "Audio engine failed to start: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        
        // Deactivate audio session (iOS only)
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
        #endif
    }
    
    func clearTranscription() {
        transcriptionText = ""
        recognitionError = nil
        originalText = ""
    }
    
    func getFullText() -> String {
        if originalText.isEmpty {
            return transcriptionText
        } else {
            return originalText + " " + transcriptionText
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognitionManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.recognitionError = "Speech recognizer became unavailable"
                self.stopRecording()
            }
        }
    }
}