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


        let completeData = anyData()
        let completeResponse = anyResponse()
        let completeError = anyNSError()

        // WHEN, THEN


        let expected = (completeData, completeResponse, completeError)

        expect(
            sut,
            toPropagateResponse: expected,
            when: spy.completeWith(response: expected)
        )
    }

    func test_get_withAnyResponseTwice_shouldPropagateResponseTwice() throws {
        // GIVEN
        let (sut, spy) = makeSUT()
        let firstData = anyData()
        let firstResponse = anyResponse()
        let firstError = anyNSError()

        let secondData = anyData()
        let secondResponse = anyResponse()
        let secondError = anyNSError()

        let responses: [(Data?, URLResponse?, NSError?)] = [
            (firstData, firstResponse, firstError),
            (secondData, secondResponse, secondError),
        ]


        // WHEN
        expect(
            sut,
            toPropagate: responses,
            when: responses.forEach { spy.completeWith(response: $0) }
        )
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

    func expect(
        _ sut: HTTPClient,
        toPropagateResponse expected: (Data?, URLResponse?, NSError?),
        when block: @autoclosure () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {

        var actualResponses: [(Data?, URLResponse?, Error?)] = []

        sut.get(from: anyURLRequest()) { actualResponses.append($0) }

        block()

        XCTAssertEqual(actualResponses.count, 1, file: file, line: line)

        let actualResponse = actualResponses.first
        XCTAssertEqual(actualResponse?.0, expected.0, file: file, line: line)
        XCTAssertEqual(actualResponse?.1, expected.1, file: file, line: line)
        XCTAssertEqual(actualResponse?.2 as NSError?, expected.2, file: file, line: line)
    }

    func expect(
        _ sut: HTTPClient,
        toPropagate responses: [(Data?, URLResponse?, NSError?)],
        when block: @autoclosure () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var actual: [(Data?, URLResponse?, Error?)] = []

        sut.get(from: anyURLRequest()) { actual.append($0) }

        block()

        XCTAssertEqual(actual.count, responses.count, "Jian has a big ass", file: file, line: line)

        zip(actual, responses).forEach { currentActual, currentExpected in

            XCTAssertEqual(currentActual.0, currentExpected.0, file: file, line: line)
            XCTAssertEqual(currentActual.1, currentExpected.1, file: file, line: line)
            XCTAssertEqual(currentActual.2 as NSError?, currentExpected.2, file: file, line: line)
        }
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

    func completeWith(response: (Data?, URLResponse?, Error?), at index: Int = 0
    ) {

        calledDataTasks[index].completionHandler(response.0, response.1, response.2)
    }


    func stub(dataTask: URLSessionDataTaskProtocol) {
        self.returnStub = Stub(dataTask: dataTask)
    }

    func dataTaskk(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {

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
