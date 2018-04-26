//
//  DefaultLogUploader.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation
import Alamofire

public struct DefaultLogUploader: LogUploader {
    
    public let homeURL: URL
    
    /// Public initializer
    public init() {
        let docsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        self.homeURL = URL(fileURLWithPath: "\(docsPath)/LogUploader", isDirectory: true)
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
                }
            }
            
        } catch (let error) {
            completion?(.failure(.missingRequest(error)))
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
    
    /// Gets the failed logs from before and uploads them
    /// - Parameters:
    ///     - destination: The CustomFileDestination we'll upload the logs from
    ///     - completion:
    public func uploadFailedLogs(from destination: CustomFileDestination, completion: LogUploadsCompletion?) {
        guard let conf = destination.uploaderConfiguration else {
            completion?([LUResult(destinationId: destination.identifier, logFileName: nil, result: .failure(.missingConfiguration))])
            return
        }
        
        let destURL = homeURL.appendingPathComponent(destination.identifier, isDirectory: true)
        let failedURL = destURL.appendingPathComponent("failed")
        let fileManager = FileManager()
        do {
            let files = try fileManager.contentsOfDirectory(at: failedURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            let logFiles = files.filter { $0.pathExtension == destination.defaultFileExtension }
            var results = LUResults()
            for logFile in logFiles {
                uploadFailedLog(destination: destination, fileURL: logFile, conf: conf) { result in
                    results.append(LUResult(destinationId: destination.identifier, logFileName: logFile.lastPathComponent, result: result))
                }
            }
            
            completion?(results)
            
        } catch {
            completion?([LUResult(destinationId: destination.identifier, logFileName: nil, result: .failure(.logFileError))])
        }
    }
    
    func uploadFailedLog(destination: CustomFileDestination, fileURL: URL, conf: LogUploaderConfiguration, completion: LogUploadCompletion?) {
        do {
            let request = try generateUrlRequest(fileUrl: fileURL, conf: conf)
            Alamofire.request(request).validate().response { response in
                if let error = response.error {
                    let networkError = NetworkError(response: response.response, error: error)
                    // Do the cleanup, if failed, log
                    if !self.cleanup(false, fileURL: fileURL, conf.storeFailedUploads) {
                        destination.owner?.warning("File handling operation of failed log upload failed!")
                    }
                    
                    completion?(.failure(.network(networkError)))
                } else {
                    // Do the cleanup, if failed, log
                    if !self.cleanup(true, fileURL: fileURL, conf.storeSuccessfulUploads) {
                        destination.owner?.warning("File handling operation of successful log upload failed!")
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

/// Extension to handle the file operation DefaultLogUploader requires
extension CustomFileDestination {
    
    /// Move the file to a new location before starting the upload
    /// to allow new logs to be written during upload process
    open func prepareFileForUpload() -> URL? {
        // Close file to prevent conflicts
        self.closeFile()
        let fileManager = FileManager()
        guard fileManager.fileExists(atPath: fileURL.path) else {
            // File or url doesn't exist
            return nil
        }
        
        // Get the home url of our logger
        guard let homeURL = self.uploaderConfiguration?.uploader.homeURL else {
            // Home folder URL isn't present
            return nil
        }
        
        // Set URL of upload file folder
        let uploadFolderURL = homeURL.appendingPathComponent("\(self.identifier)", isDirectory: true)
        // Name of the file should be the current date in Apple's format
        let date = Date().timeIntervalSinceReferenceDate
        let uploadFileURL = uploadFolderURL.appendingPathComponent("\(date).\(self.defaultFileExtension)", isDirectory: true)
        
        do {
            // Check if destination exist and if not, create folder
            var objTrue: ObjCBool = true
            if !fileManager.fileExists(atPath: uploadFolderURL.path, isDirectory: &objTrue) {
                try fileManager.createDirectory(at: uploadFolderURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Delete existing upload file
            if fileManager.fileExists(atPath: uploadFileURL.path) {
                try fileManager.removeItem(at: uploadFileURL)
            }
            
            //  Move log file
            try fileManager.moveItem(at: fileURL, to: uploadFileURL)
            
        } catch (let error) {
            self.owner?.error("An error occured during file operations. \(error)")
            return nil
        }
        
        // Open file
        self.openFile()
        // Write all waiting logs
        self.flush()
        
        return uploadFileURL
    }
}
