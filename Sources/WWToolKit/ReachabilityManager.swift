//
//  ReachabilityManager.swift
//  WWToolKit
//
//  Created by Sun on 2024/8/21.
//

import Combine
import Foundation

import Alamofire
import WWExtensions

// MARK: - ReachabilityManager

public class ReachabilityManager {
    private let manager: NetworkReachabilityManager?

    @DistinctPublished
    public private(set) var isReachable = false
    private let connectionTypeChangedSubject = PassthroughSubject<Void, Never>()

    private var lastConnectionType: NetworkReachabilityManager.NetworkReachabilityStatus.ConnectionType? = nil

    public init() {
        manager = NetworkReachabilityManager()

        if let manager {
            isReachable = manager.isReachable

            manager.startListening { [weak self] status in
                self?.onUpdate(status: status)
            }
        }
    }

    private func onUpdate(status: NetworkReachabilityManager.NetworkReachabilityStatus) {
        switch status {
        case .reachable(let connectionType):
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

    public var connectionTypeChangedPublisher: AnyPublisher<Void, Never> {
        connectionTypeChangedSubject.eraseToAnyPublisher()
    }
}

// MARK: ReachabilityManager.ReachabilityError

extension ReachabilityManager {
    public enum ReachabilityError: Error {
        case notReachable
    }
}
