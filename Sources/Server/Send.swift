//
//  Send.swift
//  Server
//
//  Created by Денис Либит on 11.02.2022.
//

import Foundation


// MARK: - Send

extension Server {
    public struct Send: Sendable {
        
        // MARK: - Creating
        
        /// No request data.
        ///
        /// This option sets `body` to `nil` and adds no headers.
        public static func void() -> Send {
            .init { config in
                return (body: nil, headers: nil)
            }
        }
        
        /// Raw request data.
        ///
        /// This option sets request's body to `data`, and adds `"Content-Type"` header.
        ///
        /// - Parameters:
        ///   - data: Request's `body` data.
        ///   - contentType: Value for request's `"Content-Type"` header. Defaults to `"application/octet-stream"`.
        public static func data(_ data: Data, _ contentType: String = "application/octet-stream") -> Send {
            .init { config in
                return (data, ["Content-Type": contentType])
            }
        }
        
        /// JSON request data.
        ///
        /// This option encodes provided value using config's ``Server/Server/Config-swift.struct/encoder`` and adds `"Content-Type"` header with `"application/json"` value.
        ///
        /// - Parameters:
        ///   - encodable: Value conforming to `Encodable` protocol.
        public static func json<T: Encodable>(_ encodable: T) -> Send {
            .init { config in
                (try config.encoder.encode(encodable), ["Content-Type": "application/json"])
            }
        }
        
        /// Text form request data.
        ///
        /// This option encodes provided value pairs and adds `"Content-Type"` header with `"application/x-www-form-urlencoded"` value.
        ///
        /// - Parameters:
        ///   - items: Form's key-value pairs.
        public static func form(_ items: [String: String]) -> Send {
            .init { config in
                var components = URLComponents()
                components.queryItems = items.map { URLQueryItem(name: $0.key, value: $0.value) }
                
                if let data = components.query?.data(using: .utf8) {
                    return (
                        body: data,
                        headers: [
                            "Content-Type":   "application/x-www-form-urlencoded",
                            "Content-Length": String(data.count),
                        ]
                    )
                } else {
                    return (body: nil, headers: nil)
                }
            }
        }
        
        /// Multipart form request data.
        ///
        /// This option encodes provided parts and adds `"Content-Type"` header with `"multipart/form-data; boundary=<...>"` value.
        ///
        /// - Parameters:
        ///   - parts: Form parts.
        public static func multipart(_ parts: [Part]) -> Send {
            .init { config in
                // content separator
                let boundary = UUID().uuidString
                
                // caret return + line feed
                let crlf = "\r\n"
                
                // assemble data
                var body = Data()
                
                // parts
                for part in parts {
                    // opening delimiter
                    body.append("--" + boundary)
                    body.append(crlf)
                    
                    // disposition
                    body.append("Content-Disposition: form-data; name=\"\(part.name)\"")
                    
                    // filename, if any
                    if let filename = part.filename {
                        body.append("; filename=\"\(filename)\"")
                    }
                    
                    body.append(crlf)
                    
                    // content type
                    if let mimeType = part.mimeType {
                        body.append("Content-Type: \(mimeType)")
                        body.append(crlf)
                    }
                    
                    body.append(crlf)
                    
                    // content body
                    if let data = part.data {
                        body.append(data)
                    }
                    
                    body.append(crlf)
                }
                
                // closing delimiter
                body.append("--\(boundary)--")
                body.append(crlf)
                body.append(crlf)
                
                // done
                return (
                    body: body,
                    headers: [
                        "Content-Type":   "multipart/form-data; boundary=\(boundary)",
                        "Content-Length": String(body.count),
                    ]
                )
            }
        }
        
        /// Custom provider for request data.
        ///
        /// - Parameters:
        ///   - encode: Closure that takes current ``Server/Server/Config-swift.struct`` and returns request's body and headers.
        public static func custom(_ encode: @escaping Encode) -> Send {
            .init(encode)
        }
        
        // MARK: - Types
        
        /// Closure that takes current ``Server/Server/Config-swift.struct`` and returns request's body and headers.
        public typealias Encode = @Sendable (Config) async throws -> (body: Data?, headers: [String: String]?)
        
        // MARK: - Properties
        
        let encode: Encode
        
        // MARK: - Initialization
        
        private init(_ encode: @escaping Encode) {
            self.encode = encode
        }
    }
}

// MARK: - Multipart form

extension Server.Send {
    /// Part of the multipart form.
    ///
    /// This structure provides name and optional data, file name and mime type for encoding form's part.
    public struct Part {
        let data: Data?
        let name: String
        let filename: String?
        let mimeType: String?
        
        private init(data: Data?, name: String, filename: String? = nil, mimeType: String? = nil) {
            self.data = data
            self.name = name
            self.filename = filename
            self.mimeType = mimeType
        }
    }
}
        
extension Server.Send.Part {
    public static func data(_ data: Data?, name: String, filename: String? = nil, mimeType: String? = nil) -> Server.Send.Part {
        .init(
            data: data,
            name: name,
            filename: filename,
            mimeType: mimeType
        )
    }
    
    public static func text(_ text: String?, name: String, filename: String? = nil) -> Server.Send.Part {
        .init(
            data: text?.data(using: .utf8),
            name: name,
            filename: filename,
            mimeType: "text/plain"
        )
    }
}

// MARK: - iOS-specific

#if os(iOS)
import UIKit

extension Server.Send.Part {
    public static func jpeg(_ image: UIImage?, max: CGSize? = nil, compression: CGFloat = 0.75, name: String, filename: String? = nil) -> Server.Send.Part {
        .init(
            data: image?
                .with(max: max)
                .jpegData(compressionQuality: compression),
            name: name,
            filename: filename,
            mimeType: "image/jpeg"
        )
    }
    
    public static func png(_ image: UIImage?, max: CGSize? = nil, name: String, filename: String? = nil) -> Server.Send.Part {
        .init(
            data: image?
                .with(max: max)
                .pngData(),
            name: name,
            filename: filename,
            mimeType: "image/png"
        )
    }
}
#endif

// MARK: - macOS-specific

#if os(macOS)
import AppKit

extension Server.Send.Part {
    public static func jpeg(_ image: NSImage?, max: NSSize? = nil, compression: CGFloat = 0.75, name: String, filename: String? = nil) -> Server.Send.Part {
        .init(
            data: image?
                .with(max: max)
                .representations
                .lazy
                .compactMap { $0 as? NSBitmapImageRep }
                .first?
                .representation(
                    using: .jpeg,
                    properties: [
                        .compressionFactor: compression,
                    ]
                ),
            name: name,
            filename: filename,
            mimeType: "image/jpeg"
        )
    }
    
    public static func png(_ image: NSImage?, max: NSSize? = nil, name: String, filename: String? = nil) -> Server.Send.Part {
        .init(
            data: image?
                .with(max: max)
                .representations
                .lazy
                .compactMap { $0 as? NSBitmapImageRep }
                .first?
                .representation(
                    using: .png,
                    properties: [:]
                ),
            name: name,
            filename: filename,
            mimeType: "image/png"
        )
    }
}
#endif

// MARK: - Tools

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}

#if os(iOS)
private extension UIImage {
    func with(max: CGSize? = nil) -> UIImage {
        let size =
            CGSize(
                width:  self.size.width  * self.scale,
                height: self.size.height * self.scale
            )
        
        let scale: CGFloat
        
        if  let max = max,
            size.width  > 0,
            size.height > 0
        {
            let ratioW = max.width  / size.width
            let ratioH = max.height / size.height
            scale = ratioW < 1 || ratioH < 1 ? min(ratioW, ratioH) : 1
        } else {
            scale = 1
        }
        
        guard scale < 1 else {
            return self
        }
        
        let newSize =
            CGSize(
                width:  size.width  * scale,
                height: size.height * scale
            )
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        
        return image
    }
}
#endif

#if os(macOS)
private extension NSImage {
    func with(max: NSSize? = nil) -> NSImage {
        let size = self.size
        
        let scale: CGFloat
        
        if  let max = max,
            size.width  > 0,
            size.height > 0
        {
            let ratioW = max.width  / size.width
            let ratioH = max.height / size.height
            scale = ratioW < 1 || ratioH < 1 ? min(ratioW, ratioH) : 1
        } else {
            scale = 1
        }
        
        guard scale < 1 else {
            return self
        }
        
        let newSize =
            NSSize(
                width:  size.width  * scale,
                height: size.height * scale
            )
        
        guard
            let representation =
                NSBitmapImageRep(
                    bitmapDataPlanes: nil,
                    pixelsWide: Int(newSize.width),
                    pixelsHigh: Int(newSize.height),
                    bitsPerSample: 8,
                    samplesPerPixel: 4,
                    hasAlpha: true,
                    isPlanar: false,
                    colorSpaceName: .calibratedRGB,
                    bytesPerRow: 0,
                    bitsPerPixel: 0
                )
        else {
            return self
        }
        
        representation.size = newSize
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)
        self.draw(in: NSRect(origin: .zero, size: newSize), from: .zero, operation: .copy, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()
        
        let image = NSImage(size: newSize)
        image.addRepresentation(representation)
        return image
    }
}
#endif
