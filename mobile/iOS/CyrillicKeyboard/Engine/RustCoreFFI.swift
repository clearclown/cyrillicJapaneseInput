//
//  RustCoreFFI.swift
//  Cyrillic IME
//
//  FFI Bridge to Rust Core
//

import Foundation

/// Rust Core FFI関数の宣言
/// 実際のバインディングはXcodeプロジェクトでlibcyrillic_ime_core.aをリンクする必要がある
///
/// 戻り値: null = 成功, non-null = エラーメッセージ（rust_free_stringで解放が必要）
@_silgen_name("rust_init_engine")
func rust_init_engine(_ profiles_json: UnsafePointer<CChar>, _ kana_engine_json: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?

@_silgen_name("rust_load_schema")
func rust_load_schema(_ schema_json: UnsafePointer<CChar>, _ schema_id: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?

@_silgen_name("rust_process_key")
func rust_process_key(_ cyrillic_key: UnsafePointer<CChar>, _ current_buffer: UnsafePointer<CChar>, _ profile_id: UnsafePointer<CChar>, _ last_output: UnsafePointer<CChar>, _ last_vowel_type: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?

@_silgen_name("rust_free_string")
func rust_free_string(_ ptr: UnsafeMutablePointer<CChar>)

@_silgen_name("rust_get_version")
func rust_get_version() -> UnsafePointer<CChar>?

/// Rust Coreとの通信を管理するクラス
class RustCoreFFI {
    // MARK: - Singleton
    static let shared = RustCoreFFI()

    private var isInitialized = false

    init() {} // Internal for test mocking

    // MARK: - Helper: CString処理

    /// Rustから返されたC文字列をSwift Stringに変換してメモリ解放
    /// - Parameter ptr: nullの場合はnilを返す（成功を意味する）
    /// - Returns: エラーメッセージ文字列、nilの場合は成功
    private func consumeRustString(_ ptr: UnsafeMutablePointer<CChar>?) -> String? {
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
        // 既にSwift側で初期化済みの場合はスキップ
        if isInitialized {
            print("[RustCoreFFI] Engine already initialized (Swift flag)")
            return nil
        }

        let errorPtr = profilesJSON.withCString { profilesPtr in
            kanaEngineJSON.withCString { kanaPtr in
                rust_init_engine(profilesPtr, kanaPtr)
            }
        }

        // null = 成功, non-null = エラーメッセージ
        if let errorMessage = consumeRustString(errorPtr) {
            // Rust側で既に初期化済みの場合は成功とみなす
            if errorMessage.contains("already initialized") {
                print("[RustCoreFFI] Engine already initialized (Rust side), continuing...")
                isInitialized = true
                return nil
            }
            return errorMessage
        }

        isInitialized = true
        print("[RustCoreFFI] Engine initialized successfully")
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

        let errorPtr = schemaJSON.withCString { schemaPtr in
            schemaId.withCString { idPtr in
                rust_load_schema(schemaPtr, idPtr)
            }
        }

        // null = 成功, non-null = エラーメッセージ
        return consumeRustString(errorPtr)
    }

    /// キー入力を処理
    /// - Parameters:
    ///   - cyrillicKey: 入力されたキリル文字
    ///   - currentBuffer: 現在の入力バッファ
    ///   - profileId: 使用するプロファイルID
    ///   - lastOutput: 最後の出力（長音検出用）
    ///   - lastVowelType: 最後の母音タイプ（連続長音検出用）
    /// - Returns: 変換結果、エラー時はnil
    func processKey(cyrillicKey: String, currentBuffer: String, profileId: String, lastOutput: String = "", lastVowelType: String? = nil) -> ConversionResult? {
        guard isInitialized else {
            print("[RustCoreFFI] Error: Engine not initialized")
            return nil
        }

        let jsonPtr = cyrillicKey.withCString { keyPtr in
            currentBuffer.withCString { bufferPtr in
                profileId.withCString { profilePtr in
                    lastOutput.withCString { lastOutputPtr in
                        (lastVowelType ?? "").withCString { lastVowelTypePtr in
                            rust_process_key(keyPtr, bufferPtr, profilePtr, lastOutputPtr, lastVowelTypePtr)
                        }
                    }
                }
            }
        }

        guard let jsonString = consumeRustString(jsonPtr) else {
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
        // rust_get_versionは静的文字列を返すため、free不要
        return String(cString: versionPtr)
    }

    /// エンジンが初期化済みかどうか
    var initialized: Bool {
        return isInitialized
    }
}
