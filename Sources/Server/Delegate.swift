//
//  Delegate.swift
//
//
//  Created by Денис Либит on 11.02.2022.
//

import Foundation


extension Server {
    internal final class Delegate: NSObject, URLSessionTaskDelegate {
        
        // MARK: - Initialization
        
        required init(with config: Config) {
            self.config = config
            super.init()
        }
        
        // MARK: - Properties
        
        private let config: Config
        
        // MARK: - Session level
        
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            self.handle(task: nil, challenge: challenge, completion: completionHandler)
        }
        
        // MARK: - Task level
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            self.handle(task: task, challenge: challenge, completion: completionHandler)
        }
        
        // MARK: - Tools
        
        private func handle(
            task: URLSessionTask?,
            challenge: URLAuthenticationChallenge,
            completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            switch self.config.challenge {
                case .standard:
                    completion(.performDefaultHandling, nil)
                    
                case .handle(let handler):
                    let (disposition, credential) = handler(task, challenge)
                    completion(disposition, credential)
            }
        }
    }
}
