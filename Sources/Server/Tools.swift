//
//  Tools.swift
//  Server
//
//  Created by Денис Либит on 11.02.2022.
//

import Foundation


extension Server {
    
    /// Methods for creation of requests, processing of responses and handling of errors.
    public struct Tools {
        
        // MARK: Prepare request
        
        /// Construct an `URLRequest` from provided parameters.
        public static func assemble<R>(
            config:  Config,
            type:    Method,
            base:    URL?,
            path:    String,
            timeout: TimeInterval?,
            headers: [String: String],
            query:   [String: String],
            send:    Send,
            take:    Take<R>
        ) async throws -> URLRequest {
            // base url
            let baseURL = base ?? config.base
            
            // target url
            let targetURL: URL = {
                // path is empty?
                if path.isEmpty {
                    // unusual, but ok
                    return baseURL
                }
                
                // base url's path is empty or is root, and request path starts from slash?
                if ["", "/"].contains(baseURL.path), path.first == "/" {
                    // replace path in target url
                    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
                    components?.path = path
                    
                    if let url = components?.url {
                        return url
                    }
                }
                
                // append path to base url
                return baseURL.appendingPathComponent(path)
            }()
            
            // add query items
            guard var components = URLComponents(url: targetURL, resolvingAgainstBaseURL: false) else {
                #if DEBUG
                NSLog("server error extending URL with \(path)")
                #endif
                
                throw Server.Errors.BadURL(
                    components: {
                        var components = URLComponents()
                        components.path = path
                        return components
                    }()
                )
            }
            
            components.queryItems =
                config.query
                    .merging(query, uniquingKeysWith: { $1 })
                    .map(URLQueryItem.init)
                    .nilIfEmpty
            
            // compose final url
            guard let url = components.url else {
                #if DEBUG
                NSLog("server error assembling URL \(components)")
                #endif
                
                throw Server.Errors.BadURL(components: components)
            }
            
            // encode body
            let encoded: (body: Data?, headers: [String : String]?)
            
            do {
                encoded = try await send.encode(config)
            } catch {
                #if DEBUG
                NSLog("server error: \(error) encoding payload: \(send)")
                #endif
                
                throw error
            }
            
            // prepare headers: config + request + encoded + accepted
            let headers: [String: String]? =
                config.headers
                    .mapValues(Optional.init)
                    .merging(headers) { $1 }
                    .merging(encoded.headers) { $1 }
                    .merging(["Accept": take.mimeType]) { $1 }
                    .compactMapValues({ $0 })
                    .nilIfEmpty
            
            // assemble request
            var request = URLRequest(url: url)
            
            request.cachePolicy         = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval     = timeout ?? config.timeout
            request.httpMethod          = type.rawValue
            request.allHTTPHeaderFields = headers
            request.httpBody            = encoded.body
            
            // request configuration
            config.request?(&request)
            
            // return
            return request
        }
        
        // MARK: - Check response
        
        /// Check `URLResponse` for validity.
        public static func check<R>(
            config:   Config,
            take:     Take<R>,
            request:  URLRequest,
            response: URLResponse,
            data:     Data
        ) async throws {
            // check is defined by config or overriden by expected response body type
            let check = take.check ?? config.response.check
            try await check(config, request, response, data)
        }
        
        // MARK: - Decode response data
        
        /// Decode `URLResponse`.
        public static func decode<R>(
            config:   Config,
            take:     Take<R>,
            request:  URLRequest,
            response: URLResponse,
            data:     Data
        ) async throws -> R {
            do {
                return try await take.decode(config, data, response)
            } catch {
                #if DEBUG
                Self.report(config: config, request: request, response: response, data: data, error: error)
                #endif
                
                throw Server.Errors.DecodingError(
                    request: request,
                    response: response,
                    data: data,
                    error: error
                )
            }
        }
        
        // MARK: - Map or skip errors
        
        /// Map error or cancel request.
        public static func map<R>(
            config: Config,
            catch:  Catcher<R>?,
            error:  Error
        ) async throws -> R {
            // error handling defined by request?
            if let `catch` {
                // return mapped value or throw an error
                return try await `catch`(error)
            }
            
            // error mapping defined by config?
            if let catcher = config.catcher {
                // error is handled?
                if let mapped = catcher(error) {
                    // throw mapped error
                    throw mapped
                } else {
                    // ignore error
                    throw CancellationError()
                }
            }
            
            // standard error handling
            switch error {
                case URLError.cancelled:
                    // request cancelled
                    throw CancellationError()
                    
                default:
                    // throw original error
                    throw error
            }
        }
    }
}

// MARK: - Default response check

private extension Server.Config.ResponseHandler {
    var check: Check {
        switch self {
            case .standard(let describe):
                return { config, request, response, data in
                    // standard response handling
                    // it's HTTP response, and response code is not very good?
                    if  let response = response as? HTTPURLResponse,
                        (200..<300).contains(response.statusCode) == false
                    {
                        #if DEBUG
                        NSLog(String(
                            format: "server error %d: [%@],\nrequest: %@\nresponse: %@\ndata: %@",
                            response.statusCode,
                            HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
                            String(describing: request),
                            {
                                if let body = request.httpBody {
                                    return String((String(data: body, encoding: .utf8) ?? "error"))
                                } else {
                                    return "<empty>"
                                }
                            }(),
                            String(describing: response).removingPercentEncoding ?? "<error>",
                            String((String(data: data, encoding: .utf8) ?? "error"))
                        ))
                        #endif
                        
                        // error description
                        let message: String =
                            describe?(config, request, response, data) ?? {
                                // standard error description
                                var message = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                                
                                // has some text from server?
                                if let info = String(data: data, encoding: .utf8) {
                                    message.append(": " + info)
                                }
                                
                                return message
                            }()
                        
                        // report error
                        throw Server.Errors.BadHTTPResponse(
                            request: request,
                            response: response,
                            data: data,
                            description: message
                        )
                    }
                }
                
            case .handle(let handler):
                // custom response handling
                return handler
        }
    }
}

// MARK: - Tools

private extension Collection {
    var nilIfEmpty: Self? {
        if self.isEmpty {
            return nil
        } else {
            return self
        }
    }
}

private extension Dictionary {
    func merging(_ other: [Key : Value]?, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> [Key : Value] {
        if let other = other {
            return try self.merging(other, uniquingKeysWith: combine)
        } else {
            return self
        }
    }
    
    init(dictionaryLiteral elements: (Key, Optional<Value>)...) {
        var dict: [Key: Value] = [:]
        
        for item in elements {
            if let value = item.1 {
                dict[item.0] = value
            }
        }
        
        self = dict
    }
}

#if DEBUG

// MARK: - Debug

private extension Server.Tools {
    static func report(
        config:   Server.Config,
        request:  URLRequest,
        response: URLResponse,
        data:     Data,
        error:    Error
    ) {
        if let error = error as? DecodingError {
            let string = String(data: data, encoding: .utf8) ?? "nil"
            let prefix = "server error decoding [\(response.url?.absoluteString ?? "")]: \(error.localizedDescription)"
            
            switch error {
                case let .dataCorrupted(context):
                    NSLog(prefix + " [\(context)]\n\n\(string)")
                case let .keyNotFound(key, context):
                    NSLog(prefix + " [\(key), \(context)\n\n\(string)]")
                case let .typeMismatch(type, context):
                    NSLog(prefix + " [\(type), \(context)\n\n\(string)]")
                case let .valueNotFound(type, context):
                    NSLog(prefix + " [\(type), \(context)\n\n\(string)]")
                @unknown default:
                    NSLog(prefix)
            }
        } else {
            NSLog("server error decoding [\(response.url?.absoluteString ?? "")]: \(error.localizedDescription)\n\n\(String(data: data, encoding: .utf8) ?? "nil")")
        }
        
        if let folder = config.reports.url {
            var filename = String(Date().timeIntervalSince1970)
            
            if let urlString = request.url?.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                filename += "-" + urlString
            }
            
            let file =
                folder
                    .appendingPathComponent(filename)
                    .appendingPathExtension(self.extensions[response.mimeType] ?? "bin")
            
            try? data.write(to: file)
        }
    }
    
    static let extensions: [String?: String] = [
        "application/epub+zip": "epub",
        "application/gzip": "gz",
        "application/java-archive": "jar",
        "application/json": "json",
        "application/ld+json": "jsonld",
        "application/msword": "doc",
        "application/octet-stream": "bin",
        "application/ogg": "ogx",
        "application/pdf": "pdf",
        "application/php": "php",
        "application/rtf": "rtf",
        "application/vnd.amazon.ebook": "azw",
        "application/vnd.apple.installer+xml": "mpkg",
        "application/vnd.mozilla.xul+xml": "xul",
        "application/vnd.ms-excel": "xls",
        "application/vnd.ms-fontobject": "eot",
        "application/vnd.ms-powerpoint": "ppt",
        "application/vnd.oasis.opendocument.presentation": "odp",
        "application/vnd.oasis.opendocument.spreadsheet": "ods",
        "application/vnd.oasis.opendocument.text": "odt",
        "application/vnd.openxmlformats-officedocument.presentationml.presentation": "pptx",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xlsx",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
        "application/vnd.rar": "rar",
        "application/vnd.visio": "vsd",
        "application/x-7z-compressed": "7z",
        "application/x-abiword": "abw",
        "application/x-bzip": "bz",
        "application/x-bzip2": "bz2",
        "application/x-csh": "csh",
        "application/x-freearc": "arc",
        "application/x-sh": "sh",
        "application/x-shockwave-flash": "swf",
        "application/x-tar": "tar",
        "application/xhtml+xml": "xhtml",
        "application/xml": "xml",
        "application/zip": "zip",
        "audio/3gpp": "3gp",
        "audio/3gpp2": "3g2",
        "audio/aac": "aac",
        "audio/midi": "midi",
        "audio/mpeg": "mp3",
        "audio/ogg": "oga",
        "audio/opus": "opus",
        "audio/wav": "wav",
        "audio/webm": "weba",
        "audio/x-midi": "midi",
        "font/otf": "otf",
        "font/ttf": "ttf",
        "font/woff": "woff",
        "font/woff2": "woff2",
        "image/bmp": "bmp",
        "image/gif": "gif",
        "image/jpeg": "jpg",
        "image/png": "png",
        "image/svg+xml": "svg",
        "image/tiff": "tiff",
        "image/vnd.microsoft.icon": "ico",
        "image/webp": "webp",
        "text/calendar": "ics",
        "text/css": "css",
        "text/csv": "csv",
        "text/html": "html",
        "text/javascript": "js",
        "text/plain": "txt",
        "text/xml": "xml",
        "video/3gpp": "3gp",
        "video/3gpp2": "3g2",
        "video/mp2t": "ts",
        "video/mpeg": "mpeg",
        "video/ogg": "ogv",
        "video/webm": "webm",
        "video/x-msvideo": "avi",
    ]
}
#endif
