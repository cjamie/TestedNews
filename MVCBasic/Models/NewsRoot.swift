//
//  NewsRoot.swift
//  MVCBasic
//
//  Created by Jamie Chu on 5/9/21.
//

import Foundation

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
