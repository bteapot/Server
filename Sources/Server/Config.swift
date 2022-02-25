//
//  Config.swift
//
//
//  Created by Денис Либит on 11.02.2022.
//

import Foundation
import ReactiveSwift


extension Server {
    public struct Config {
        
        // MARK: - Initialization
        
        /// Creates a `Server`'s configuration with specified parameters.
        /// - Parameters:
        ///   - timeout: Default [timeoutInterval](https://developer.apple.com/documentation/foundation/urlrequest/2011509-timeoutinterval) value for all requests.
        ///   - base: Default base `URL` for all requests.
        ///   - headers: Base key-value pairs for [allHTTPHeaderFields](https://developer.apple.com/documentation/foundation/urlrequest/2011502-allhttpheaderfields) of all requests.
        ///   - query: Base key-value pairs for [queryItems](https://developer.apple.com/documentation/foundation/urlcomponents/1779966-queryitems) of all requests.
        ///   - session: `URLSessionConfiguration` provider.
        ///   - challenge: Handling of `URLSessionDelegate`'s authentication challenges (see [here](https://developer.apple.com/documentation/foundation/urlsessiondelegate/1409308-urlsession)).
        ///   - request: Optional closure for fine-tuning any `URLRequest`.
        ///   - response: Response handling (see ``Server/Server/Tools/check(config:take:request:response:data:)``).
        ///   - encoder: Optional closure for `JSONEncoder` configuration.
        ///   - decoder: Optional closure for `JSONDecoder` configuration.
        ///   - catcher: Optional closure for mapping or canceling errors.
        ///   - reports: Optional local file system folder `URL` for response data dumps on decoding failures. Used only with DEBUG builds. Specify something like `URL(fileURLWithPath: "/Users/<your username>/Downloads")`.
        public init(
            timeout:  TimeInterval = 60,
            base:      URL,
            headers:   [String: String] = [:],
            query:     [String: String] = [:],
            session:   SessionConfiguration = .ephemeral,
            challenge: ChallengeHandler = .standard,
            request:   Configure<URLRequest>? = nil,
            response:  ResponseHandler = .standard(),
            encoder:   Configure<JSONEncoder>? = nil,
            decoder:   Configure<JSONDecoder>? = nil,
            catcher:   Catcher? = nil,
            reports:   URL? = nil
        ) {
            // common request parameters
            self.timeout = timeout
            self.base    = base
            self.headers = headers
            self.query   = query
            
            // session configuration
            self.session = session
            
            // authentication challenge response
            self.challenge = challenge
            
            // request configuration
            self.request = request
            
            // response handling
            self.response = response
            
            // encoder
            self.encoder = {
                var e = JSONEncoder()
                encoder?(&e)
                return e
            }()
            
            // decoder
            self.decoder = {
                var d = JSONDecoder()
                decoder?(&d)
                return d
            }()
            
            // error catcher
            self.catcher = catcher
            
            // dump response data into this local folder when decoding error occurs
            #if DEBUG
            if let reports = reports {
                assert(reports.isFileURL)
            }
            self.reports = reports
            #endif
        }
        
        // MARK: - Types
        
        public typealias Configure<T> = (inout T) -> Void
        
        public enum SessionConfiguration {
            case `default`
            case ephemeral
            case custom(() -> URLSessionConfiguration)
            
            var configuration: URLSessionConfiguration {
                switch self {
                    case .default:              return .default
                    case .ephemeral:            return .ephemeral
                    case .custom(let provider): return provider()
                }
            }
        }
        
        public enum ChallengeHandler {
            case standard
            case handle((URLSessionTask?, URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))
        }
        
        public enum ResponseHandler {
            case standard(Describe? = nil)
            case handle(Check)
            
            public typealias Describe = (Config, URLRequest, HTTPURLResponse, Data) -> String
            public typealias Check    = (Config, URLRequest, URLResponse, Data) throws -> Void
        }
        
        public typealias Catcher = (Error) -> Error?
        
        // MARK: - Properties
        
        public let timeout:   TimeInterval
        public let base:      URL
        public let headers:   [String: String]
        public let query:     [String: String]
        public let session:   SessionConfiguration
        public let challenge: ChallengeHandler
        public let request:   Configure<URLRequest>?
        public let response:  ResponseHandler
        public let encoder:   JSONEncoder
        public let decoder:   JSONDecoder
        public let catcher:   Catcher?
        
        #if DEBUG
        public let reports:  URL?
        #endif
    }
}
