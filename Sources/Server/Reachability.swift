//
//  Reachability.swift
//
//
//  Created by Денис Либит on 11.02.2022.
//

import Foundation
import Network
import ReactiveSwift


extension Server {
    /// Reactive property which value indicates current network reachability status.
    public static let reachable =
        Property<Bool>(
            initial: true,
            then: SignalProducer { observer, lifetime in
                Server.monitor.pathUpdateHandler = { path in
                    observer.send(value: path.status == .satisfied)
                }
                Server.monitor.start(queue: DispatchQueue.main)
            }
        )
}

private extension Server {
    static let monitor = NWPathMonitor()
}
