//
//  WebSocketClient.swift
//  SWToolKit
//
//  Created by Sun on 2024/8/14.
//

import Foundation

import Atomics
import NIO
import NIOConcurrencyHelpers
import NIOHTTP1
import NIOSSL
import NIOWebSocket

final class WebSocketClient {
    // MARK: Nested Types

    enum Error: Swift.Error, LocalizedError {
        case invalidURL
        case invalidResponseStatus(HTTPResponseHead)
        case alreadyShutdown

        // MARK: Computed Properties

        var errorDescription: String? {
            "\(self)"
        }
    }

    enum EventLoopGroupProvider {
        case shared(EventLoopGroup)
        case createNew
    }

    struct Configuration {
        // MARK: Properties

        var tlsConfiguration: TLSConfiguration?
        var maxFrameSize: Int

        // MARK: Lifecycle

        init(
            tlsConfiguration: TLSConfiguration? = nil,
            maxFrameSize: Int = 1 << 14
        ) {
            self.tlsConfiguration = tlsConfiguration
            self.maxFrameSize = maxFrameSize
        }
    }

    // MARK: Properties

    let eventLoopGroupProvider: EventLoopGroupProvider
    let group: EventLoopGroup
    let configuration: Configuration
    let isShutdown = ManagedAtomic<Bool>(false)

    // MARK: Lifecycle

    init(eventLoopGroupProvider: EventLoopGroupProvider, configuration: Configuration = .init()) {
        self.eventLoopGroupProvider = eventLoopGroupProvider
        switch self.eventLoopGroupProvider {
        case let .shared(group):
            self.group = group
        case .createNew:
            group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        }
        self.configuration = configuration
    }

    deinit {
        switch eventLoopGroupProvider {
        case .shared:
            return
        case .createNew:
            assert(isShutdown.load(ordering: .sequentiallyConsistent), "WebSocketClient not shutdown before deinit.")
        }
    }

    // MARK: Functions

    func connect(
        scheme: String,
        host: String,
        port: Int,
        path: String = "/",
        headers: HTTPHeaders = [:],
        onUpgrade: @escaping (NIOWebSocket) -> Void
    )
        -> EventLoopFuture<Void> {
        assert(["ws", "wss"].contains(scheme))
        let upgradePromise = group.next().makePromise(of: Void.self)
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)
            .channelInitializer { channel in
                let httpHandler = HTTPInitialRequestHandler(
                    host: host,
                    path: path,
                    headers: headers,
                    upgradePromise: upgradePromise
                )

                var key: [UInt8] = []
                for _ in 0 ..< 16 {
                    key.append(.random(in: .min ..< .max))
                }
                let websocketUpgrader = NIOWebSocketClientUpgrader(
                    requestKey: Data(key).base64EncodedString(),
                    maxFrameSize: self.configuration.maxFrameSize,
                    automaticErrorHandling: false,
                    upgradePipelineHandler: { channel, _ in
                        NIOWebSocket.client(on: channel, onUpgrade: onUpgrade)
                    }
                )

                let config: NIOHTTPClientUpgradeConfiguration = (
                    upgraders: [websocketUpgrader],
                    completionHandler: { _ in
                        upgradePromise.succeed(())
                        channel.pipeline.removeHandler(httpHandler, promise: nil)
                    }
                )

                if scheme == "wss" {
                    do {
                        let context = try NIOSSLContext(
                            configuration: self.configuration.tlsConfiguration ?? .makeClientConfiguration()
                        )
                        let tlsHandler = try NIOSSLClientHandler(context: context, serverHostname: host)
                        return channel.pipeline.addHandler(tlsHandler).flatMap {
                            channel.pipeline.addHTTPClientHandlers(
                                leftOverBytesStrategy: .forwardBytes,
                                withClientUpgrade: config
                            )
                        }.flatMap {
                            channel.pipeline.addHandler(httpHandler)
                        }
                    } catch {
                        return channel.pipeline.close(mode: .all)
                    }
                } else {
                    return channel.pipeline.addHTTPClientHandlers(
                        leftOverBytesStrategy: .forwardBytes,
                        withClientUpgrade: config
                    ).flatMap {
                        channel.pipeline.addHandler(httpHandler)
                    }
                }
            }

        let connect = bootstrap.connect(host: host, port: port)
        connect.cascadeFailure(to: upgradePromise)
        return connect.flatMap { _ in
            upgradePromise.futureResult
        }
    }

    func syncShutdown() throws {
        switch eventLoopGroupProvider {
        case .shared:
            return
        case .createNew:
            let (exchanged, _) = isShutdown.compareExchange(
                expected: false,
                desired: true,
                ordering: .sequentiallyConsistent
            )
            if exchanged {
                try group.syncShutdownGracefully()
            } else {
                throw WebSocketClient.Error.alreadyShutdown
            }
        }
    }
}
