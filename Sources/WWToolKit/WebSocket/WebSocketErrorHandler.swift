//
//  WebSocketErrorHandler.swift
//  WWToolKit
//
//  Created by Sun on 2024/8/21.
//

import Foundation

import NIO
import NIOWebSocket

protocol WebSocketErrorHandlerDelegate {
    func onError(error: NIOWebSocketError)
}

final class WebSocketErrorHandler: ChannelInboundHandler {
    typealias InboundIn = Never
    typealias OutboundOut = WebSocketFrame

    private let delegate: WebSocketErrorHandlerDelegate

    init(delegate: WebSocketErrorHandlerDelegate) {
        self.delegate = delegate
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        if let error = error as? NIOWebSocketError {
            delegate.onError(error: error)
        }

        context.fireErrorCaught(error)
    }
}
