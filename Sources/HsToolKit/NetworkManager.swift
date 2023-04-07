import Foundation
import Alamofire

public class NetworkManager {
    private static var index = 1

    // todo: make session private, remove all external usages
    public let session: Session
    private let interRequestInterval: TimeInterval?
    private var logger: Logger?

    private var lastRequestTime: TimeInterval = 0

    public init(interRequestInterval: TimeInterval? = nil, logger: Logger? = nil) {
        session = Session()
        self.interRequestInterval = interRequestInterval
        self.logger = logger
    }

    public func fetchData(
            url: URLConvertible, method: HTTPMethod = .get, parameters: Parameters = [:], encoding: ParameterEncoding = URLEncoding.default,
            headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil,
            contentType: String? = nil
    ) async throws -> Data {
        if let interRequestInterval {
            let now = Date().timeIntervalSince1970

            if lastRequestTime + interRequestInterval <= now {
                lastRequestTime = now
            } else {
                lastRequestTime += interRequestInterval
                try await Task.sleep(nanoseconds: UInt64((lastRequestTime - now) * 1_000_000_000))
            }
        }

        var request = session
                .request(url, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor)
                .validate(statusCode: 200..<400)

        if let contentType {
            request = request.validate(contentType: [contentType])
        }

        if let responseCacherBehavior {
            request = request.cacheResponse(using: ResponseCacher(behavior: responseCacherBehavior))
        }

        do {
            return try await request.serializingData(automaticallyCancelling: true).value
        } catch {
            throw Self.unwrap(error: error)
        }
    }

    public func fetchJson(
            url: URLConvertible, method: HTTPMethod = .get, parameters: Parameters = [:], encoding: ParameterEncoding = URLEncoding.default,
            headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil
    ) async throws -> Any {
        let uuid = Self.index
        Self.index += 1

        logger?.debug("API OUT [\(uuid)]: \(method.rawValue) \(url) \(parameters)")

        let data = try await fetchData(
                url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor,
                responseCacherBehavior: responseCacherBehavior, contentType: "application/json"
        )

        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

        logger?.debug("API IN [\(uuid)]: \(json)")

        return json
    }

    // todo: remove this method, used for back-compatibility only
    func fetchData(request: DataRequest, responseCacherBehavior: ResponseCacher.Behavior? = nil, contentType: String? = nil) async throws -> Data {
        if let interRequestInterval {
            let now = Date().timeIntervalSince1970

            if lastRequestTime + interRequestInterval <= now {
                lastRequestTime = now
            } else {
                lastRequestTime += interRequestInterval
                try await Task.sleep(nanoseconds: UInt64((lastRequestTime - now) * 1_000_000_000))
            }
        }

        var request = request.validate(statusCode: 200..<400)

        if let contentType {
            request = request.validate(contentType: [contentType])
        }

        if let responseCacherBehavior {
            request = request.cacheResponse(using: ResponseCacher(behavior: responseCacherBehavior))
        }

        do {
            return try await request.serializingData(automaticallyCancelling: true).value
        } catch {
            throw Self.unwrap(error: error)
        }
    }

    // todo: remove this method, used for back-compatibility only
    func fetchJson(request: DataRequest, responseCacherBehavior: ResponseCacher.Behavior? = nil) async throws -> Any {
        let uuid = Self.index
        Self.index += 1

        logger?.debug("API OUT [\(uuid)]: \(request)")

        let data = try await fetchData(request: request, responseCacherBehavior: responseCacherBehavior, contentType: "application/json")
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

        logger?.debug("API IN [\(uuid)]: \(json)")

        return json
    }

}

extension NetworkManager {

    public static func unwrap(error: Error) -> Error {
        if case let AFError.responseSerializationFailed(reason) = error, case let .customSerializationFailed(error) = reason {
            return error
        }

        return error
    }

}
