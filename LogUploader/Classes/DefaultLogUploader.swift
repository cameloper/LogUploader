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
        // Get folder URL
        let folderURL = fileURL.deletingLastPathComponent()
        do {
            switch store {
            case true:
                /// URL of the new folder the file is going to get moved to. (successful/failed)
                let sFileURL = folderURL.appendingPathComponent("\(folderName)/\(fileName)", isDirectory: false)
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
    public func uploadFailedLogs(from destination: CustomFileDestination, completion: LogUploadCompletion?) {
        completion?(.success)
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
        
        // Get upload path
        let docsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let uploadFilePath = "\(docsPath)/\(self.identifier)/\(Date().timeIntervalSinceReferenceDate).\(self.defaultFileExtension)"
        let uploadFileURL = URL(fileURLWithPath: uploadFilePath)
        
        do {
            // Delete existing upload file
            if fileManager.fileExists(atPath: uploadFilePath) {
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
