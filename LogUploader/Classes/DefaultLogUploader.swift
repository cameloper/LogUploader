//
//  DefaultLogUploader.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation
import Alamofire
import XCGLogger

public struct DefaultLogUploader: LogUploader {
    
    /// URL of the uploader folder.
    public let homeURL: URL
    
    /// Public initializer
    public init() {
        let docsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        self.homeURL = URL(fileURLWithPath: "\(docsPath)/LogUploader", isDirectory: true)
    }
    
    /// Begin the process of log uploading
    public func upload(from destination: UploadableFileDestination, completion: LogUploadCompletion?) {
        // First get the configuration struct
        guard let conf = destination.uploaderConfiguration else {
            completion?(.failure(.missingConfiguration))
            return
        }
        
        // Get the url of upload file which was moved
        guard destination.finalize(),
            let uploadFileURL = destination.moveForUpload() else {
            completion?(.failure(.logFileError))
            return
        }
        
        do {
            // First get the URL request for upload
            let urlRequest = try generateUrlRequest(fileUrl: uploadFileURL, conf: conf)
            
            // Make request and get response from server
            Alamofire.request(urlRequest).validate().response { response in
                if let error = response.error {
                    let networkError = NetworkError(response: response.response, error: error)
                    // Do the cleanup, if failed, log
                    if !self.cleanup(false, fileURL: uploadFileURL, conf.storeFailedUploads) {
                        destination.owner?.warning("File handling operation of failed log upload failed!")
                    }
                    
                    completion?(.failure(.network(networkError)))
                    
                } else {
                    // Do the cleanup, if failed, log
                    if !self.cleanup(true, fileURL: uploadFileURL, conf.storeSuccessfulUploads) {
                        destination.owner?.warning("File handling operation of successful log upload failed!")
                    }
                    
                    completion?(.success)
                    // If configuration demands auto retrying of failed logs -
                    if conf.autoRetryFailedUploads {
                        switch self.hasFailedLogs(destination) {
                        // - and there are failed logs to be uploaded,
                        case true:
                            // upload them.
                            destination.owner?.info("Auto retrying the failed logs of \(destination.identifier)")
                            self.uploadFailedLogs(from: destination, completion: nil)
                        case false:
                            destination.owner?.debug("Good to go! There are no failed logs to upload from destination \(destination.identifier).")
                        }
                    }
                }
            }
            
        } catch (let error) {
            completion?(.failure(.missingRequest(error)))
        }
    }
    
    /// Returns whether the destination has failed logs or not
    /// - parameter destination: The destination whose logs will be uploaded
    /// - Returns:
    ///     - true: The destination has failed logs that needs to be uploaded
    ///     - false: The destination has no failed logs that needs to be uploaded
    func hasFailedLogs(_ destination: UploadableFileDestination) -> Bool {
        // Get the base URL of destination and the failed folder URL
        let destURL = homeURL.appendingPathComponent(destination.identifier, isDirectory: true)
        let failedURL = destURL.appendingPathComponent("failed")
        let fileManager = FileManager()
        
        do {
            // If failed folder doesn't exist, return false
            var objFalse: ObjCBool = false
            if !fileManager.fileExists(atPath: failedURL.path, isDirectory: &objFalse) {
                return false
            }
            
            // Get all files in folder
            let files = try fileManager.contentsOfDirectory(at: failedURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            
            // Filter files and get only with valid extension
            let logFiles = files.filter { $0.pathExtension == destination.defaultFileExtension }
            
            return !logFiles.isEmpty
            
        } catch (let error) {
            destination.owner?.warning("An error occured when trying to get the failed logs of \(destination.identifier). Returning false! \(error)")
            return false
        }
    }
    
    /// If wanted, move file to successful/failed folder. Otherwise delete
    /// - Parameters:
    ///     - folderURL: The url of destinations upload folder
    ///     - fileURL: The url to the log file
    ///     - store: Boolean that decides whether to store the file or not
    /// - Returns:
    ///     - true: Operation successful
    ///     - false: Operation failed
    func cleanup(_ successful: Bool, fileURL: URL, _ store: Bool) -> Bool {
        // Set folder name depending on success
        let folderName = successful ? "successful" : "failed"
        let fileManager = FileManager()
        // Get file name
        let fileName = fileURL.lastPathComponent
        // Get folder URL we'll copy the file to
        let folderURL = fileURL.deletingLastPathComponent().appendingPathComponent(folderName, isDirectory: true)
        
        do {
            switch store {
            case true:
                // Check if destination exist and if not, create folder
                var objTrue: ObjCBool = true
                if !fileManager.fileExists(atPath: folderURL.path, isDirectory: &objTrue) {
                    try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                }
                
                /// New file url for moving operation (in successful/failed)
                let sFileURL = folderURL.appendingPathComponent("\(fileName)", isDirectory: false)
                try fileManager.moveItem(at: fileURL, to: sFileURL)
            case false:
                try fileManager.removeItem(at: fileURL)
            }
            return true
        } catch {
            return false
        }
    }
    
    /// Gets the failed logs from before and passes them to `uploadFailedLog` method
    /// - Parameters:
    ///     - destination: The CustomFileDestination we'll upload the logs from
    ///     - completion: Completion closure that passes the results
    public func uploadFailedLogs(from destination: UploadableFileDestination, completion: LogUploadsCompletion?) {
        // Get the configuration
        guard let conf = destination.uploaderConfiguration else {
            completion?([LUResult(destinationId: destination.identifier, logFileName: nil, result: .failure(.missingConfiguration))])
            return
        }
        
        // Get the base URL of destination and the failed folder URL
        let destURL = homeURL.appendingPathComponent(destination.identifier, isDirectory: true)
        let failedURL = destURL.appendingPathComponent("failed")
        let fileManager = FileManager()
        
        do {
            // Get all files in folder
            let files = try fileManager.contentsOfDirectory(at: failedURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            
            // Filter files and get only with valid extension
            let logFiles = files.filter { $0.pathExtension == destination.defaultFileExtension }
            var results = LUResults()
            
            // Execute method for all files
            for logFile in logFiles {
                let newURL = destURL.appendingPathComponent(logFile.lastPathComponent)
                // Move file to the main directory to prevent issues during cleanup
                try fileManager.moveItem(at: logFile, to: newURL)
                uploadFailedLog(logger: destination.owner, fileURL: newURL, conf: conf) { result in
                    results.append(LUResult(destinationId: destination.identifier, logFileName: logFile.lastPathComponent, result: result))
                }
            }
            
            completion?(results)
            
        } catch {
            completion?([LUResult(destinationId: destination.identifier, logFileName: nil, result: .failure(.logFileError))])
        }
    }
    
    /// Uploads the failed logFile
    /// - Parameters:
    ///     - logger: The XCGLogger object to be able to log errors etc.
    ///     - fileURL: LogFile that'll be uploaded
    ///     - conf: Configuration file for the upload
    ///     - completion: The completion closure that passes the result
    func uploadFailedLog(logger: XCGLogger?, fileURL: URL, conf: LogUploaderConfiguration, completion: LogUploadCompletion?) {
        do {
            // Generate URL request
            let request = try generateUrlRequest(fileUrl: fileURL, conf: conf)
            
            Alamofire.request(request).validate().response { response in
                if let error = response.error {
                    let networkError = NetworkError(response: response.response, error: error)
                    // Do the cleanup, if failed, log
                    if !self.cleanup(false, fileURL: fileURL, conf.storeFailedUploads) {
                        logger?.warning("File handling operation of failed log upload failed!")
                    }
                    
                    completion?(.failure(.network(networkError)))
                } else {
                    // Do the cleanup, if failed, log
                    if !self.cleanup(true, fileURL: fileURL, conf.storeSuccessfulUploads) {
                        logger?.warning("File handling operation of successful log upload failed!")
                    }
                    
                    completion?(.success)
                }
            }
        } catch (let error) {
            completion?(.failure(.missingRequest(error)))
        }
    }
    
    /// Generates the URL Request for Alamofire
    /// - Parameters:
    ///     - fileUrl: URL of the logFile that'll be sent
    ///     - conf: Configuration object for the request
    /// - Returns: `URLRequest` object for alamofire
    public func generateUrlRequest(fileUrl: URL, conf: LogUploaderConfiguration) throws -> URLRequest {
        var conf = conf.uploadConf
        
        // Get the log file as data to append it in parameters
        let logFileData = try Data(contentsOf: fileUrl).base64EncodedString()
        conf.parameters["logFileData"] = logFileData
        
        // Add date as parameter using file name. This'll help especially with old (failed) uploads.
        let fileName = fileUrl.deletingPathExtension().lastPathComponent
        conf.parameters["date"] = fileName
        
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
