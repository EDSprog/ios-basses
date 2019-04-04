import Foundation
import Alamofire
import RxSwift
import JSONDecoder_Keypath

let EncodeKey = CodingUserInfoKey(rawValue: "encode")!
typealias ProgressHandler = ((Progress) -> Void)

protocol ApiErrorProtocol: Error, Decodable {}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

protocol ApiManagerDelegate: class {
    func apiManagerNeedsRelogin()
}

class ApiManager<ApiErrorT: ApiErrorProtocol> {
    private let _apiPrefix: String
    private let _bgScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    
    var headers: [String: String] = [:]
    var authHeaders: [String: String] = [:]
    
    weak var delegate: ApiManagerDelegate?
    
    init(apiPrefix: String) {
        _apiPrefix = apiPrefix
    }
    
    private var _allHeaders: [String: String] {
        var allheaders = headers
        
        authHeaders.forEach {allheaders[$0] = $1}
        return allheaders
    }
    
    func getVoid(_ endpoint: String, query: [String: CustomStringConvertible]? = nil) -> Completable {
        return callApi(endpoint: endpoint, method: .get, query: query).asCompletable()
            .observeOn(MainScheduler.instance)
    }
    
    func getVoid(_ endpoint: String, dst: URL, query: [String: CustomStringConvertible]? = nil) -> Completable {
        return downloadFile(endpoint, dst: dst, method: .get)
    }
    
    func get<ResultT: Decodable>(_ endpoint: String, query: [String: CustomStringConvertible]? = nil, keyPath: String = "data") -> Single<ResultT> {
        return callApi(endpoint: endpoint, method: .get, query: query)
            .map {try ApiManager.decodeBody($0, keyPath: keyPath)}
            .observeOn(MainScheduler.instance)
    }
    
    func get<T: Decodable>(_ endpoint: String, query: [URLQueryItem]?, keyPath: String = "") -> Single<T> {
        return callApi(endpoint: endpoint, method: .get, queryItems: query)
            .map {try ApiManager.decodeBody($0, keyPath: keyPath)}
            .observeOn(MainScheduler.instance)
    }
    
    func downloadVoid(_ endpoint: String, destination: URL, query: [String: CustomStringConvertible]? = nil, progressHandler: ProgressHandler? = nil ) -> Completable {
        return makeRequest(endpoint, method: .get)
            .flatMapCompletable {
                return self.sendDownloadRequest(request: $0.0, isAuthorized: $0.1, dst: destination, progressHandler: progressHandler)
            }.observeOn(MainScheduler.instance)
    }
    
    func postVoid(_ endpoint: String, params: [String: Any]) -> Completable {
        return callApi(endpoint: endpoint, method: .post, bodyDict: params).asCompletable()
            .observeOn(MainScheduler.instance)
    }
    
    func postVoid<BodyT: Encodable>(_ endpoint: String, dst: URL, body: BodyT) -> Completable {
        do {
            return downloadFile(endpoint, dst: dst, method: .post, body: try ApiManager.encodeBody(body))
                .observeOn(MainScheduler.instance)
        } catch {
            return Completable.error(error)
        }
    }
    
    func postVoid<T: Encodable>(_ endpoint: String, body: T) -> Completable {
        return callApi(endpoint: endpoint, method: .post, bodyEncodable: body)
            .asCompletable()
            .observeOn(MainScheduler.instance)
    }
    
    func post<ResultT: Decodable>(_ endpoint: String, params: [String: Any], keyPath: String = "data") -> Single<ResultT> {
        return callApi(endpoint: endpoint, method: .post, bodyDict: params)
            .map {try ApiManager.decodeBody($0, keyPath: keyPath)}
            .observeOn(MainScheduler.instance)
    }
    
    func post<ResultT: Decodable>(_ endpoint: String,
                                  params: [String: Any],
                                  query: [String: CustomStringConvertible]? = nil,
                                  keyPath: String = "data") -> Single<ResultT>
    {
        return callApi(endpoint: endpoint, method: .post, query: query, bodyDict: params)
            .map {try ApiManager.decodeBody($0, keyPath: keyPath)}
            .observeOn(MainScheduler.instance)
    }
    
    func post<BodyT: Encodable, ResultT: Decodable>(_ endpoint: String,
                                                    body: BodyT,
                                                    query: [String: CustomStringConvertible]? = nil,
                                                    keyPath: String = "data") -> Single<ResultT>
    {
        return callApi(endpoint: endpoint, method: .post, query: query, bodyEncodable: body)
            .map{try ApiManager.decodeBody($0, keyPath: keyPath)}
            .observeOn(MainScheduler.instance)
    }
    
    func put<ResultT: Decodable>(_ endpoint: String,
                                 params: [String: Any],
                                 query: [String: CustomStringConvertible]? = nil,
                                 keyPath: String = "data") -> Single<ResultT>
    {
        return callApi(endpoint: endpoint, method: .put, query: query, bodyDict: params)
            .map {try ApiManager.decodeBody($0, keyPath: keyPath)}
            .observeOn(MainScheduler.instance)
    }
    
    func putVoid(_ endpoint: String, params: [String: Any]) -> Completable {
        return callApi(endpoint: endpoint, method: .put, bodyDict: params).asCompletable()
            .observeOn(MainScheduler.instance)
    }
    
    private func sendRequest(request: URLRequest) -> Single<(HTTPURLResponse, Data)> {
        DebugLog("(\(request.httpMethod ?? "") request: \(request.description)")
        DebugLog("Body: \(request.httpBody?.toString() ?? "empty")")
        DebugLog("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        return Single.create {single in
            let request = Alamofire.request(request).response(completionHandler: {response in
                #if DEBUG
                print("\(response.data?.toString() ?? "")")
                #endif
                
                if let error = response.error {
                    single(.error(error))
                } else if let httpResponse = response.response {
                    single(.success((httpResponse, response.data ?? Data())))
                } else {
                    single(.error(AppError.internal("Alamofire.request failed")))
                }
            })
            
            return Disposables.create {request.cancel()}
            }.observeOn(_bgScheduler)
    }
    
    private func sendDataRequest(request: URLRequest, isAuthorized: Bool) -> Single<Data> {
        return sendRequest(request: request).map {response, data in
            if 200...299 ~= response.statusCode {
                let response: ApiResponse = try ApiManager.decodeBody(data)
                if response.success {
                    return data
                }
            } else if isAuthorized && response.statusCode == 401 {
                DispatchQueue.main.async {
                    self.delegate?.apiManagerNeedsRelogin()
                }
                throw AppError.auth()
            }
            
            let decoder = JSONDecoder()
            let error: ApiErrorT
            
            do {
                error = try decoder.decode(ApiErrorT.self, from: data)
            } catch {
                throw AppError.regular("Server error \(response.statusCode)")
            }
            
            throw error
        }
    }
    
    private func sendDownloadRequest(request: URLRequest, isAuthorized: Bool, dst: URL, progressHandler: ProgressHandler? = nil) -> Completable {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (dst, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        return Completable.create {complete in
            let dlRequest = Alamofire.download(request, to: destination).response {rsp in
                if let error = rsp.error {
                    complete(.error(error))
                } else if let response = rsp.response {
                    if  200...299 ~= response.statusCode {
                        do {
                            let data = try Data(contentsOf: dst)
                            let apiResponse: ApiResponse = try ApiManager.decodeBody(data)
                            if apiResponse.success {
                                complete(.completed)
                            } else {
                                complete(.error(AppError.regular(apiResponse.errors?.first?.value ?? "Download server error \(response.statusCode)")))
                            }
                        } catch {
                            complete(.completed)
                        }
                    } else {
                        if isAuthorized && response.statusCode == 401 {
                            DispatchQueue.main.async {
                                self.delegate?.apiManagerNeedsRelogin()
                            }
                            complete(.error(AppError.auth()))
                            return
                        }
                        
                        let decoder = JSONDecoder()
                        let error: ApiErrorT
                        
                        do {
                            let data = try Data(contentsOf: dst)
                            error = try decoder.decode(ApiErrorT.self, from: data)
                            complete(.error(error))
                        } catch {
                            complete(.error(AppError.regular("Server error \(response.statusCode)")))
                        }
                    }
                } else {
                    complete(.error(AppError.internal("Internal error")))
                }
            }
            
            dlRequest.downloadProgress(closure: { progress in
                progressHandler?(progress)
            })
            
            return Disposables.create {dlRequest.cancel()}
        }
    }
    
    private func callApi(endpoint: String,
                         method: HTTPMethod,
                         query: [String: CustomStringConvertible]? = nil,
                         bodyDict: [String: Any]? = nil) -> Single<Data>
    {
        return makeRequest(endpoint, method: method, query: query)
            .flatMap {result in
                var request = result.0
                
                if let bodyDict = bodyDict {
                    request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
                }
                
                return self.sendDataRequest(request: request, isAuthorized: result.1)
        }
    }
    
    private func callApi(endpoint: String,
                         method: HTTPMethod,
                         queryItems: [URLQueryItem]?,
                         bodyDict: [String: Any]? = nil) -> Single<Data>
    {
        return makeRequest(endpoint, method: method, queryItems: queryItems)
            .flatMap {result in
                var request = result.0
                
                if let bodyDict = bodyDict {
                    request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
                }
                return self.sendDataRequest(request: request, isAuthorized: result.1)
        }
    }
    
    private func callApi<EncodableT: Encodable>(endpoint: String,
                                                method: HTTPMethod,
                                                query: [String: CustomStringConvertible]? = nil,
                                                bodyEncodable: EncodableT) -> Single<Data>
    {
        return makeRequest(endpoint, method: method, query: query)
            .flatMap {result in
                var request = result.0
                
                request.httpBody = try ApiManager.encodeBody(bodyEncodable)
                return self.sendDataRequest(request: request, isAuthorized: result.1)
        }
    }
    
    private static func encodeBody<BodyT: Encodable>(_ body: BodyT) throws -> Data {
        let encoder = JSONEncoder()
        
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        encoder.userInfo = [EncodeKey: true]
        
        return try encoder.encode(body)
    }
    
    private static func decodeBody<ResultT: Decodable>(_ data: Data, keyPath: String? = nil) throws -> ResultT {
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            if let kp = keyPath, !kp.isEmpty {
                return try decoder.decode(ResultT.self, from: data, keyPath: kp)
            }
            return try decoder.decode(ResultT.self, from: data)
        } catch {
            DebugLog(error.localizedDescription)
            throw AppError.regular("Bad server response")
        }
    }
    
    private func downloadFile(_ endpoint: String, dst: URL, method: HTTPMethod, body: Data? = nil) -> Completable {
        return makeRequest(endpoint, method: method)
            .flatMapCompletable {result -> Completable in
                var request = result.0
                
                request.httpBody = body
                return self.sendDownloadRequest(request: request, isAuthorized: result.1, dst: dst)
        }
    }
    
    private func makeRequestImpl(_ endpoint: String, method: HTTPMethod, query: [String: CustomStringConvertible]? = nil) throws -> URLRequest {
        guard var components = URLComponents(string: _apiPrefix + endpoint) else {
            throw AppError.internal("Bad endpoint url")
        }
        
        components.queryItems = query?.map {URLQueryItem(name: $0.key, value: $0.value.description)}
        
        guard let url = components.url else {
            throw AppError.internal("buildUrl failed")
        }
        
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10000)
        
        req.httpMethod = method.rawValue
        req.allHTTPHeaderFields = _allHeaders
        return req
    }
    
    private func makeRequest(_ endpoint: String, method: HTTPMethod, query: [String: CustomStringConvertible]? = nil)  -> Single<(URLRequest, Bool)> {
        return Single<Void>.just((), scheduler: MainScheduler.instance)
            .map {_ in (try self.makeRequestImpl(endpoint, method: method, query: query),
                        !self.authHeaders.isEmpty)}
            .observeOn(_bgScheduler)
    }
    
    private func makeRequest(_ endpoint: String, method: HTTPMethod, queryItems: [URLQueryItem]?)  -> Single<(URLRequest, Bool)> {
        return Single<Void>.just((), scheduler: MainScheduler.instance)
            .map {_ in (try self.makeRequestImpl(endpoint, method: method, queryItems: queryItems),
                        !self.authHeaders.isEmpty)}
            .observeOn(_bgScheduler)
    }
    
    private func makeRequestImpl(_ endpoint: String, method: HTTPMethod, queryItems: [URLQueryItem]?) throws -> URLRequest {
        guard var components = URLComponents(string: _apiPrefix + endpoint) else {
            throw AppError.internal("Bad endpoint url")
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw AppError.internal("buildUrl failed")
        }
        
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10000)
        
        req.httpMethod = method.rawValue
        req.allHTTPHeaderFields = _allHeaders
        return req
    }
}
