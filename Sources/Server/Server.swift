//
//  Server.swift
//  Server
//
//  Created by Денис Либит on 11.02.2022.
//

import Foundation


/// An object that represents specific backend.
///
/// `Server` class provides coordination between changes in its configuration and session- and request-level nuances of specific backend service.
open class Server: @unchecked Sendable {
    
    // MARK: - Initialization
    
    /// Creates and returns a `Server` instance.
    ///
    /// - Parameter config: Initial ``Config-swift.struct`` value.
    public init(with config: Config) {
        self.container = Container(with: config)
    }
    
    // MARK: - Config
    
    private actor Container {
        var config: Config {
            didSet {
                if self.config.break {
                    oldValue.invalidate()
                }
            }
        }
        
        init(with config: Config) {
            self.config = config
        }
        
        func set(_ config: Config) {
            self.config = config
        }
    }
    
    private let container: Container
    
    /// Get current ``Server/Server/Config-swift.struct`` value.
    public var config: Config {
        get async {
            await self.container.config
        }
    }
    
    /// Sets new ``Server/Server/Config-swift.struct`` value.
    /// - Parameter config: New ``Server/Server/Config-swift.struct``.
    ///
    /// Changes to the current ``Config-swift.struct`` will cancel all ongoing requests and invalidate current `URLSession`.
    public func set(_ config: Config) async {
        await self.container.set(config)
    }
    
    // MARK: - Requests
    
    /// Execute arbitrary network request.
    ///
    /// - Parameter request: Custom `URLRequest`.
    /// - Returns: Server response's `Data` and `URLResponse` tuple.
    open func raw(with request: URLRequest) async throws -> (Data, URLResponse) {
        return try await self.config.session
            .data(for: request)
    }
    
    /// Perfom network request.
    ///
    /// - Parameters:
    ///   - type:    HTTP RESTful method.
    ///   - base:    Override config's ``Config-swift.struct/base`` URL when non-`nil`.
    ///   - path:    Request path.
    ///   - timeout: Override config's ``Config-swift.struct/timeout`` value when non-`nil`.
    ///   - headers: Request headers. Defaults to empty.
    ///   - query:   Request query. Defaults to empty.
    ///   - send:    Request's outgoing data handler. Defaults to ``Send/void()``.
    ///   - take:    Expected response data handler.
    ///   - catcher: Overrides config's ``Config-swift.struct/catcher-swift.property`` when non-`nil`.
    ///
    /// - Returns: Value defined by specified ``Server/Server/Take`` handler.
    open func request<R>(
        type:    Method,
        base:    URL? = nil,
        path:    String,
        cache:   URLRequest.CachePolicy = .useProtocolCachePolicy,
        timeout: TimeInterval? = nil,
        headers: [String: String] = [:],
        query:   [String: String] = [:],
        send:    Send = .void(),
        take:    Take<R>,
        catcher: Catcher.Type? = nil
    ) async throws -> R {
        // get config
        let config = await self.config
        
        // usage
        try await config.checkin()
        
        defer {
            Task {
                await config.checkout()
            }
        }
        
        let checkCancellation = {
            try Task.checkCancellation()
            try await config.checkInvalidation()
        }
        
        do {
            // assemble request
            let request: URLRequest =
                try await Tools.assemble(
                    config:  config,
                    type:    type,
                    base:    base,
                    path:    path,
                    cache:   cache,
                    timeout: timeout,
                    headers: headers,
                    query:   query,
                    send:    send,
                    take:    take
                )
            
            try await checkCancellation()
            
            // execute request
            let received: (data: Data, response: URLResponse) =
                try await config.session
                    .data(for: request)
            
            try await checkCancellation()
            
            // check response
            try await Tools.check(
                config:   config,
                take:     take,
                request:  request,
                response: received.response,
                data:     received.data
            )
            
            try await checkCancellation()
            
            // decode response data
            let decoded: R =
                try await Tools.decode(
                    config:   config,
                    take:     take,
                    request:  request,
                    response: received.response,
                    data:     received.data
                )
            
            try await checkCancellation()
            
            // return
            return decoded
        } catch {
            // try to handle error
            let mapped: R =
                try await Tools.map(
                    config:  config,
                    type:    type,
                    base:    base,
                    path:    path,
                    timeout: timeout,
                    headers: headers,
                    query:   query,
                    send:    send,
                    take:    take,
                    catcher: catcher,
                    error:   error
                )
            
            try await checkCancellation()
            
            // return
            return mapped
        }
    }
}
