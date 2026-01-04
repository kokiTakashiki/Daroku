//
//  ImageOCRService.swift
//  Daroku
//

import AppKit
import Vision

/// Vision frameworkを使用して画像からテキストを抽出するサービス
@MainActor
final class ImageOCRService {
    /// OCR処理中に発生するエラー
    enum OCRError: LocalizedError {
        /// 画像を読み込めなかった場合
        case invalidImage
        /// テキスト認識に失敗した場合
        case recognitionFailed(Error)
        /// テキストが見つからなかった場合
        case noTextFound

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                "画像を読み込めませんでした"
            case let .recognitionFailed(error):
                "テキスト認識に失敗しました: \(error.localizedDescription)"
            case .noTextFound:
                "テキストが見つかりませんでした"
            }
        }
    }

    /// 画像からテキストを認識して抽出する
    /// - Parameter image: 認識対象の画像
    /// - Returns: 認識されたテキストの配列
    func recognizeText(from image: NSImage) async throws -> [String] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: recognizedStrings)
            }

            // 日本語と英語を認識対象に設定
            request.recognitionLanguages = ["ja-JP", "en-US"]
            // 高精度モードを使用
            request.recognitionLevel = .accurate
            // 言語補正を有効化
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }

    /// ファイルURLから画像を読み込んでテキストを認識する
    /// - Parameter url: 画像ファイルのURL
    /// - Returns: 認識されたテキストの配列
    func recognizeText(from url: URL) async throws -> [String] {
        guard let image = NSImage(contentsOf: url) else {
            throw OCRError.invalidImage
        }
        return try await recognizeText(from: image)
    }
}
