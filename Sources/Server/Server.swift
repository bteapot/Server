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
    /// - Parameter configurator: Reactive property with ``Config`` values.
    public init<P: PropertyProtocol>(_ configurator: P) where P.Value == Config {
        // set configuration and observe its changes
        self.assets =
            Property(capturing: configurator.map { config in
                Assets(
                    config: config,
                    session: URLSession(
                        configuration: config.session.configuration,
                        delegate:      Delegate(with: config),
                        delegateQueue: nil
                    )
                )
            })
        
        // discard old session
        self.assets
            .producer
            .combinePrevious()
            .map { old, new in old.session }
            .startWithValues { session in
                session.invalidateAndCancel()
            }
    }
    
    // MARK: - Assets
    
    public typealias Assets = (config: Config, session: URLSession)
    
    /// Reactive prtoperty which value contains current ``Config`` and `URLSession`.
    public let assets: Property<Assets>
    
    // MARK: - Requests
    
    /// Execute arbitrary network request.
    ///
    /// - Parameter request: Custom `URLRequest`.
    /// - Returns: `SignalProducer` for request execution.
    open func raw(with request: URLRequest) -> SignalProducer<(Data, URLResponse), Error> {
        self.assets.value.session.reactive
            .data(with: request)
            .take(until: self.assets.signal.map(value: ()))
    }
    
    /// Perfom network request.
    ///
    /// - Parameters:
    ///   - type:    HTTP RESTful method.
    ///   - base:    Override ``Config/base`` URL when non-`nil`.
    ///   - path:    Request path.
    ///   - timeout: Override ``Config/timeout`` value when non-`nil`.
    ///   - headers: Request headers. Defaults to empty.
    ///   - query:   Rquest query. Defaults to empty.
    ///   - send:    Request's outgoing data handler. Defaults to ``Send/void()``.
    ///   - take:    Expected response data handler. Defaults to ``Take/void()``.
    ///   - catch:   Override ``Config/catcher-swift.property`` when non-`nil`.
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
        catch:   Config.Catcher? = nil
    ) -> SignalProducer<R, Error> {
        let (config, session) = self.assets.value
        
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
            session.reactive
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
                config: config,
                catch:  `catch`,
                error:  error
            )
        }
        .take(until: self.assets.signal.map(value: ()))
    }
}
