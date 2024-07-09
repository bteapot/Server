//
//  Catcher.swift
//
//
//  Created by Денис Либит on 02.07.2024.
//

import Foundation


public protocol Catcher {
    static func `catch`<R>(
        type:    Server.Method,
        base:    URL?,
        path:    String,
        timeout: TimeInterval?,
        headers: [String: String],
        query:   [String: String],
        send:    Server.Send,
        take:    Server.Take<R>,
        error:   Error
    ) async throws -> R
}

extension Server.Config {
    /// Default error handling, just throws provided error.
    public enum DefaultCatcher: Catcher {
        public static func `catch`<R>(
            type:    Server.Method,
            base:    URL?,
            path:    String,
            timeout: TimeInterval?,
            headers: [String : String],
            query:   [String : String],
            send:    Server.Send,
            take:    Server.Take<R>,
            error:   Error
        ) async throws -> R {
            throw error
        }
    }
}


