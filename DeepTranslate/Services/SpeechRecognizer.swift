//
//  SpeechRecognizer.swift
//  DeepTranslate
//
//  Created by Zzy on 04/03/2025.
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognizer {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func startRecording(languageCode: String) async -> String? {
        // 设置正确的语言代码
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: languageCode))
        
        guard speechRecognizer != nil, await checkPermissions() else {
            return nil
        }
        
        // 重置之前的任务
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // 设置录音会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("设置音频会话失败: \(error.localizedDescription)")
            return nil
        }
        
        // 创建和配置请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("无法创建语音识别请求")
            return nil
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 设置输入节点
        let inputNode = audioEngine.inputNode
        
        return await withCheckedContinuation { continuation in
            // 开始录音
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            
            do {
                try audioEngine.start()
            } catch {
                print("无法启动音频引擎: \(error.localizedDescription)")
                continuation.resume(returning: nil)
                return
            }
            
            // 实际应用中实现完整异步识别
            var finalText = ""
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    finalText = result.bestTranscription.formattedString
                }
                
                if error != nil || result?.isFinal == true {
                    self.stopRecording()
                    continuation.resume(returning: finalText)
                }
            }
            
            // 超时保护（实际应用中可以改进）
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10秒超时
                if self.recognitionTask != nil {
                    self.stopRecording()
                    if finalText.isEmpty {
                        continuation.resume(returning: "无法识别语音，请重试")
                    } else {
                        continuation.resume(returning: finalText)
                    }
                }
            }
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 重置音频会话
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func checkPermissions() async -> Bool {
        // 检查语音识别权限
        let authStatus = await SFSpeechRecognizer.authorizationStatus()
        if authStatus != .authorized {
            let status = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
            guard status == .authorized else {
                return false
            }
        }
        
        // 检查麦克风权限
        let audioStatus = AVAudioSession.sharedInstance().recordPermission
        if audioStatus != .granted {
            let status = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted ? AVAudioSession.RecordPermission.granted : .denied)
                }
            }
            guard status == .granted else {
                return false
            }
        }
        
        return true
    }
}
