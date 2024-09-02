//
//  ReachabilityManager.swift
//
//  Created by Sun on 2022/1/20.
//

import Combine
import Foundation

import Alamofire
import WWExtensions

// MARK: - ReachabilityManager

public class ReachabilityManager {
    // MARK: Properties

    @DistinctPublished
    public private(set) var isReachable = false

    private let manager: NetworkReachabilityManager?

    private let connectionTypeChangedSubject = PassthroughSubject<Void, Never>()

    private var lastConnectionType: NetworkReachabilityManager.NetworkReachabilityStatus.ConnectionType?

    // MARK: Computed Properties

    public var connectionTypeChangedPublisher: AnyPublisher<Void, Never> {
        connectionTypeChangedSubject.eraseToAnyPublisher()
    }

    // MARK: Lifecycle

    public init() {
        manager = NetworkReachabilityManager()

        if let manager {
            isReachable = manager.isReachable

            manager.startListening { [weak self] status in
                self?.onUpdate(status: status)
            }
        }
    }

    // MARK: Functions

    private func onUpdate(status: NetworkReachabilityManager.NetworkReachabilityStatus) {
        switch status {
        case let .reachable(connectionType):
            isReachable = true

            if let lastConnectionType, connectionType != lastConnectionType {
                connectionTypeChangedSubject.send()
            }

            lastConnectionType = connectionType

        default:
            isReachable = false
            lastConnectionType = nil
        }
    }
}

// MARK: ReachabilityManager.ReachabilityError

extension ReachabilityManager {
    public enum ReachabilityError: Error {
        case notReachable
    }
}
