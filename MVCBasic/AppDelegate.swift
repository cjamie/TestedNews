//
//  AppDelegate.swift
//  MVCBasic
//
//  Created by Jamie Chu on 5/1/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        startAppFlow()

        return true
    }
//
    private func startAppFlow() {
        let myWindow = UIWindow(frame: UIScreen.main.bounds)

        let client = HTTPClientSpy()
//        let client = HTTPClientImpl()
        let viewModel = ViewControllerViewModelImpl(
            client: client,
            fromDateVendor: Date.init,
            apiKey: "some api key", inputQuery: "rando"
        )

        let controller = ViewController(viewModel: viewModel)

        myWindow.rootViewController = UINavigationController(rootViewController: controller)

        window = myWindow


        myWindow.makeKeyAndVisible()



        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            client.completeWithResponse(
                data: Data(teslaNewsStub.utf8),
                response: HTTPURLResponse(
                    url: URL(string: "https://example.com")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil
            )
        }
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
