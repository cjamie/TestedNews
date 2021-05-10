//
//  ViewControllerViewModel.swift
//  MVCBasic
//
//  Created by Jamie Chu on 5/9/21.
//

import Foundation

protocol ViewControllerViewModel {
    typealias NewsRootCompletion = (Result<NewsRoot, Error>) -> Void

    func requestNews(completion: @escaping NewsRootCompletion)
}


// will be responsible for mapping client responses to our result type

final class ViewControllerViewModelImpl: ViewControllerViewModel {
    typealias DateVendor = () -> Date

    private let client: HTTPClient
    private let fromDateVendor: DateVendor
    private let apiKey: String
    private let inputQuery: String

    init(
        client: HTTPClient,
        fromDateVendor: @escaping DateVendor,
        apiKey: String,
        inputQuery: String
    ) {
        self.client = client
        self.fromDateVendor = fromDateVendor
        self.apiKey = apiKey
        self.inputQuery = inputQuery
    }

    func requestNews(completion: @escaping NewsRootCompletion) {
        guard let derivedURL = TeslaNewsURLDeriver.url(
            fromDate: fromDateVendor(),
            inputQuery: inputQuery,
            apiKey: apiKey
        ) else { return }

        client.get(from: URLRequest(url: derivedURL)) { [weak self] data, response, error in

            guard self != nil else { return }

            if let result: Result<NewsRoot, Error> = HttpResponseMapper.mapResult(data: data, response: response, error: error) {
                completion(result)
            }
        }
    }
}


private enum HttpResponseMapper {
    static func mapResult<T: Decodable>(
        data: Data?,
        response: URLResponse?,
        error: Error?
    )-> Result<T, Error>? {

        if let error = error {
            return .failure(error)
        }

        if let data = data,
           let response = response as? HTTPURLResponse,
           (200..<299).contains(response.statusCode),
           let decodedObject = try? JSONDecoder().decode(T.self, from: data) {
            return .success(decodedObject)
        }


        return nil
    }

}


private enum TeslaNewsURLDeriver {
    static func url(
        fromDate: Date,
        inputQuery: String,
        apiKey: String)-> URL? {
        let calendar = Calendar.current

        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: fromDate) else { return nil }

        let month = calendar.component(.month, from: oneMonthAgo)
        let day = calendar.component(.day, from: oneMonthAgo)
        let year = calendar.component(.year, from: oneMonthAgo)

        let components = NSURLComponents()

        components.host = "newsapi.org"
        components.scheme = "https"
        components.path = "/v2/everything"

        components.queryItems = [
            "q": inputQuery,
            "from": "\(year)-\(month)-\(day)",
            "apiKey": apiKey
        ].map(URLQueryItem.init)

        return components.url
    }
}
