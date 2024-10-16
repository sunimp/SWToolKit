//
//  WebSocketHandler.swift
//  SWToolKit
//
//  Created by Sun on 2024/8/14.
//

import Foundation

import NIO
import NIOWebSocket

extension NIOWebSocket {
    static func client(
        on channel: Channel,
        onUpgrade: @escaping (NIOWebSocket) -> Void
    )
        -> EventLoopFuture<Void> {
        handle(on: channel, as: .client, onUpgrade: onUpgrade)
    }

    static func server(
        on channel: Channel,
        onUpgrade: @escaping (NIOWebSocket) -> Void
    )
        -> EventLoopFuture<Void> {
        handle(on: channel, as: .server, onUpgrade: onUpgrade)
    }

    private static func handle(
        on channel: Channel,
        as type: PeerType,
        onUpgrade: @escaping (NIOWebSocket) -> Void
    )
        -> EventLoopFuture<Void> {
        let webSocket = NIOWebSocket(channel: channel, type: type)
        _ = channel.pipeline.addHandler(WebSocketErrorHandler(delegate: webSocket))

        return channel.pipeline.addHandler(WebSocketHandler(webSocket: webSocket)).map { _ in
            onUpgrade(webSocket)
        }
    }
}

extension WebSocketErrorCode {
    init(_ error: NIOWebSocketError) {
        switch error {
        case .invalidFrameLength:
            self = .messageTooLarge
        case .fragmentedControlFrame,
             .multiByteControlFrameLength:
            self = .protocolError
        }
    }
}

// MARK: - WebSocketHandler

private final class WebSocketHandler: ChannelInboundHandler {
    // MARK: Nested Types

    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    // MARK: Properties

    private var webSocket: NIOWebSocket

    // MARK: Lifecycle

    init(webSocket: NIOWebSocket) {
        self.webSocket = webSocket
    }

    // MARK: Functions

    func channelRead(context _: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        webSocket.handle(incoming: frame)
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        let errorCode: WebSocketErrorCode =
            if let error = error as? NIOWebSocketError {
                WebSocketErrorCode(error)
            } else {
                .unexpectedServerError
            }
        _ = webSocket.close(code: errorCode)

        // We always forward the error on to let others see it.
        context.fireErrorCaught(error)
    }

    func channelInactive(context: ChannelHandlerContext) {
        let closedAbnormally = WebSocketErrorCode.unknown(1006)
        _ = webSocket.close(code: closedAbnormally)

        // We always forward the error on to let others see it.
        context.fireChannelInactive()
    }
}
