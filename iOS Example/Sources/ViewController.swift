import Foundation
import Combine
import UIKit
import HsToolKit
import ObjectMapper
import Alamofire

class ViewController: UIViewController {
    private let networkManager = NetworkManager(interRequestInterval: 1, logger: Logger(minLogLevel: .error))
    private let reachabilityManager = ReachabilityManager()

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        reachabilityManager.$isReachable
                .sink { print("Reachable: \($0)") }
                .store(in: &cancellables)

        for i in 1...3 {
            Task {
                do {
                    let categories: [Category] = try await networkManager.fetch(url: "https://api-dev.blocksdecoded.com/v1/categories", parameters: ["currency": "usd"])

                    print("\(i) - \(categories.count)")
                } catch {
                    print("ERROR: \(error)")
                }
            }
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
