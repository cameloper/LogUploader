//
//  LogUploader.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation
import Alamofire
import XCGLogger

public typealias LogUploadCompletion = (LogUploadResult<LogUploadError>) -> Void

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
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let uploadFilePath = "\(cachePath)/\(self.identifier)_upload.\(self.defaultFileExtension)"
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

extension XCGLogger {
    
    /// Upload the saved log file for a destination with the given identifier
    /// - Parameters:
    ///     - destinationId: Used to get the 'CustomFileDestination' object from logger
    ///     - uploader: The initialized object which conforms to protocol LogUploader. It will be used to upload the logs
    ///     - completion: Returns the result of upload operation. Use to handle errors etc.
    public func uploadLogs(from destinationId: String, uploader: LogUploader = DefaultLogUploader(), completion: LogUploadCompletion?) {
        // First get the destination object from logger
        guard let destination = self.destination(withIdentifier: destinationId) as? CustomFileDestination else {
            completion?(.failure(.missingDestination))
            return
        }
        
        // Then upload the logs and log the result to the owner
        uploader.upload(from: destination) { result in
            switch result {
            case .success:
                destination.owner?.info("LogUpload for destination \(destination) is successful")
            case .failure(let error):
                destination.owner?.error("LogUpload for destination \(destination) failed. Reason: \(error.displayMessage)")
            }
            completion?(result)
        }
    }
}

/// Struct that stores all the required parameters etc. for the networking of uploader
public struct LogUploaderConfiguration {
    /// The URL for the POST request
    var requestURL: URL
    /// Request parameters about device/system/app.
    /// Change this variable if you want your own parameters or to remove defaults
    /// - Default parameters:
    ///     - UUID
    ///     - Device model
    ///     - Device name
    ///     - System name
    ///     - System version
    ///     - App version
    ///     - App build version
    ///     - Logs
    var parameters: [String: Any]
    /// Encoding type for the POST parameters.
    /// - default value: `JSON`
    var parameterEncoding: ParameterEncoding
    /// Closure that must return required headers for the POST request.
    /// i.e. Authentication tokens that change everytime.
    var headers: (() -> [String: String])?
    /// Boolean that decides if the failed log uploads should be stored
    /// in the device until they get successfuly uploaded.
    /// - default value: `true`
    var storeFailedUploads: Bool
    /// Boolean that decides if the failed and stored uploads should be
    /// automatically retried to upload.
    /// - precondition: `storeFailedUploads == true`
    /// - default value: `true`
    var autoRetryFailedUploads: Bool
    /// Boolean that decides if the successful log uploads should be
    /// stored in the device until they get manually deleted.
    /// - default value: `false`
    var storeSuccessfullUploads: Bool
    
    public init(requestURL: URL,
                parameterEncoding: ParameterEncoding = JSONEncoding.default,
                headerHandler headers: (() -> [String: String])? = nil) {
        
        self.requestURL = requestURL
        
        // Get the device object to gather system and app info
        let device = UIDevice.current
        let versionNumber = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "undefined"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "undefined"
        
        self.parameters = ["deviceIdentifier": device.identifierForVendor?.uuidString ?? "n/A",
                           "deviceModel": device.model,
                           "deviceName": device.name,
                           "systemName": device.systemName,
                           "systemVersion": device.systemVersion,
                           "appVersion": versionNumber,
                           "appBuildVersion": buildNumber]
        
        self.parameterEncoding = parameterEncoding
        self.headers = headers
        
    }
    
}

/// The protocol LogUploaders must conform to
public protocol LogUploader {
    func upload(from destination: CustomFileDestination, completion: LogUploadCompletion?)
}
