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
    
    public enum StubbingBehaviour {
        case Never
        case Immediately
        case Delayed(seconds: Int)
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

public class APIProvider<Target : APITarget> {
    public typealias EndpointClosure = (Target) -> (APIEndpoint<Target>)
    public typealias RequestClosure = (endpoint: APIEndpoint<Target>) -> (NSURLRequest)
    public typealias StubClosure = (Target) -> (Nirvash.StubbingBehaviour)
    
    public let endpointClosure: EndpointClosure
    public let requestClosure: RequestClosure
    public let stubClosure: StubClosure
    public let stubScheduler: DateSchedulerType
    
    public init(endpointClosure: EndpointClosure = APIProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = APIProvider.DefaultEndpointResolution,
        stubClosure: StubClosure = APIProvider.NeverStub,
        stubScheduler: DateSchedulerType = QueueScheduler()) {
            
        self.endpointClosure = endpointClosure
        self.requestClosure = requestClosure
        self.stubClosure = stubClosure
        self.stubScheduler = stubScheduler
    }
    
    @warn_unused_result(message="Did you forget to call `start` om the producer?")
    public func request(target: Target) -> SignalProducer<(NSData, NSURLResponse?), NSError> {
        switch stubClosure(target) {
        case .Never:
            return sendRequest(target)
        case .Immediately, .Delayed(seconds: _):
            return stubRequest(target )
        }
    }
    
    public func sendRequest(target: Target) -> SignalProducer<(NSData, NSURLResponse?), NSError> {
        return SignalProducer<Target, NSError>(value: target)
            .map(endpointClosure)
            .map(requestClosure)
            .flatMap(.Latest) { request in
                return NSURLSession.sharedSession().rac_dataWithRequest(request)
            }
            .map { data, response in
                return (data, response)
            }
    }
    
    public func stubRequest(target: Target) -> SignalProducer<(NSData, NSURLResponse?), NSError> {
        let producer: SignalProducer<(NSData, NSURLResponse?), NSError> = SignalProducer(value: target)
            .map { ($0.sampleData, nil) }
        
        switch stubClosure(target) {
        case .Never:
            fatalError("Tried to stub target that should never be stubbed")
        case .Immediately:
            return producer
        case .Delayed(seconds: let seconds):
            return producer.delay(NSTimeInterval(seconds), onScheduler: stubScheduler)
        }
    }
}

// MARK: - Defaults

extension APIProvider {
    public class func DefaultEndpointMapping(target: Target) -> APIEndpoint<Target> {
        let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
        return APIEndpoint(URL: url, method: target.method, parameters: target.parameters, parameterEncoding: Nirvash.ParameterEncoding.URL, httpHeaderFields: nil)
    }
    
    public class func DefaultEndpointResolution(endpoint: APIEndpoint<Target>) -> NSURLRequest {
        return endpoint.urlRequest
    }
}

// MARK: - Stubbing

extension APIProvider {
    public class func NeverStub(_: Target) -> Nirvash.StubbingBehaviour {
        return .Never
    }
    
    public class func ImmediatelyStub(_: Target) -> Nirvash.StubbingBehaviour {
        return .Immediately
    }
    
    public class func DelayedStub(seconds: Int) -> (_: Target) -> Nirvash.StubbingBehaviour {
        return { _ in .Delayed(seconds: seconds) }
    }
}
