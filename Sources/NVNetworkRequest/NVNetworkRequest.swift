import Foundation
import Alamofire

public enum Environment {
    case developement
    case staging
    case production

    var baseURL: String {
        switch self {
        case .developement: return ""
        case .staging: return ""
        case .production: return ""
        }
    }

}

public enum APIPath: String {
    case unknown
}

extension APIPath {
    var endpoint: Endpoint {
        Endpoint(path: self)
    }
}

public struct Endpoint {
    let path: APIPath
    static public private(set) var environment: Environment?

    var url: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.environment?.baseURL
        components.path = "/" + path.rawValue

        guard let url = components.url else {
            preconditionFailure(
                "Invalid URL components: \(components)"
            )
        }

        return url
    }

    static func configureEnvironment(_ environment: Environment) {
        self.environment = environment
    }
}

public class NVNetworkRequest {

    // MARK: - Properties

    public private(set) var dataRequest: DataRequest?
    var cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy
    var timeoutInterval: TimeInterval = 15.0
    var printCurl: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }

    var defaultHeaders = HTTPHeaders()

    // MARK: - Cancel

    func cancel() {
        dataRequest?.cancel()
        dataRequest = nil
    }

    func cancelAll(
        completingOnQueue queue: DispatchQueue = .main,
        completion: (() -> Void)? = nil
    ) {
        AF.cancelAllRequests(completingOnQueue: queue, completion: completion)
    }

    // MARK: - Request

    func sendRequest<T: Decodable>(
        endpoint: Endpoint,
        model: T.Type,
        method: HTTPMethod,
        interceptor: RequestInterceptor? = nil,
        params: Parameters? = nil,
        paramsEncoding: ParameterEncoding = URLEncoding.default,
        requestModifier: Session.RequestModifier? = nil,
        responseDecoder: JSONDecoder = JSONDecoder(),
        bearerToken: String? = UUID().uuidString,
        completion: @escaping ((Result<T, Error>) -> Void)
    ) {
        precondition(Endpoint.environment != nil, "[ERROR] Endpoint environment must be set!")

        let _cachePolicy = cachePolicy
        let _timeOutInterval = timeoutInterval

        var headers = defaultHeaders
        if let bearerToken = bearerToken {
            headers.add(.authorization(bearerToken: bearerToken))
        }

        dataRequest = AF.request(
            endpoint.url,
            method: method,
            parameters: params,
            encoding: paramsEncoding,
            headers: headers,
            requestModifier: { urlRequest in
                urlRequest.cachePolicy = _cachePolicy
                urlRequest.timeoutInterval = _timeOutInterval
            }
        ).responseDecodable(of: model, decoder: responseDecoder) { response in
            if let responseError = response.error {
                completion(.failure(responseError))
            }
            else if let model = response.value {
                completion(.success(model))
            }
        }.cURLDescription { description in
            if self.printCurl {
                print(description)
            }
        }
    }
}
