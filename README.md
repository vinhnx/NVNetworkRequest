# NVNetworkRequest

Alamofire network layer

### Installation

Add this to your Package dependencies:

```swift
 dependencies: [
   .package(url: "https://github.com/vinhnx/NVNetworkRequest", .upToNextMajor(from: "0.1.3"))
],
```

### Usage

Conform to `EndpointEnvironment` protocol with environment enum (eg: development, staging, production...):
```swift
import NVNetworkRequest

enum Enviroment: EndpointEnvironment {
    case development
    case staging
    case production

    var baseURL: String {
        switch self {
        case .development, .staging:
            return "staging.quotable.io"
        case .production:
            return "api.quotable.io"
        }
    }
}
```

Conform `EndpointPath` with any request request path:
```swift
enum APIPath: EndpointPath {
    case random

    var path: String {
        switch self {
        case .random: return "random"
        }
    }
}
```

Subclass `NVNetworkRequest`
```swift
class QuoteNetworkRequest: NVNetworkRequest {
    
    func fetch(
        tags: [String]? = nil,
        completion: @escaping ((Result<Quote, Error>) -> Void)
    ) {
        var params: Parameters = [:]
        if let tags = tags {
            params["tags"] = tags.joined(separator: ",")
        }

        sendRequest(endpoint: APIPath.random.endpoint, model: Quote.self, method: .get, params: params, paramsEncoding: URLEncoding.queryString, completion: completion)
    }
    
}
```

Then, configure API environment on app start, typically from AppDelegate didFinishLaunchingWithOptions:
```swift
Endpoint.configureEnvironment(Enviroment.production)
```

Usage:
```swift
        QuoteNetworkRequest().fetch { result in
            switch result {
            case .success(let response):
                debugPrint(response)
            case .failure(let error):
                debugPrint(error)
            }
        }
```
