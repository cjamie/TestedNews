//
//  HTTPClient.swift
//  MVCBasic
//
//  Created by Jamie Chu on 5/9/21.
//

import Foundation

protocol HTTPClient {
    typealias RawResponse = (Data?, URLResponse?, Error?)

    func get(from request: URLRequest, rawResponse: @escaping (RawResponse)-> Void)
}

protocol URLSessionProtocol {
    func dataTaskk(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
}

protocol URLSessionDataTaskProtocol {
    func resume()
}


// TODO: - move back into tests
final class HTTPClientSpy: HTTPClient {

    private(set) var calledGet: [Get] = []

    struct Get: Equatable {
        let request: URLRequest
        let rawResponse: (RawResponse) -> Void

        // MARK: - Equatable

        static func == (lhs: Get, rhs: Get) -> Bool {
            lhs.request == rhs.request
        }
    }

    func get(from request: URLRequest, rawResponse: @escaping (RawResponse)-> Void) {
        calledGet.append(.init(request: request, rawResponse: rawResponse))
    }


    func completeWithResponse(
        data: Data? = nil,
        response: URLResponse? = nil,
        error: Error? = nil,
        at index: Int = 0
    ) {
        calledGet.map { $0.rawResponse }[index]((data, response, error))
    }

}


final class HTTPClientImpl: HTTPClient {
    private let urlSession: URLSessionProtocol

    init(urlSessionProtocol: URLSessionProtocol) {
        self.urlSession = urlSessionProtocol
    }

    func get(
        from request: URLRequest,
        rawResponse: @escaping (RawResponse)-> Void
    ) {
        urlSession
            .dataTaskk(with: request) { rawResponse(($0, $1, $2)) }
            .resume()
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

extension URLSession: URLSessionProtocol {
    func dataTaskk(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        dataTask(with: request, completionHandler: completionHandler)
    }

//    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
//        self.data
//    }
}

