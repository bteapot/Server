//
//  Take.swift
//  Server
//
//  Created by Денис Либит on 11.02.2022.
//

import Foundation


extension Server {
    public struct Take<Value>: Sendable {
        
        // MARK: - Creating
        
        /// Expect no data.
        ///
        /// Sets return value type to `Void`. Any received data will be ignored.
        public static func void() -> Take<Void> {
            .init(
                mimeType: "*/*",
                decode: { _, _, _ in () }
            )
        }
        
        /// Expect raw data.
        ///
        /// Sets return value type to `Data`. Received data will be passed as is.
        ///
        /// - Parameters:
        ///   - mimeType: Value for request's `"Accept"` header. Defaults to `"*/*"`.
        public static func data(mimeType: String = "*/*") -> Take<Data> {
            .init(
                mimeType: mimeType,
                decode: { config, data, response in data }
            )
        }
        
        /// Expect JSON.
        ///
        /// Sets return value type to specified type. Request's `"Accept"` header will be set to `"application/json"` value.
        ///
        /// - Parameters:
        ///   - type: Expected `Decodable` type.
        public static func json<T: Decodable>(_ type: T.Type) -> Take<T> {
            .init(
                mimeType: "application/json",
                decode: { config, data, response in try config.decoder.decode(T.self, from: data) }
            )
        }
        
        /// Custom response processing.
        ///
        /// Sets return value type to the return type of `decode` closure.
        ///
        /// - Parameters:
        ///   - mimeType: Optional value for `"Accept"` request header.
        ///   - check:    Optional response check. Overrides, if present, the one defined in config's ``Server/Server/Config-swift.struct/response``.
        ///   - decode:   Closure that will decode received data.
        public static func custom<T>(mimeType: String?, check: Config.ResponseHandler.Check? = nil, decode: @escaping Decode<T>) -> Take<T> {
            .init(
                mimeType: mimeType,
                check: check,
                decode: decode
            )
        }
        
        /// Take received response with other ``Server/Server/Take`` type.
        ///
        /// Completely skips any response check. Uses `"Accept"` header value and decoding method from specified ``Server/Server/Take``.
        ///
        /// - Parameters:
        ///   - take: Other ``Server/Server/Take`` type.
        public static func response<T>(with take: Take<T>) -> Take<(URLResponse, T)> {
            .init(
                mimeType: take.mimeType,
                check: { _, _, _, _ in },
                decode: { config, data, response in
                    await (response, try take.decode(config, data, response))
                }
            )
        }
        
        // MARK: - Types
        
        /// Closure that takes current ``Server/Server/Config-swift.struct``, received `Data` and `URLResponse`, and returns decoded data.
        public typealias Decode<T> = @Sendable (Config, Data, URLResponse) async throws -> T
        
        // MARK: - Properties
        
        let mimeType: String?
        let check: Config.ResponseHandler.Check?
        let decode: Decode<Value>
        
        // MARK: - Initialization
        
        private init(mimeType: String?, check: Config.ResponseHandler.Check? = nil, decode: @escaping Decode<Value>) {
            self.mimeType = mimeType
            self.check = check
            self.decode = decode
        }
    }
}
