//
//  Errors.swift
//
//
//  Created by Денис Либит on 11.02.2022.
//

import Foundation


extension Server {
    public struct Errors {}
}

// MARK: - Errors

extension Server.Errors {
    public struct BadURL {
        public let components: URLComponents
    }
    
    public struct BadHTTPResponse {
        public let request: URLRequest
        public let response: HTTPURLResponse
        public let data: Data
        public let description: String
    }
    
    public struct DecodingError {
        public let request: URLRequest
        public let response: URLResponse
        public let data: Data
        public let error: Error
    }
}

// MARK: - Conformances

extension Server.Errors {
    public enum UserInfoKey: String {
        case urlComponents = "ServerErrorKeyURLComponents"
        case request       = "ServerErrorKeyRequest"
        case response      = "ServerErrorKeyResponse"
        case responseData  = "ServerErrorKeyResponseData"
    }
}

// MARK: Bad URL

extension Server.Errors.BadURL: LocalizedError {
    public var errorDescription: String? {
        NSLocalizedString("Incorrect URL.", tableName: "Server", bundle: Bundle.main, comment: "Server error description.")
    }
}

extension Server.Errors.BadURL: CustomNSError {
    public static var errorDomain: String {
        "server"
    }
    public var errorCode: Int {
        URLError.badURL.rawValue
    }
    public var errorUserInfo: [String : Any] {
        [
            Server.Errors.UserInfoKey.urlComponents.rawValue: self.components,
        ]
    }
}

// MARK: Bad HTTP response

extension Server.Errors.BadHTTPResponse: LocalizedError {
    public var errorDescription: String? {
        String(
            format: NSLocalizedString("Server error: %@", tableName: "Server", bundle: Bundle.main, comment: "Server error description."),
            self.description
        )
    }
}

extension Server.Errors.BadHTTPResponse: CustomNSError {
    public static var errorDomain: String {
        "server"
    }
    public var errorCode: Int {
        self.response.statusCode
    }
    public var errorUserInfo: [String : Any] {
        var userInfo: [String: Any] = [:]
        userInfo[Server.Errors.UserInfoKey.request.rawValue]      = self.request
        userInfo[Server.Errors.UserInfoKey.response.rawValue]     = self.response
        userInfo[Server.Errors.UserInfoKey.responseData.rawValue] = self.data
        return userInfo
    }
}

// MARK: Decoding error

extension Server.Errors.DecodingError: LocalizedError {
    public var errorDescription: String? {
        String(
            format: NSLocalizedString("Server provided incorrect data: %@", tableName: "Server", bundle: Bundle.main, comment: "Server error description."),
            self.error.localizedDescription
        )
    }
}

extension Server.Errors.DecodingError: CustomNSError {
    public static var errorDomain: String {
        "server"
    }
    public var errorCode: Int {
        (self.error as NSError).code
    }
    public var errorUserInfo: [String : Any] {
        var userInfo = (error as NSError).userInfo
        userInfo[Server.Errors.UserInfoKey.request.rawValue]      = self.request
        userInfo[Server.Errors.UserInfoKey.response.rawValue]     = self.response
        userInfo[Server.Errors.UserInfoKey.responseData.rawValue] = self.data
        return userInfo
    }
}
