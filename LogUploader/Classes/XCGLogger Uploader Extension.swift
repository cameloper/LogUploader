//
//  Uploder Extensions.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 20.04.18.
//

import Foundation
import XCGLogger

/// Completion closure for single log upload
/// - parameter result: Result of the upload
public typealias LogUploadCompletion = (_ result: LogUploadResult<LogUploadError>) -> Void
/// Completion closure for operation with multiple LogUploads such as `uploadFailed(_:)`
/// - parameter results: Dictionary of results with name of LogFile and its result
///     - key: Name of LogFile. "`n/A`" for uploads that failed before getting the Uploader
///     - value: Result of upload
public typealias LogUploadsCompletion = (_ results: [String: LogUploadResult<LogUploadError>]) -> Void

extension XCGLogger {
    
    /// Upload the saved log file for a destination with the given identifier
    /// - Parameters:
    ///     - destinationId: Used to get the 'CustomFileDestination' object from logger
    ///     - uploader: The initialized object which conforms to protocol LogUploader. It will be used to upload the logs
    ///     - completion: Returns the result of upload operation. Use to handle errors etc.
    public func uploadLogs(from destinationId: String, completion: LogUploadCompletion?) {
        // First get the destination object from logger
        guard let destination = self.destination(withIdentifier: destinationId) as? CustomFileDestination else {
            completion?(.failure(.missingDestination))
            return
        }
        
        guard let conf = destination.uploaderConfiguration else {
            completion?(.failure(.missingConfiguration))
            return
        }
        
        let uploader = conf.uploader
        
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
    
    public func uploadFailed(from destinationId: String, completion: LogUploadsCompletion?) {
        // First get the destination object from logger
        guard let destination = self.destination(withIdentifier: destinationId) as? CustomFileDestination else {
            completion?(["n/A": .failure(.missingDestination)])
            return
        }
        
        guard let conf = destination.uploaderConfiguration else {
            completion?(["n/A": .failure(.missingConfiguration)])
            return
        }
        
        let uploader = conf.uploader
        
        // Then upload the logs and log the result to the owner
        uploader.uploadFailedLogs(from: destination) { results in
            for result in results {
                switch result.value {
                case .success:
                    destination.owner?.debug("Upload of failed logfile \(result.key) is successful.")
                case .failure(let error):
                    destination.owner?.error("Upload of failed logdile \(result.key) failed. \(error.displayMessage)")
                }
            }
            completion?(results)
        }
    }
}
