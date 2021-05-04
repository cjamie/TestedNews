//
//  ViewController.swift
//  MVCBasic
//
//  Created by Jamie Chu on 5/1/21.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("-=- did load? ")

        viewModel.requestNews { [weak self] result in
            print("-=- result \(result)")
            switch result {
            case .failure:
                self?.statusLabel.text = "Failed to retrieve news"
            case .success(let root):
                self?.statusLabel.text = root.status
            }
        }


        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(statusLabel)

        view.backgroundColor = .yellow


        statusLabel.text = "vjsnenjksnjknk"


        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: statusLabel.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),

        ])

    }

    let statusLabel: UILabel = UILabel()

    init(viewModel: ViewControllerViewModel) {
        self.viewModel = viewModel
        print("-=- init")
        super.init(nibName: nil, bundle: nil)
    }

    private let viewModel: ViewControllerViewModel

    required init?(coder aDecoder: NSCoder) {
        fatalError("Storyboard are a pain")
    }


}

struct NewsRoot: Decodable, Equatable {
    let status: String
    let totalResults: Int
    let articles: [Article]

    init(status: String, totalResults: Int, articles: [Article]) {
        self.status = status
        self.totalResults = totalResults
        self.articles = articles
    }
}


// MARK: - Article
struct Article: Decodable, Equatable {
    let source: Source
    let author: String?
    let title: String
    let articleDescription: String
    let url: URL //
    let urlToImage: URL
//    let publishedAt: Date
    let content: String

    enum CodingKeys: String, CodingKey {
        case source
        case author
        case title
        case articleDescription = "description"
        case url
        case urlToImage
//        case publishedAt
        case content
    }

    init(
        source: Source,
        author: String?,
        title: String,
        articleDescription: String,
        url: URL,
        urlToImage: URL,
//        publishedAt: Date,
        content: String
    ) {
        self.source = source
        self.author = author
        self.title = title
        self.articleDescription = articleDescription
        self.url = url
        self.urlToImage = urlToImage
//        self.publishedAt = publishedAt
        self.content = content
    }
}

// MARK: - Source
struct Source: Decodable, Equatable {
    let id: String?
    let name: String

    init(id: String?, name: String) {
        self.id = id
        self.name = name
    }
}




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
        apiKey: String
    )-> URL? {
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



protocol HTTPClient {
    typealias RawResponse = (Data?, URLResponse?, Error?)

    func get(from request: URLRequest, rawResponse: @escaping (RawResponse)-> Void)
}

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
}

protocol URLSessionDataTaskProtocol {
    func resume()
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
            .dataTask(with: request) { rawResponse(($0, $1, $2)) }
            .resume()
    }
}

let teslaNewsStub = """
{
    "status": "ok",
    "totalResults": 9431,
    "articles": [
        {
            "source": {
                "id": null,
                "name": "Salon"
            },
            "author": "Robert Reich",
            "title": "Elon Musk and Jeff Bezos: the great escape",
            "description": "The rich have found ways to protect themselves from the rest of humanity",
            "url": "https://www.salon.com/2021/05/01/elon-musk-and-jeff-bezos-the-great-escape_partner/",
            "urlToImage": "https://media.salon.com/2020/11/musk-bezos-spacex-1113201.jpg",
            "publishedAt": "2021-05-02T01:00:01Z",
            "content": "Elon Musk and Jeff Bezos want to colonize outer space to save humanity, but they couldn't care less about protecting the rights of workers here on earth.\\r\\nMusk's SpaceX just won a $2.9 billion NAS"
        },
        {
            "source": {
                "id": null,
                "name": "Motley Fool Australia"
            },
            "author": "James Mickleboro",
            "title": "3 high quality ETFs for ASX investors in May",
            "description": "BetaShares NASDAQ 100 ETF (ASX:NDQ) and these ASX ETFs could be high quality options for investors in May...\\nThe post 3 high quality ETFs for ASX investors in May appeared first on The Motley Fool Australia.",
            "url": "https://www.fool.com.au/2021/05/02/3-high-quality-etfs-for-asx-investors-in-may/",
            "urlToImage": "https://www.fool.com.au/wp-content/uploads/2021/04/asx-share-price-22.jpg",
            "publishedAt": "2021-05-02T00:30:52Z",
            "content": "If you’re looking for an easy way to invest your hard-earned money, then exchange traded funds (ETFs) could be worth considering. Rather than deciding on which individual shares you should put your"
        },
    ]
}
"""

