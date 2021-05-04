//
//  HTTPClientImplTestCase.swift
//  MVCBasicTests
//
//  Created by Jamie Chu on 5/2/21.
//

import XCTest
@testable import MVCBasic

class HTTPClientImplTestCase: XCTestCase {

    func test_get_shouldCallDataTask() {
        let (sut, spy) = makeSUT()

        let request = anyURLRequest()
        sut.get(from: request) { _ in }

        XCTAssertEqual(spy.calledDataTasks.map { $0.request }, [ request ])
    }

    func test_get_shouldResumeURLSessionVendedTask() {
        // GIVEN
        let vendedDataTask = URLSessionDataTaskSpy()
        let (sut, spy) = makeSUT()
        spy.stub(dataTask: vendedDataTask)
        let request = anyURLRequest()


        // WHEN
        sut.get(from: request) { _ in }

        // THEN
        XCTAssertEqual(vendedDataTask.calledResume, 1)
    }

    func test_get_withAnyResponseOnce_shouldPropagateResponse() throws {
        // GIVEN
        let (sut, spy) = makeSUT()
        var capturedResponses: [(Data?, URLResponse?, Error?)] = []

        sut.get(from: anyURLRequest()) { capturedResponses.append($0) }


        let completeData = anyData()
        let completeResponse = anyResponse()
        let completeError = anyNSError()


        // WHEN
        spy.completeWith(
            data: completeData,
            response: completeResponse,
            error: completeError
        )

        // THEN
        XCTAssertEqual(capturedResponses.count, 1)

        let actualResponse = try XCTUnwrap(capturedResponses.first)
        XCTAssertEqual(actualResponse.0, completeData)
        XCTAssertEqual(actualResponse.1, completeResponse)
        XCTAssertEqual(actualResponse.2 as NSError?, completeError)
    }

    func test_get_withAnyResponseTwice_shouldPropagateResponseTwice() throws {
        // GIVEN
        let (sut, spy) = makeSUT()
        var capturedResponses: [(Data?, URLResponse?, Error?)] = []

        sut.get(from: anyURLRequest()) { capturedResponses.append($0) }

        // WHEN
        let firstData = anyData()
        let firstResponse = anyResponse()
        let firstError = anyNSError()

        spy.completeWith(
            data: firstData,
            response: firstResponse,
            error: firstError
        )

        let secondData = anyData()
        let secondResponse = anyResponse()
        let secondError = anyNSError()

        spy.completeWith(
            data: secondData,
            response: secondResponse,
            error: secondError
        )

        // THEN
        XCTAssertEqual(capturedResponses.count, 2)

        let first = capturedResponses[0]
        XCTAssertEqual(first.0, firstData)
        XCTAssertEqual(first.1, firstResponse)
        XCTAssertEqual(first.2 as NSError?, firstError)

        let second = capturedResponses[1]
        XCTAssertEqual(second.0, secondData)
        XCTAssertEqual(second.1, secondResponse)
        XCTAssertEqual(second.2 as NSError?, secondError)
    }


    // MARK: - Helpers

    private func anyURLRequest() -> URLRequest {
        .init(url: anyURL())
    }

    func makeSUT() -> (HTTPClient, URLSessionProtocolSpy) {
        let spy = URLSessionProtocolSpy()
        return (HTTPClientImpl(urlSessionProtocol: spy), spy)
    }


    func anyNSError() -> NSError {
        .init(domain: anyString(), code: 8383, userInfo: nil)
    }
}

final class URLSessionProtocolSpy: URLSessionProtocol {

    private(set) var calledDataTasks: [CalledDataTask] = []

    struct CalledDataTask {
        let request: URLRequest
        let completionHandler: (Data?, URLResponse?, Error?) -> Void
    }


    struct Stub {
        let dataTask: URLSessionDataTaskProtocol
    }

    private var returnStub: Stub = .init(dataTask: FakeURLSessionDataTask())

    func completeWith(
        data: Data?,
        response: URLResponse?,
        error: Error?, at index: Int = 0
    ) {

        calledDataTasks[index].completionHandler(data, response, error)
    }


    func stub(dataTask: URLSessionDataTaskProtocol) {
        self.returnStub = Stub(dataTask: dataTask)
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {

        calledDataTasks.append(.init(
            request: request,
            completionHandler: completionHandler
        ))

        return returnStub.dataTask
    }


}

struct FakeURLSessionDataTask: URLSessionDataTaskProtocol {
    func resume() {

    }
}

final class URLSessionDataTaskSpy: URLSessionDataTaskProtocol {
    private(set) var calledResume = 0

    func resume() {
        calledResume += 1
    }
}

func anyResponse() -> URLResponse {
    .init(
        url: anyURL(),
        mimeType: nil,
        expectedContentLength: 0,
        textEncodingName: nil)
}


func anyError() -> Error {
    NSError(domain: "nfjesnejks", code: 19, userInfo: nil)
}

func anyData() -> Data {
    Data(anyString().utf8)
}
