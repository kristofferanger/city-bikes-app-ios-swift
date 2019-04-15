//
//  ApiHelpers.swift
//  CityBikesApp
//
//  Created by Kristoffer Anger on 2019-03-08.
//  Copyright © 2019 kriang. All rights reserved.
//

let API_KEY = ""
let BASE_URL = "api.citybik.es/v2/networks"
let TIMEOUT = 15.0

class APIHelpers {
    
    class func makeRequest(withEndpoint endpoint:String, paramters: [String: Any], completion:@escaping (_ response:[String : Any] ) -> Void) -> URLSessionDataTask? {
        
        // create request with url - base, path and queries
        // reason for optional URLSessionDataTask - url method in URLComponents can return nil
        guard let url = makeURL(withPath: endpoint, parameters: paramters) else {
            return nil
        }
        print("Request URL:\(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = TimeInterval(TIMEOUT)
        
        // make request and parse the data
        let dataTask = URLSession.shared.dataTask(with:request, completionHandler:{ data, urlResponse, error in
        
            var response: [String : Any]

            if let jsonData = serializeJsonWith(data: data) {
                
                response = ["result": jsonData]
            }
            else {
                response = ["error": error ?? NSError(domain: "UnknownErrorTypeDomain", code: 0, userInfo: [NSLocalizedDescriptionKey:"An unknown error occured"]) as Error]
            }

            // returning data on main thread
            DispatchQueue.main.async(execute:{
                completion(response)
            })
        })

        dataTask.resume()
        return dataTask
    }
    
    // MARK:- helper methods
    class func serializeJsonWith(data: Data?) -> Any? {
        
        // serialize json data
        // returns nil if operation fails or json is not an array or dictionary
        var returnValue : Any?
        
        if data != nil {
            let jsonObject = try? JSONSerialization.jsonObject(with: data!, options:.allowFragments)
            returnValue = jsonObject
        }
        return returnValue
    }
    
    
    class func makeURL(withPath path: String, parameters: [String : Any]) -> URL? {
        
        // create queries
        var queryItems = [AnyHashable]()
        
        // add api key by default if it exists
        if API_KEY.count > 0 {
            queryItems.append(URLQueryItem(name:"api_key", value:API_KEY))
        }
        
        // add rest of parameters
        for (key, value) in parameters {
            queryItems.append(URLQueryItem(name:key, value:"\(value)"))
        }
        
        // build URL
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.path = BASE_URL + (path)
        urlComponents.queryItems = queryItems as? [URLQueryItem]
        
        return urlComponents.url
    }
}
