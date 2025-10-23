//
//  RustCoreFFI.swift
//  Cyrillic IME
//
//  FFI Bridge to Rust Core
//

import Foundation

/// Rust Core FFI関数の宣言
/// 実際のバインディングはXcodeプロジェクトでlibcyrillic_ime_core.aをリンクする必要がある
@_silgen_name("rust_init_engine")
func rust_init_engine(_ profiles_json: UnsafePointer<CChar>, _ kana_engine_json: UnsafePointer<CChar>) -> UnsafePointer<CChar>?

@_silgen_name("rust_load_schema")
func rust_load_schema(_ schema_json: UnsafePointer<CChar>, _ schema_id: UnsafePointer<CChar>) -> UnsafePointer<CChar>?

@_silgen_name("rust_process_key")
func rust_process_key(_ cyrillic_key: UnsafePointer<CChar>, _ current_buffer: UnsafePointer<CChar>, _ profile_id: UnsafePointer<CChar>) -> UnsafePointer<CChar>?

@_silgen_name("rust_free_string")
func rust_free_string(_ ptr: UnsafePointer<CChar>)

@_silgen_name("rust_get_version")
func rust_get_version() -> UnsafePointer<CChar>?

/// Rust Coreとの通信を管理するクラス
class RustCoreFFI {
    // MARK: - Singleton
    static let shared = RustCoreFFI()

    private var isInitialized = false

    private init() {}

    // MARK: - Helper: CString処理

    /// Rustから返されたC文字列をSwift Stringに変換してメモリ解放
    private func consumeRustString(_ ptr: UnsafePointer<CChar>?) -> String? {
        guard let ptr = ptr else { return nil }
        defer { rust_free_string(ptr) }
        return String(cString: ptr)
    }

    // MARK: - Public API

    /// エンジンを初期化
    /// - Parameters:
    ///   - profilesJSON: プロファイル配列のJSON文字列
    ///   - kanaEngineJSON: かなエンジンマッピングのJSON文字列
    /// - Returns: 成功時はnil、エラー時はエラーメッセージ
    func initEngine(profilesJSON: String, kanaEngineJSON: String) -> String? {
        guard !isInitialized else {
            return "Engine already initialized"
        }

        let result = profilesJSON.withCString { profilesPtr in
            kanaEngineJSON.withCString { kanaPtr in
                rust_init_engine(profilesPtr, kanaPtr)
            }
        }

        if let errorMessage = consumeRustString(result) {
            // エラーメッセージが返された場合
            return errorMessage
        }

        isInitialized = true
        return nil
    }

    /// スキーマをロード
    /// - Parameters:
    ///   - schemaJSON: スキーママッピングのJSON文字列
    ///   - schemaId: スキーマID（例: "schema_rus_v1"）
    /// - Returns: 成功時はnil、エラー時はエラーメッセージ
    func loadSchema(schemaJSON: String, schemaId: String) -> String? {
        guard isInitialized else {
            return "Engine not initialized"
        }

        let result = schemaJSON.withCString { schemaPtr in
            schemaId.withCString { idPtr in
                rust_load_schema(schemaPtr, idPtr)
            }
        }

        return consumeRustString(result)
    }

    /// キー入力を処理
    /// - Parameters:
    ///   - cyrillicKey: 入力されたキリル文字
    ///   - currentBuffer: 現在の入力バッファ
    ///   - profileId: 使用するプロファイルID
    /// - Returns: 変換結果、エラー時はnil
    func processKey(cyrillicKey: String, currentBuffer: String, profileId: String) -> ConversionResult? {
        guard isInitialized else {
            print("[RustCoreFFI] Error: Engine not initialized")
            return nil
        }

        let resultPtr = cyrillicKey.withCString { keyPtr in
            currentBuffer.withCString { bufferPtr in
                profileId.withCString { profilePtr in
                    rust_process_key(keyPtr, bufferPtr, profilePtr)
                }
            }
        }

        guard let jsonString = consumeRustString(resultPtr) else {
            print("[RustCoreFFI] Error: Failed to get result from Rust")
            return nil
        }

        // JSONをConversionResultにデコード
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("[RustCoreFFI] Error: Invalid UTF-8 in JSON response")
            return nil
        }

        do {
            let result = try JSONDecoder().decode(ConversionResult.self, from: jsonData)
            return result
        } catch {
            print("[RustCoreFFI] Error decoding JSON: \(error)")
            print("[RustCoreFFI] JSON string: \(jsonString)")
            return nil
        }
    }

    /// Rustバージョン情報を取得
    /// - Returns: バージョン文字列
    func getVersion() -> String {
        guard let versionPtr = rust_get_version() else {
            return "unknown"
        }
        return consumeRustString(versionPtr) ?? "unknown"
    }

    /// エンジンが初期化済みかどうか
    var initialized: Bool {
        return isInitialized
    }
}
