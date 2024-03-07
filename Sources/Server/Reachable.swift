//
//  Reachable.swift
//  Server
//
//  Created by Денис Либит on 11.02.2022.
//

import SwiftUI
import Network


extension Server {
    /// Network state monitoring for SwiftUI.
    ///
    /// Usage:
    ///
    ///     @Server.Reachable
    ///     private var isReachable: Bool
    @propertyWrapper
    public struct Reachable: DynamicProperty, @unchecked Sendable {
        
        public init() {
            _path = State(wrappedValue: self.monitor.currentPath)
        }
        
        public var wrappedValue: Bool {
            self.satisfied
        }
        
        public var projectedValue: NWPath {
            self.path
        }
        
        public func update() {
            if self.started {
                return
            }
            
            Task { @MainActor in
                if self.started {
                    return
                }
                
                self.started = true
                
                self.monitor.pathUpdateHandler = { path in
                    self.path = path
                    self.satisfied = path.status == .satisfied
                }
                
                self.monitor.start(queue: .main)
            }
        }
        
        @State
        private var path: NWPath
        
        @State
        private var satisfied: Bool = false
        
        @State
        private var started: Bool = false
        
        private let monitor = NWPathMonitor()
    }
}
