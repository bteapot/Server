//
//  Server.swift
//
//
//  Created by Денис Либит on 11.02.2022.
//

import Foundation
import ReactiveSwift


/// An object that represents specific backend.
///
/// `Server` class provides coordination between changes in its configuration and session- and request-level nuances of specific backend service.
open class Server {
    
    // MARK: - Initialization
    
    /// Creates and returns a `Server` instance.
    ///
    /// - Parameter configurator: Reactive property with ``Config-swift.struct`` values.
    public init<P: PropertyProtocol>(_ configurator: P) where P.Value == Config {
        // set configuration and observe its changes
        self.config =
            Property(capturing: configurator)
        
        // discard old session
        self.config
            .producer
            .combinePrevious()
            .map { old, new in old.session }
            .startWithValues { session in
                session.invalidateAndCancel()
            }
    }
    
    // MARK: - Config
    
    /// Reactive prtoperty which value contains current ``Config-swift.struct``.
    public let config: Property<Config>
    
    // MARK: - Requests
    
    /// Execute arbitrary network request.
    ///
    /// - Parameter request: Custom `URLRequest`.
    /// - Returns: `SignalProducer` for request execution.
    open func raw(with request: URLRequest) -> SignalProducer<(Data, URLResponse), Error> {
        self.config.value.session.reactive
            .data(with: request)
            .take(until: self.config.signal.map(value: ()))
    }
    
    /// Request-level error mapping.
    ///
    /// Overrides config's ``Config-swift.struct/catcher-swift.property`` when non-`nil`
    /// This closure can return substitute value as request's result, rethrow received error or throw replacement error.
    public typealias Catcher<R> = (Error) throws -> R
    
    /// Perfom network request.
    ///
    /// - Parameters:
    ///   - type:    HTTP RESTful method.
    ///   - base:    Override config's ``Config-swift.struct/base`` URL when non-`nil`.
    ///   - path:    Request path.
    ///   - timeout: Override config's ``Config-swift.struct/timeout`` value when non-`nil`.
    ///   - headers: Request headers. Defaults to empty.
    ///   - query:   Rquest query. Defaults to empty.
    ///   - send:    Request's outgoing data handler. Defaults to ``Send/void()``.
    ///   - take:    Expected response data handler. Defaults to ``Take/void()``.
    ///   - catcher: Overrides config's ``Config-swift.struct/catcher-swift.property`` when non-`nil`.
    ///
    /// - Returns: `SignalProducer` for request processing.
    open func request<R>(
        type:    Method,
        base:    URL? = nil,
        path:    String,
        timeout: TimeInterval? = nil,
        headers: [String: String] = [:],
        query:   [String: String] = [:],
        send:    Send = .void(),
        take:    Take<R>,
        catcher: Catcher<R>? = nil
    ) -> SignalProducer<R, Error> {
        let config = self.config.value
        
        #if DEBUG
        let logging: Bool = config.reports.logging
        var start:   Date = .distantFuture
        
        let log = { (phase: String, message: String) in
            guard logging else {
                return
            }
            
            NSLog(
                "[server] %@ %@ %6.3f %@ %@",
                phase.padding(toLength: 6, withPad: " ", startingAt: 0),
                Date().timeIntervalSince(start) > 3 ? "•" : " ",
                Date().timeIntervalSince(start),
                path,
                message
            )
        }
        #endif
        
        return Tools.assemble(
            config:  config,
            type:    type,
            base:    base,
            path:    path,
            timeout: timeout,
            headers: headers,
            query:   query,
            send:    send,
            take:    take
        )
        .flatMap(.concat) { request in
            config.session.reactive
                .data(with: request)
                .map { (request, $0.1, $0.0) }
        }
        .flatMap(.concat) { request, response, data in
            Tools.check(
                config:   config,
                take:     take,
                request:  request,
                response: response,
                data:     data
            )
        }
        .flatMap(.concat) { request, response, data in
            Tools.decode(
                config:   config,
                take:     take,
                request:  request,
                response: response,
                data:     data
            )
        }
        .flatMapError { error in
            Tools.mapError(
                config:  config,
                catcher: catcher,
                error:   error
            )
        }
        .take(until: self.config.signal.map(value: ()))
        
        #if DEBUG
        .on(
            started: {
                start = Date()
                log("start", "")
            },
            failed: { error in
                log("error", error.localizedDescription)
            },
            interrupted: {
                log("cancel", "")
            },
            value: { value in
                log("done", "")
            }
        )
        #endif
    }
}
