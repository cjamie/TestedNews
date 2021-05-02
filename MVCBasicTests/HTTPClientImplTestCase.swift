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


//    func test_get_shouldCallDataTask() {
//        let spy = URLSessionProtocolSpy()
//        let sut = makeSUT(urlSessionProtocol: spy)
//
//        let request = anyURLRequest()
//        sut.get(from: request) { _ in }
//
//        XCTAssertEqual(spy.calledDataTasks.map { $0.request }, [ request ])
//    }




    private func anyURLRequest() -> URLRequest {
        .init(url: anyURL())
    }

    func makeSUT() -> (HTTPClient, URLSessionProtocolSpy) {
        let spy = URLSessionProtocolSpy()
        return (HTTPClientImpl(urlSessionProtocol: spy), spy)
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
