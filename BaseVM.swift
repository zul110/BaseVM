//
//  BaseVM.swift
//  BaseVM
//
//  Created by Zul on 8/22/17.
//
//

import Foundation
import AFNetworking
import AlamofireObjectMapper
import ObjectMapper

class BaseViewModel: BaseViewModelDelegate {
    // MARK: Constants
    let failureTimerSeconds: Double = 5.0
    let cacheDuration: Int = 604800             // One Week
    
    // MARK: Internal Variables
    var delegate: BaseViewModelDelegate!
    
    var apiToUse: String!
    var parameters: NSDictionary!
    var jsonResponse: String!
    
    var timer: Timer!
    
    var autoRetry: Bool = true
    
    // MARK: Properties
    var isLoading: Bool! {
        didSet {
            
        }
    }
    
    var isConnected: Bool! {
        didSet {
            
        }
    }
    
    var hasError: Bool! {
        didSet {
            
        }
    }
    
    var hasContent: Bool! {
        didSet {
            
        }
    }
    
    // MARK: Constructor(s)
    init() {
        self.setDelegate(delegate: self)
        
        self.parameters = NSMutableDictionary()
        self.parameters.setValue("eng", forKey: "lang")
    }
    
    // MARK: Member Functions
    func setDelegate(delegate: BaseViewModelDelegate) {
        self.delegate = delegate
    }
    
    // MARK: HTTP Functions
    func getResponse(usingHttpMethod method: HTTPMethod, onAPI api: String, withParameters parameters: NSDictionary?, andSuccessBlock success: @escaping (_ response: JSON) -> Void) {
        let urlString = getUrl(api: api, parameters: parameters) as String
        let token = Settings.instance.getString(key: KEY_TOKEN)
        
        let manager = AFHTTPSessionManager()
        //manager.forceCacheResponse(duration: self.cacheDuration)
        manager.requestSerializer = AFHTTPRequestSerializer()
        manager.requestSerializer.cachePolicy = .returnCacheDataElseLoad
        manager.requestSerializer.setValue("application/json", forHTTPHeaderField: "Accept")
        manager.requestSerializer.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        manager.responseSerializer = AFHTTPResponseSerializer()
        
        if Utils.hasInternetConnection() {
            self.isConnected = true
            
            switch method {
            case .GET:
                getGetResponse(manager: manager, urlString: urlString, parameters: parameters, successBlock: success)
                break
            case .POST:
                getPostResponse(manager: manager, urlString: urlString, parameters: parameters, successBlock: success)
                break
            }
        } else {
            self.isConnected = false
            self.hasError = true
        }
    }
    
    private func getGetResponse(manager: AFHTTPSessionManager, urlString: String, parameters: NSDictionary?, successBlock: @escaping (_ response: JSON) -> Void) {
        manager.get(urlString, parameters: parameters, progress: nil, success: {
            (task: URLSessionDataTask!, responseObject: Any!) in
            
            self.requestSuccess(task: task, responseObject: responseObject, successBlock: successBlock)
        }, failure: {
            requestOperation, error in
            
            self.hasError = true
            
            self.requestFailure(requestOperation: requestOperation, error: error)
        })
    }
    
    private func getPostResponse(manager: AFHTTPSessionManager, urlString: String, parameters: NSDictionary?, successBlock: @escaping (_ response: JSON) -> Void) {
        manager.post(urlString, parameters: parameters, progress: nil, success: {
            (task: URLSessionDataTask!, responseObject: Any!) in
            
            self.requestSuccess(task: task, responseObject: responseObject, successBlock: successBlock)
        }, failure: {
            requestOperation, error in
            
            self.hasError = true
            
            self.requestFailure(requestOperation: requestOperation, error: error)
        })
    }
    
    func requestSuccess(task: URLSessionDataTask!, responseObject: Any!, successBlock: @escaping (_ response: JSON) -> Void) {
        print("success")
        
        let httpResponse = task.response as! HTTPURLResponse
        let responseCode = httpResponse.statusCode
        
        if let tempResponse: AnyObject = responseObject as AnyObject? {
            switch (responseCode) {
            // OK
            case 200:
                let data: Data = tempResponse as! Data
                let response = JSON(data: data, options: JSONSerialization.ReadingOptions.allowFragments, error: nil)
                
                self.hasContent = response != ""
                
                successBlock(response)
                
                break
            default:
                break
            }
        }
    }
    
    func requestFailure(requestOperation: URLSessionDataTask!, error: Error) {
        print("\(error.localizedDescription)")
        
        var statusCode: Int!
        
        if requestOperation?.response != nil {
            statusCode = (requestOperation?.response as! HTTPURLResponse).statusCode
        }
        
        let errorMessage = String(data: (error as NSError).userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as! Data, encoding: String.Encoding.utf8)
        
        self.handleFailure(errorMessage: errorMessage!, statusCode: statusCode, error: error)
    }
    
    func getUrl(api: String, parameters: NSDictionary?) -> String {
        let url = getApiWithParameters(api: api, parameters: parameters)
        
        return url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    }
    
    func getApiWithParameters(api: String, parameters: NSDictionary?) -> String {
        var url: String = api
        
        if parameters != nil {
            let apiWithParameters = NSMutableString(string: "\(api)?")
            let parametersArray = NSMutableArray() //holds strings extracted from dictionary
            let keys: NSArray = parameters!.allKeys as NSArray //holds keys in the dictionary
            
            for key in keys {
                let value: AnyObject = parameters!.object(forKey: key)! as AnyObject
                
                if value is NSArray {
                    let array: NSArray = parameters!.object(forKey: key)! as! NSArray
                    
                    for value in array {
                        parametersArray.add("\(key)[]=\(value)")
                    }
                } else {
                    parametersArray.add("\(key)=\(value)")
                }
            }
            
            for parameter in parametersArray {
                let index = parametersArray.index(of: parameter) as Int
                if index != 0 {
                    apiWithParameters.append("&\(parameter)")
                } else {
                    apiWithParameters.append("\(parameter)")
                }
            }
            
            url = apiWithParameters as String
        }
        
        return url
    }
    
    func handleFailure(errorMessage: String, statusCode: Int, error: Error) {
        self.hasError = true
        self.hasContent = false
        
        switch statusCode {
        // Bad Request
        case 400:
            print("400 (Bad Request): \(errorMessage)")
            
            break
            
        // Unauthorized
        case 401:
            print("401 (Unauthorized): \(errorMessage)")
            
            break
            
        // Not Found
        case 404:
            print("404 (Not Found): \(errorMessage)")
            
        // Internal Server Error
        case 500:
            print("500 (Internal Server Error): \(errorMessage)")
            
            break
            
        default:
            break
        }
        
        if autoRetry {
            self.timer = Timer.scheduledTimer(withTimeInterval: self.failureTimerSeconds, repeats: true, block: failureTimerTick(timer:))
        }
    }
    
    func failureTimerTick(timer: Timer) {
        self.timer.invalidate()
        self.getData()
    }
    
    // MARK: Delegate Functions
    func dataDidLoad() {
        print("Base dataDidLoad")
        self.isLoading = false
    }
    
    // MARK: Abstract Functions
    func getData() {
        preconditionFailure("Abstract function: BaseViewModel.getData()")
    }
    
    func displayData() {
        preconditionFailure("Abstract function: BaseViewModel.displayData()")
    }
    
    func success(response: JSON) {
        preconditionFailure("Abstract function: BaseViewModel.success(response:)")
    }
}
