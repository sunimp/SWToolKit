//
//  WebSocketErrorHandler.swift
//
//  Created by Sun on 2022/1/20.
//

import Foundation

import NIO
import NIOWebSocket

// MARK: - WebSocketErrorHandlerDelegate

protocol WebSocketErrorHandlerDelegate {
    func onError(error: NIOWebSocketError)
}

// MARK: - WebSocketErrorHandler

final class WebSocketErrorHandler: ChannelInboundHandler {
    // MARK: Nested Types

    typealias InboundIn = Never
    typealias OutboundOut = WebSocketFrame

    // MARK: Properties

    private let delegate: WebSocketErrorHandlerDelegate

    // MARK: Lifecycle

    init(delegate: WebSocketErrorHandlerDelegate) {
        self.delegate = delegate
    }

    // MARK: Functions

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        if let error = error as? NIOWebSocketError {
            delegate.onError(error: error)
        }

        context.fireErrorCaught(error)
    }
}
