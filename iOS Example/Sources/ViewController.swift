//
//  ViewController.swift
//  SWToolKit-Example
//
//  Created by Sun on 2024/8/21.
//

import UIKit
import Combine

import Alamofire
import SWToolKit
import ObjectMapper

class ViewController: UIViewController {
    private let networkManager = NetworkManager(interRequestInterval: 2, logger: Logger(minLogLevel: .error))
    private let reachabilityManager = ReachabilityManager()

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        reachabilityManager.$isReachable
            .sink {
                print("Reachable: \($0)")
            }
            .store(in: &cancellables)

        let task = Task {
            do {
                for i in 1 ... 10 {
                    let categories: [Category] = try await networkManager.fetch(url: "https://api-dev.blocksdecoded.com/v1/categories", parameters: ["currency": "usd"])

                    print("\(i) - \(categories.count)")
                }
            } catch {
                print("ERROR: \(error.localizedDescription)")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            task.cancel()
        }
    }
}

class Category: ImmutableMappable {
    let uid: String
    let name: String

    required init(map: Map) throws {
        uid = try map.value("uid")
        name = try map.value("name")
    }
}
