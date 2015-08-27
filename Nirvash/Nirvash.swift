//
//  Nirvash.swift
//  Nirvash
//
//  Created by Rhys Powell on 9/08/2015.
//  Copyright © 2015 Rhys Powell. All rights reserved.
//

import Foundation
import Alamofire
import ReactiveCocoa

/// Solely used for namespacing
public struct Nirvash {
    
    /// HTTP Methods
    public enum Method {
        case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT
        
        func method() -> Alamofire.Method {
            switch self {
            case .GET:
                return .GET
            case .POST:
                return .POST
            case .PUT:
                return .PUT
            case .DELETE:
                return .DELETE
            case .HEAD:
                return .HEAD
            case .OPTIONS:
                return .OPTIONS
            case PATCH:
                return .PATCH
            case TRACE:
                return .TRACE
            case .CONNECT:
                return .CONNECT
            }
        }
    }
    
    /// Choice of parameter encoding.
    public enum ParameterEncoding {
        case URL
        case JSON
        case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
        case Custom((URLRequestConvertible, [String: AnyObject]?) -> (NSMutableURLRequest, NSError?))
        
        func parameterEncoding() -> Alamofire.ParameterEncoding {
            switch self {
            case .URL:
                return .URL
            case .JSON:
                return .JSON
            case .PropertyList(let format, let options):
                return .PropertyList(format, options)
            case .Custom(let closure):
                return .Custom(closure)
            }
        }
    }
}

public protocol APITarget {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: Nirvash.Method { get }
    var parameters: [String: AnyObject]? { get }
    var sampleData: NSData { get }
}

public struct APIEndpoint<T> {
    public let URL: String
    public let method: Nirvash.Method
    public let parameters: [String: AnyObject]?
    public let parameterEncoding: Nirvash.ParameterEncoding
    public let httpHeaderFields: [String: String]?
    
    public var urlRequest: NSURLRequest {
        let request = NSMutableURLRequest(URL: NSURL(string: URL)!)
        request.HTTPMethod = method.method().rawValue
        request.allHTTPHeaderFields = httpHeaderFields
        return parameterEncoding.parameterEncoding().encode(request, parameters: parameters).0
    }
}

public class APIProvider<T : APITarget> {
    public typealias ReactiveAPIEndpointClosure = (T) -> (APIEndpoint<T>)
    public typealias ReactiveAPIEndpointResolution = (endpoint: APIEndpoint<T>) -> (NSURLRequest)
    
    public let endpointClosure: ReactiveAPIEndpointClosure
    public let endpointResolver: ReactiveAPIEndpointResolution
    
    public init(endpointClosure: ReactiveAPIEndpointClosure = APIProvider.DefaultEndpointMapping, endpointResolver: ReactiveAPIEndpointResolution = APIProvider.DefaultEndpointResolution) {
        self.endpointClosure = endpointClosure
        self.endpointResolver = endpointResolver
    }
    
    public func request(target: T) -> SignalProducer<(NSData, NSURLResponse), NSError> {
        return SignalProducer<T, NSError>(value: target)
            .map(endpointClosure)
            .map(endpointResolver)
            .flatMap(.Latest) { request in
                return NSURLSession.sharedSession().rac_dataWithRequest(request)
            }
    }
    
    public class func DefaultEndpointMapping(target: T) -> APIEndpoint<T> {
        let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
        return APIEndpoint(URL: url, method: target.method, parameters: target.parameters, parameterEncoding: Nirvash.ParameterEncoding.URL, httpHeaderFields: nil)
    }
    
    public class func DefaultEndpointResolution(endpoint: APIEndpoint<T>) -> NSURLRequest {
        return endpoint.urlRequest
    }
}
