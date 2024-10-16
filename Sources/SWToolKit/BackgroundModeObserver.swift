//
//  BackgroundModeObserver.swift
//  SWToolKit
//
//  Created by Sun on 2024/8/14.
//

#if os(iOS)
import Combine
import UIKit

public class BackgroundModeObserver {
    // MARK: Static Properties

    public static let shared = BackgroundModeObserver()

    // MARK: Properties

    private let foregroundFromExpiredBackgroundSubject = PassthroughSubject<Void, Never>()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    private var cancellables = Set<AnyCancellable>()

    // MARK: Computed Properties

    public var foregroundFromExpiredBackgroundPublisher: AnyPublisher<Void, Never> {
        foregroundFromExpiredBackgroundSubject.eraseToAnyPublisher()
    }

    // MARK: Lifecycle

    init() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.appCameToBackground() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.appCameToForeground() }
            .store(in: &cancellables)
    }

    // MARK: Functions

    @objc
    private func appCameToBackground() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    @objc
    private func appCameToForeground() {
        if backgroundTask != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskIdentifier.invalid
        } else {
            foregroundFromExpiredBackgroundSubject.send()
        }
    }
}
#endif
