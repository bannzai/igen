import AVFoundation
import Foundation
// SFSpeechAudioBufferRecognitionRequest は Sendable 宣言がないが、append はオーディオスレッドからの
// 呼び出しを想定した API のため @preconcurrency で警告を抑制する
@preconcurrency import Speech

/// 音声入力 (Speech framework) のラッパー。
/// 認識結果は AsyncThrowingStream で逐次返し、View 側の @State に反映する
/// (@Observable は使わない方針のため。.claude/rules/coding-rules.md)
@MainActor
final class SpeechRecognizer {
  /// 音声入力のエラー
  enum SpeechError: Error {
    /// マイクまたは音声認識が許可されていない
    case notAuthorized
    /// 端末の言語で音声認識が利用できない
    case recognizerUnavailable
  }

  private let audioEngine = AVAudioEngine()
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?

  /// 許可を確認してから録音を開始し、認識テキスト (partial 含む) を流すストリームを返す
  func start() async throws -> AsyncThrowingStream<String, Error> {
    // requestAuthorization のコールバックはバックグラウンドキューで呼ばれるため、
    // MainActor 分離と推論されないよう @Sendable を明示する (分離チェックのランタイムクラッシュ回避)
    let speechStatus = await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { @Sendable status in
        continuation.resume(returning: status)
      }
    }
    if speechStatus != .authorized {
      throw SpeechError.notAuthorized
    }
    if await AVAudioApplication.requestRecordPermission() == false {
      throw SpeechError.notAuthorized
    }
    guard let recognizer = SFSpeechRecognizer(locale: .autoupdatingCurrent), recognizer.isAvailable else {
      throw SpeechError.recognizerUnavailable
    }

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    recognitionRequest = request

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement, options: .duckOthers)
    try session.setActive(true, options: .notifyOthersOnDeactivation)

    let inputNode = audioEngine.inputNode
    let format = inputNode.outputFormat(forBus: 0)
    // tap のコールバックはオーディオスレッドで呼ばれるため @Sendable を明示する
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { @Sendable buffer, _ in
      request.append(buffer)
    }
    audioEngine.prepare()
    do {
      try audioEngine.start()
    } catch {
      // 開始途中で失敗したら、設置済みタップ・リクエスト・セッションを片付けてから投げる
      // (タップが残ったまま次回の installTap を呼ぶと例外でクラッシュするため)
      inputNode.removeTap(onBus: 0)
      recognitionRequest = nil
      deactivateAudioSession()
      throw error
    }

    return AsyncThrowingStream { continuation in
      // 認識結果のコールバックも任意のキューで呼ばれるため @Sendable を明示する
      recognitionTask = recognizer.recognitionTask(with: request) { @Sendable result, error in
        if let result {
          continuation.yield(result.bestTranscription.formattedString)
          if result.isFinal {
            continuation.finish()
          }
        }
        if error != nil {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in
        Task { @MainActor in
          self.stop()
        }
      }
    }
  }

  /// 録音と認識を止める。start 前・停止後に呼んでも安全 (冪等)
  func stop() {
    if audioEngine.isRunning {
      audioEngine.stop()
      audioEngine.inputNode.removeTap(onBus: 0)
    }
    recognitionRequest?.endAudio()
    recognitionRequest = nil
    recognitionTask?.cancel()
    recognitionTask = nil
    // マイク使用後も .duckOthers で他アプリの音声が下がり続けないよう、セッションを解除する
    deactivateAudioSession()
  }

  private func deactivateAudioSession() {
    // 解除の失敗 (他の音声処理が使用中など) はユーザーに提示しても対処できないため無視する
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
