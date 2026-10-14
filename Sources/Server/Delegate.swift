//
//  Delegate.swift
//  Server
//
//  Created by Денис Либит on 11.02.2022.
//

import Foundation


extension Server {
    internal final class Delegate: NSObject, URLSessionTaskDelegate {
        
        // MARK: - Initialization
        
        required init(with challenge: Config.ChallengeHandler, _ redirect: Config.RedirectHandler) {
            self.challenge = challenge
            self.redirect = redirect
            
            super.init()
        }
        
        // MARK: - Properties
        
        private let challenge: Config.ChallengeHandler
        private let redirect:  Config.RedirectHandler
        
        // MARK: - Session level
        
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            self.challenge.handle(task: nil, challenge: challenge, completion: completionHandler)
        }
        
        // MARK: - Task level
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            self.challenge.handle(task: task, challenge: challenge, completion: completionHandler)
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            self.redirect.handle(task: task, response: response, request: request, completion: completionHandler)
        }
    }
}

// MARK: - Tools

private extension Server.Config.ChallengeHandler {
    func handle(
        task: URLSessionTask?,
        challenge: URLAuthenticationChallenge,
        completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        switch self {
            case .standard:
                completion(.performDefaultHandling, nil)
                
            case .handle(let handler):
                handler(task, challenge, completion)
        }
    }
}

private extension Server.Config.RedirectHandler {
    func handle(
        task: URLSessionTask,
        response: HTTPURLResponse,
        request: URLRequest,
        completion: @escaping (URLRequest?) -> Void
    ) {
        switch self {
            case .standard:
                completion(request)
                
            case .handle(let handler):
                handler(task, response, request, completion)
        }
    }
}
