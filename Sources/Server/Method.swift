//
//  Method.swift
//  Server
//
//  Created by Денис Либит on 11.02.2022.
//

extension Server {
    public enum Method: String, Sendable {
        case delete = "DELETE"
        case get    = "GET"
        case patch  = "PATCH"
        case post   = "POST"
        case put    = "PUT"
    }
}
