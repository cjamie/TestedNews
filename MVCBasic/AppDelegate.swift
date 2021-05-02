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
        print("-=- app delegate")

//        startAppFlow()

        return true
    }
//
//    private func startAppFlow() {
//        let myWindow = UIWindow(frame: UIScreen.main.bounds)
//        let viewModel = ViewControllerViewModelImpl(
//            client: HTTPClientImpl(),
//            fromDateVendor: Date.init,
//            apiKey: "some api key", inputQuery: "rando"
//        )
//
//        let controller = ViewController(viewModel: viewModel)
//
//        myWindow.rootViewController = UINavigationController(rootViewController: controller)
//
//        window = myWindow
//
//
//        myWindow.makeKeyAndVisible()
//    }


}

