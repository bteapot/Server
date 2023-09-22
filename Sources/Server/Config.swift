//
//  Config.swift
//  Server
//
//  Created by Денис Либит on 11.02.2022.
//

import Foundation


extension Server {
    public struct Config: Sendable {
        
        // MARK: - Initialization
        
        /// Creates a `Server`'s configuration with specified parameters.
        /// - Parameters:
        ///   - timeout: Default [timeoutInterval](https://developer.apple.com/documentation/foundation/urlrequest/2011509-timeoutinterval) value for all requests.
        ///   - base: Default base `URL` for all requests.
        ///   - headers: Base key-value pairs for [allHTTPHeaderFields](https://developer.apple.com/documentation/foundation/urlrequest/2011502-allhttpheaderfields) of all requests.
        ///   - query: Base key-value pairs for [queryItems](https://developer.apple.com/documentation/foundation/urlcomponents/1779966-queryitems) of all requests.
        ///   - config: `URLSessionConfiguration` for new session.
        ///   - challenge: Handling of `URLSessionDelegate`'s authentication challenges (see [here](https://developer.apple.com/documentation/foundation/urlsessiondelegate/1409308-urlsession)).
        ///   - request: Optional closure for fine-tuning any `URLRequest`.
        ///   - response: Response handling (see ``Server/Server/Tools/check(config:take:request:response:data:)``).
        ///   - encoder: Optional closure for `JSONEncoder` configuration.
        ///   - decoder: Optional closure for `JSONDecoder` configuration.
        ///   - catcher: Optional closure for mapping or canceling errors.
        ///   - reports: Reports mode. Defaults to `none`. Works only for `DEBUG` builds.
        public init(
            timeout:  TimeInterval = 60,
            base:      URL,
            headers:   [String: String] = [:],
            query:     [String: String] = [:],
            config:    URLSessionConfiguration = .ephemeral,
            challenge: ChallengeHandler = .standard,
            request:   Configure<URLRequest>? = nil,
            response:  ResponseHandler = .standard(),
            encoder:   Configure<JSONEncoder>? = nil,
            decoder:   Configure<JSONDecoder>? = nil,
            catcher:   Catcher? = nil,
            reports:   Reports = .none
        ) {
            // common request parameters
            self.timeout = timeout
            self.base    = base
            self.headers = headers
            self.query   = query
            
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
            
            // session
            self.session = 
                URLSession(
                    configuration: config,
                    delegate:      Delegate(with: challenge),
                    delegateQueue: nil
                )
            
            // dump response data into this local folder when decoding error occurs
            #if DEBUG
            if let url = reports.url {
                assert(url.isFileURL)
            }
            self.reports = reports
            #endif
        }
        
        // MARK: - Types
        
        public typealias Configure<T> = @Sendable (inout T) -> Void
        
        public enum ChallengeHandler {
            case standard
            case handle((URLSessionTask?, URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))
        }
        
        public enum ResponseHandler: Sendable {
            case standard(Describe? = nil)
            case handle(Check)
            
            public typealias Describe = @Sendable (Config, URLRequest, HTTPURLResponse, Data) -> String
            public typealias Check    = @Sendable (Config, URLRequest, URLResponse, Data) async throws -> Void
        }
        
        public typealias Catcher = @Sendable (Error) -> Error?
        
        // MARK: - Properties
        
        public let timeout:   TimeInterval
        public let base:      URL
        public let headers:   [String: String]
        public let query:     [String: String]
        public let request:   Configure<URLRequest>?
        public let response:  ResponseHandler
        public let encoder:   JSONEncoder
        public let decoder:   JSONDecoder
        public let catcher:   Catcher?
        
        public let session:   URLSession
        
        #if DEBUG
        public let reports:   Reports
        #endif
        
        private let usage = Usage()
    }
}

// MARK: - Reports mode

extension Server.Config {
    /// Reports mode.
    ///
    /// - **`none`**: No reporting.
    /// - **`logs`**: Will be logged request events such as starting, finishing, errors and execution duration. Used only with `DEBUG` builds.
    /// - **`dumps`**: Same as `logs` plus decoding failures data dumps. Takes local file system folder `URL` for response data dumps on decoding failures. Used only with `DEBUG` builds. Specify something like `URL(fileURLWithPath: "/Users/<your username>/Downloads")`. Will also turn on request execution logs when present.
    /// - **`full`**: Same as `logs` plus `dumps`.
    public enum Reports: Sendable {
        case none
        case logs
        case dumps(URL)
        case full(URL)
    }
}

// MARK: - Usage and invalidation

extension Server.Config {
    private actor Usage {
        
        // MARK: - Properties
        
        var invalidated: Bool = false
        
        var count: Int = 0 {
            didSet {
                if let continuation = self.continuation, self.count == 0 {
                    continuation.resume()
                }
            }
        }
        
        private var continuation: CheckedContinuation<Void, Never>?
        
        // MARK: - Methods
        
        func check() throws {
            if self.invalidated == true {
                throw CancellationError()
            }
        }
        
        func invalidate() throws {
            try self.check()
            self.invalidated = true
        }
        
        func checkin() throws {
            try self.check()
            self.count += 1
        }
        
        func checkout() {
            self.count -= 1
        }
        
        func empty() async {
            if self.count == 0 {
                return
            }
            
            await withCheckedContinuation { self.continuation = $0 }
        }
    }
}

extension Server.Config {
    func invalidate() {
        Task {
            // mark as invalidated, if not already
            try await self.usage.invalidate()
            
            // cancel all current tasks
            let tasks = await self.session.allTasks
            
            for task in tasks {
                task.cancel()
            }
            
            // await zero usage
            await self.usage.empty()
            
            // invalidate session
            self.session.invalidateAndCancel()
        }
    }
    
    func checkInvalidation() async throws {
        try await self.usage.check()
    }
    
    func checkin() async throws {
        try await self.usage.checkin()
    }
    
    func checkout() async {
        await self.usage.checkout()
    }
}

#if DEBUG

// MARK: - Debug

extension Server.Config.Reports {
    var logging: Bool {
        switch self {
            case .logs: return true
            case .full: return true
            default:    return false
        }
    }
    
    var url: URL? {
        switch self {
            case .dumps(let url): return url
            case .full(let url):  return url
            default:              return nil
        }
    }
}
#endif
