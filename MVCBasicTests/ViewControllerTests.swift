//
//  ViewControllerTests.swift
//  MVCBasicTests
//
//  Created by Jamie Chu on 5/1/21.
//

import XCTest
@testable import MVCBasic

class ViewControllerTests: XCTestCase {

    func test_viewDidLoad_shouldRequestNews() {
        // GIVEN
        let (sut, spy) = makeSUT()

        // WHEN
        XCTAssertEqual(spy.calledRequestNews.count, 0)

        sut.loadViewIfNeeded()

        // THEN

        XCTAssertEqual(spy.calledRequestNews.count, 1)
    }

    func test_completeWithSuccess_afterViewDidLoad_shouldUpdateLabel() {
        // GIVEN
        let (sut, spy) = makeSUT()
        sut.loadViewIfNeeded()
        let successValue = expectedNewsRoot()

        // WHEN
        spy.completeWithSuccess(object: successValue)


        XCTAssertEqual(sut.statusLabel.text, successValue.status)
    }

    func test_completeWithError_afterViewDidLoad_shouldUpdateLabel() {
        // GIVEN
        let (sut, spy) = makeSUT()
        sut.loadViewIfNeeded()

        // WHEN
        spy.completeWithError()


        XCTAssertEqual(sut.statusLabel.text, "Failed to retrieve news")
    }


    func test_viewDidLoad_shouldAddStatusLabelToViewHierarchy() {
        // GIVEN
        let (sut, _) = makeSUT()

        // WHEN
        sut.loadViewIfNeeded()

        // THEN
        XCTAssert(sut.view.subviews.contains(sut.statusLabel))
    }


    private func makeSUT() -> (ViewController, ViewControllerViewModelSpy) {
        let spy = ViewControllerViewModelSpy()
        let sut = ViewController(viewModel: spy)

        return (sut, spy)
    }

    private final class ViewControllerViewModelSpy: ViewControllerViewModel {
        private(set) var calledRequestNews: [NewsRootCompletion] = []

        func requestNews(completion: @escaping NewsRootCompletion) {
            calledRequestNews.append(completion)
        }

        func completeWithSuccess(object: NewsRoot = expectedNewsRoot(), at index: Int = 0) {
            calledRequestNews[index](.success(object))
        }

        func completeWithError(at index: Int = 0) {
            calledRequestNews[index](.failure(anyError()))
        }
    }
}


class ViewControllerViewModelImplTests: XCTestCase {
    func test_requestWeather_shouldMakeExpectedUnderlyingRequestToTheHttpClient() throws {


        try XCTSkipIf(true)
        // GIVEN
        let (sut, client) = makeSUT()

        // WHEN
        sut.requestNews { _ in }

        XCTAssertEqual(client.calledGet.map { $0.request }, [ try {
            let url = URL(string: "https://newsapi.org/v2/everything?q=tesla&from=2021-04-02&sortBy=publishedAt&apiKey=e5d785fd7502464298bc300d1416e378")
            return URLRequest(url: try XCTUnwrap(url))
        }()])
    }

    func test_clientComplete_withNilNilError_shouldPropagateErrorInResult() throws {
        let (sut, clientSpy) = makeSUT()

        var capturedResult: [Result<NewsRoot, Error>] = []

        sut.requestNews { capturedResult.append($0) }

        clientSpy.completeWithResponse(error: anyError())
        let result = try XCTUnwrap(capturedResult.first)

        switch result {
        case .failure:
            // no op
            print("-=- ")
            break
        case .success(let model):
            XCTFail("Expected failure, got model \(model)")
        }
    }

    func test_clientComplete_withValidDataResponseNil_shouldCompleteWithExpectedItems() throws {
        // GIVEN
        let (sut, spy) = makeSUT()
        var capturedResult: [Result<NewsRoot, Error>] = []
        sut.requestNews { capturedResult.append($0) }

        // WHEN
        spy.completeWithResponse(
            data: Data(teslaNewsStub.utf8),
            response: validHttpURLResponse()
        )

        // THEN
        let result = try XCTUnwrap(capturedResult.first)

        switch result {
        case .failure(let error):
            XCTFail("expected success, but got failure with message: \(error)")
        case .success(let actual):
            XCTAssertEqual(actual, expectedNewsRoot())
        }
    }


    // sample URL https://newsapi.org/v2/everything?q=tesla&from=2021-04-02&sortBy=publishedAt&apiKey=e5d785fd7502464298bc300d1416e378

    func test_requestNews_withSuppliedInputDateAndAPIKey_shouldGetWithProperURL() throws {
        // GIVEN

        let apiKey = anyString()
        let inputDate = Date(timeIntervalSince1970: 90000) // 1970-01-01 01:00:00 +0000
        let (sut, spy) = makeSUT(fromDateVendor: { inputDate }, apiKey: apiKey)

        // WHEN
        sut.requestNews { _ in }

        // THEN
        XCTAssertEqual(spy.calledGet.count, 1)

        let actualQueryItems =  try XCTUnwrap(URLComponents(
            url: XCTUnwrap(spy.calledGet.first?.request.url),
            resolvingAgainstBaseURL: true
        )?.queryItems)


        XCTAssert(actualQueryItems, containsElementWhere: {$0.name == "from" && $0.value == "\(1969)-\(12)-\(1)"})
        XCTAssert(actualQueryItems, containsElementWhere: {$0.name == "apiKey" && $0.value == apiKey})
    }

    func test_requestNews_withInputQuery_shouldGetWithProperURL() throws {
        // GIVEN
        let inputQuery = anyString()
        let (sut, spy) = makeSUT(inputQuery: inputQuery)

        // WHEN
        sut.requestNews { _ in }

        // THEN

        let actualQueryItems = try XCTUnwrap(URLComponents(
            url: XCTUnwrap(spy.calledGet.first?.request.url),
            resolvingAgainstBaseURL: true
        )?.queryItems)

        XCTAssert(actualQueryItems, containsElementWhere: {$0.name == "q" && $0.value == inputQuery})
    }


    func test_requestNews_shouldHaveExpectedHostSchemeAndPath() throws {
        let (sut, spy) = makeSUT()

        // WHEN
        sut.requestNews { _ in }

        // THEN

        let actual = try XCTUnwrap(spy.calledGet.first?.request.url)

        XCTAssertEqual(actual.host, "newsapi.org")
        XCTAssertEqual(actual.scheme, "https")
        XCTAssertEqual(actual.path, "/v2/everything")
    }




    private func XCTAssert<T>(
        _ items: [T],
        containsElementWhere: (T) -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            items.contains(where: containsElementWhere),
            "these items \(items) did not find match",
            file: file,
            line: line)
    }



//    func test_requestNews_duringJanuary_shouldGetWithProperURL() {
//        // GIVEN
//
//        let apiKey = anyString()
//        let inputDate = Date(timeIntervalSince1970: 90000) // 1970-01-02 01:00:00 +0000
//        let currentCalendar = Calendar.current
//
//        let expectedYear = currentCalendar.component(.year, from: inputDate)
//        let expectedDay = currentCalendar.component(.day, from: inputDate)
//        let expectedMonth = currentCalendar.component(.month, from: inputDate)
//
//
//        let expectedRequest: URLRequest = {
//            let expectedURL = URL(string: "https://newsapi.org/v2/everything?q=tesla&from=\(expectedYear)-\(expectedMonth - 1)-\(expectedDay)&apiKey=\(apiKey)")!
//
//
//            let request = URLRequest(url: expectedURL)
//            return request
//        }()
//
//        let (sut, spy) = makeSUT(fromDateVendor: { inputDate }, apiKey: apiKey)
//
//
//
//        // WHEN
//        sut.requestNews { _ in }
//
//
//        // THEN
//        XCTAssertEqual(spy.calledGet, [
//            .init(request: expectedRequest) { _ in }
//        ])
//    }


    private func anyInt() -> Int {
        -2448
    }

    private func validWeatherRootData() -> Data {
        // TODO: -
        Data()
    }

    private func validHttpURLResponse() -> HTTPURLResponse {
        .init(
            url: anyURL(),
            mimeType: anyString(),
            expectedContentLength: anyInt(),
            textEncodingName: anyString()
        )
    }

    private func anyResponse() -> URLResponse {
        .init(
            url: anyURL(),
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil)
    }


    private func makeSUT(
        fromDateVendor: @escaping ViewControllerViewModelImpl.DateVendor = Date.init,
        apiKey: String = anyString(),
        inputQuery: String = anyString()
    ) -> (sut: ViewControllerViewModel, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = ViewControllerViewModelImpl(
            client: client,
            fromDateVendor: fromDateVendor,
            apiKey: apiKey,
            inputQuery: inputQuery
        )

        return (sut, client)
    }
}

class DecodingTests: XCTestCase {

    func test_decoder() throws {
        let decoder = JSONDecoder()
        let dataExpectedToDecodeIntoNewsRoot = Data(teslaNewsStub.utf8)

        let value = try decoder.decode(NewsRoot.self, from: dataExpectedToDecodeIntoNewsRoot)


        XCTAssertEqual(value, expectedNewsRoot())
    }

}

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
        let rawResponse = HTTPClient.RawResponse(data, response, error)

        calledGet.map { $0.rawResponse }[index](rawResponse)
    }

}

private func anyError() -> Error {
    NSError(domain: "nfjesnejks", code: 19, userInfo: nil)
}

func expectedNewsRoot() -> NewsRoot {
    .init(
        status: "ok",
        totalResults: 9431,
        articles: [
            .init(
                source: .init(
                    id: nil,
                    name: "Salon"
                ),
                author: "Robert Reich",
                title: "Elon Musk and Jeff Bezos: the great escape",
                articleDescription: "The rich have found ways to protect themselves from the rest of humanity",
                url: URL(string: "https://www.salon.com/2021/05/01/elon-musk-and-jeff-bezos-the-great-escape_partner/")!,
                urlToImage: URL(string: "https://media.salon.com/2020/11/musk-bezos-spacex-1113201.jpg")!,
//                publishedAt: .distantPast,
                content: "Elon Musk and Jeff Bezos want to colonize outer space to save humanity, but they couldn't care less about protecting the rights of workers here on earth.\r\nMusk's SpaceX just won a $2.9 billion NAS"
            ),
            .init(
                source: .init(
                    id: nil,
                    name: "Motley Fool Australia"),
                author: "James Mickleboro",
                title: "3 high quality ETFs for ASX investors in May",
                articleDescription: "BetaShares NASDAQ 100 ETF (ASX:NDQ) and these ASX ETFs could be high quality options for investors in May...\nThe post 3 high quality ETFs for ASX investors in May appeared first on The Motley Fool Australia.",
                url: URL(string: "https://www.fool.com.au/2021/05/02/3-high-quality-etfs-for-asx-investors-in-may/")!,
                urlToImage: URL(string: "https://www.fool.com.au/wp-content/uploads/2021/04/asx-share-price-22.jpg")!,
//                publishedAt: .distantPast,
                content: "If you’re looking for an easy way to invest your hard-earned money, then exchange traded funds (ETFs) could be worth considering. Rather than deciding on which individual shares you should put your")
        ]
    )
//    .init(
//        status: "ok",
//        totalResults: 9431,
//        articles: [
//            .init(
//                source: .init(
//                    id: nil,
//                    name: "Salon"
//                ),
//                author: "Robert Reich",
//                title: "Elon Musk and Jeff Bezos: the great escape",
//                description: "The rich have found ways to protect themselves from the rest of humanity",
//                url: URL(string: "https://www.salon.com/2021/05/01/elon-musk-and-jeff-bezos-the-great-escape_partner/")!,
//                urlToImage: URL(string: "https://media.salon.com/2020/11/musk-bezos-spacex-1113201.jpg")!,
//                content: "Elon Musk and Jeff Bezos want to colonize outer space to save humanity, but they couldn't care less about protecting the rights of workers here on earth.\r\nMusk's SpaceX just won a $2.9 billion NAS"
//            ),
//            .init(
//                source: .init(
//                    id: nil,
//                    name: "Motley Fool Australia"
//                ),
//                author: "James Mickleboro",
//                title: "3 high quality ETFs for ASX investors in May",
//                description: "BetaShares NASDAQ 100 ETF (ASX:NDQ) and these ASX ETFs could be high quality options for investors in May...\nThe post 3 high quality ETFs for ASX investors in May appeared first on The Motley Fool Australia.",
//                url: URL(string: "https://www.fool.com.au/2021/05/02/3-high-quality-etfs-for-asx-investors-in-may/")!,
//                urlToImage: URL(string: "https://www.fool.com.au/wp-content/uploads/2021/04/asx-share-price-22.jpg")!,
//                content: "If you’re looking for an easy way to invest your hard-earned money, then exchange traded funds (ETFs) could be worth considering. Rather than deciding on which individual shares you should put your"
//            )
//        ]
//    )
}



func anyString(_ length: Int = 10) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map { _ in letters.randomElement()! })
}

func anyURL() -> URL {
    URL(string: "https://example.com")!
}
