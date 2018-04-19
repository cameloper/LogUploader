//
//  DefaultLogUploader.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation
import Alamofire

public struct DefaultLogUploader: LogUploader {
    /// Public initializer
    public init() {
        return
    }
    
    /// Begin the process of log uploading
    public func upload(from destination: CustomFileDestination, completion: LogUploadCompletion?) {
        // First get the configuration struct
        guard let conf = destination.uploaderConfiguration else {
            completion?(.failure(.missingConfiguration))
            return
        }
        
        // Get the url of upload file which was moved
        guard let uploadFileURL = destination.prepareFileForUpload() else {
            completion?(.failure(.logFileError))
            return
        }
        
        do {
            let urlRequest = try generateUrlRequest(fileUrl: uploadFileURL, conf: conf)
            
            // Make request and get response from server
            Alamofire.request(urlRequest).validate().response { response in
                if let error = response.error {
                    let networkError = NetworkError(response: response.response, error: error)
                    completion?(.failure(.network(networkError)))
                } else {
                    completion?(.success)
                }
            }
            
        } catch (let error) {
            completion?(.failure(.missingRequest(error)))
        }
    }
    
    /// Generates the URL Request for Alamofire
    public func generateUrlRequest(fileUrl: URL, conf: LogUploaderConfiguration) throws -> URLRequest {
        var conf = conf.uploadConf
        
        // Get the log file as data to append it in parameters
        let logFileData = try Data(contentsOf: fileUrl).base64EncodedString()
        conf.parameters["logFile"] = logFileData
        
        var urlRequest = try URLRequest(url: conf.requestURL, method: .post)
        
        // Encode the request with parameters
        urlRequest = try conf.parameterEncoding.encode(urlRequest, with: conf.parameters)
        
        // Execute the headers closure to get required HTTP header such as authentication tokens
        if let headers = conf.headers?() {
            for (field, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        return urlRequest
    }
    
}
