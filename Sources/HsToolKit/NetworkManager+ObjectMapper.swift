import Foundation
import Alamofire
import ObjectMapper
import RxSwift

extension NetworkManager {

    public func single<T: ImmutableMappable>(request: DataRequest, sync: Bool = false, postDelay: TimeInterval? = nil, context: MapContext? = nil) -> Single<T> {
        single(request: request, mapper: ObjectMapper<T>(context: context), sync: sync, postDelay: postDelay)
    }

    public func single<T: ImmutableMappable>(request: DataRequest, context: MapContext? = nil) -> Single<[T]> {
        single(request: request, mapper: ObjectArrayMapper<T>(context: context))
    }

    public func single<T: ImmutableMappable>(url: URLConvertible, method: HTTPMethod, parameters: Parameters = [:], encoding: ParameterEncoding = URLEncoding.default, headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil, context: MapContext? = nil) -> Single<T> {
        single(url: url, method: method, parameters: parameters, mapper: ObjectMapper<T>(context: context), encoding: encoding, headers: headers, interceptor: interceptor, responseCacherBehavior: responseCacherBehavior)
    }

    public func single<T: ImmutableMappable>(url: URLConvertible, method: HTTPMethod, parameters: Parameters = [:], encoding: ParameterEncoding = URLEncoding.default, headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil, context: MapContext? = nil) -> Single<[T]> {
        single(url: url, method: method, parameters: parameters, mapper: ObjectArrayMapper<T>(context: context), encoding: encoding, headers: headers, interceptor: interceptor, responseCacherBehavior: responseCacherBehavior)
    }

    public func single<T: ImmutableMappable>(url: URLConvertible, method: HTTPMethod, parameters: Parameters = [:], encoding: ParameterEncoding = URLEncoding.default, headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil, context: MapContext? = nil) -> Single<[String: T]> {
        single(url: url, method: method, parameters: parameters, mapper: ObjectDictionaryMapper<T>(context: context), encoding: encoding, headers: headers, interceptor: interceptor, responseCacherBehavior: responseCacherBehavior)
    }

}

extension NetworkManager {

    class ObjectMapper<T: ImmutableMappable>: IApiMapper {
        private let context: MapContext?

        init(context: MapContext? = nil) {
            self.context = context
        }

        func map(statusCode: Int, data: Any?) throws -> T {
            guard let data = data else {
                throw RequestError.invalidResponse(statusCode: statusCode, data: data)
            }

            return try T(JSONObject: data, context: context)
        }

    }

    class ObjectArrayMapper<T: ImmutableMappable>: IApiMapper {
        private let context: MapContext?

        init(context: MapContext? = nil) {
            self.context = context
        }

        func map(statusCode: Int, data: Any?) throws -> [T] {
            guard let data = data else {
                throw RequestError.invalidResponse(statusCode: statusCode, data: data)
            }

            return try Mapper<T>(context: context).mapArray(JSONObject: data)
        }

    }

    class ObjectDictionaryMapper<T: ImmutableMappable>: IApiMapper {
        private let context: MapContext?

        init(context: MapContext? = nil) {
            self.context = context
        }

        func map(statusCode: Int, data: Any?) throws -> [String: T] {
            guard let data = data else {
                throw RequestError.invalidResponse(statusCode: statusCode, data: data)
            }

            return try Mapper<T>(context: context).mapDictionary(JSONObject: data)
        }

    }

    public enum ObjectMapperError: Error {
        case mappingError
    }

}
