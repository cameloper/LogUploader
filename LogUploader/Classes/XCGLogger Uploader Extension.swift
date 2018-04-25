//
//  Uploder Extensions.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 20.04.18.
//

import Foundation
import XCGLogger

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
        
        // Then get the configuration
        guard let conf = destination.uploaderConfiguration else {
            completion?(.failure(.missingConfiguration))
            return
        }
        
        // We'll use the desired loguploader instance
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
    
    /// Try to upload the previous failed logfiles
    /// - Parameters:
    ///     - destinationId: Identifier of the destination we'll try to upload logs for
    ///     - completion: Completion closure that passes the results
    public func uploadFailed(from destinationId: String, completion: LogUploadsCompletion?) {
        // First get the destination object from logger
        guard let destination = self.destination(withIdentifier: destinationId) as? CustomFileDestination else {
            completion?([LUResult(destinationId: destinationId, logFileName: nil, result: .failure(.missingDestination))])
            return
        }
        
        guard let conf = destination.uploaderConfiguration else {
            completion?([LUResult(destinationId: destinationId, logFileName: nil, result: .failure(.missingDestination))])
            return
        }
        
        let uploader = conf.uploader
        
        // Then upload the logs and log the result to the owner
        uploader.uploadFailedLogs(from: destination) { results in
            for result in results {
                switch result.result {
                case .success:
                    destination.owner?.debug("Upload of failed logfile \(result.logFileName!) is successful.")
                case .failure(let error):
                    destination.owner?.error("Upload of failed logfile \(result.logFileName!) failed. \(error.displayMessage)")
                }
            }
            
            completion?(results)
        }
    }
}
