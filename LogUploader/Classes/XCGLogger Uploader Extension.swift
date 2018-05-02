//
//  Uploder Extensions.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 20.04.18.
//

import Foundation
import XCGLogger

/// Extension of XCGLogger class that holds the upload methods for first access
extension XCGLogger {
    
    /// Try to upload all logs from all destinations that have a configuration
    /// - parameter completion: Completion closure that passes the results
    public func uploadLogs(completion: LogUploadsCompletion?) {
        // Get all Custom File Destinations
        let destinations = self.destinations.compactMap { $0 as? CustomFileDestination }
        // This will be the output result array
        var output = LUResults()
        // Execute the `uploadLogs(from:)` for all destinations with non-nil configurations
        for destination in destinations where destination.uploaderConfiguration != nil {
            self.uploadLogs(from: destination) { result in
                let fileName = destination.fileURL.lastPathComponent
                output.append(LUResult(destinationId: destination.identifier, logFileName: fileName, result: result))
            }
        }
        
        completion?(output)
    }
    
    /// Upload the saved log file for a destination with the given identifier
    /// - Parameters:
    ///     - destinationId: Used to get the 'CustomFileDestination' object from logger
    ///     - completion: Returns the result of upload operation. Use to handle errors etc.
    public func uploadLogs(from destinationId: String, completion: LogUploadCompletion?) {
        // First get the destination object from logger
        guard let destination = self.destination(withIdentifier: destinationId) as? CustomFileDestination else {
            completion?(.failure(.missingDestination))
            return
        }
        
        // Execute `uploadLogs(from:)` with destination object
        self.uploadLogs(from: destination, completion: completion)
    }
    
    /// Upload the saved log file for the given destination
    /// - Parameters:
    ///     - destination: The destination which'll be the source of logs
    ///     - completion: Returns the result of upload operation. Use to handle errors etc.
    private func uploadLogs(from destination: CustomFileDestination, completion: LogUploadCompletion?) {
        // Get the configuration
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
    
    /// Try to upload all failed logs from all destinations
    /// - parameter completion: Completion closure that passes the results
    public func uploadFailedLogs(completion: LogUploadsCompletion?) {
        // Get all Custom File Destinations
        let customFileDestinations = self.destinations.compactMap { $0 as? CustomFileDestination }
        // This will be the output result array
        var output = LUResults()
        // Execute the `uploadFailedLogs(from:)` for all destinations with non-nil configurations
        for destination in customFileDestinations where destination.uploaderConfiguration != nil {
            self.uploadFailedLogs(from: destination) { results in
                output.append(contentsOf: results)
            }
        }
        completion?(output)
    }
    
    /// Try to upload the previous failed logfiles for destination with given identifier
    /// - Parameters:
    ///     - destinationId: Identifier of the destination we'll try to upload logs for
    ///     - completion: Completion closure that passes the results
    public func uploadFailedLogs(from destinationId: String, completion: LogUploadsCompletion?) {
        // First get the destination object from logger
        guard let destination = self.destination(withIdentifier: destinationId) as? CustomFileDestination else {
            completion?([LUResult(destinationId: destinationId, logFileName: nil, result: .failure(.missingDestination))])
            return
        }
        
        uploadFailedLogs(from: destination, completion: completion)
    }
    
    /// Try to upload the previous failed logfiles for the given destination
    /// - Parameters:
    ///     - destination: The destination which'll be the source of failed logFiles
    ///     - completion: Returns the result of upload operation. Use to handle errors etc.
    func uploadFailedLogs(from destination: CustomFileDestination, completion: LogUploadsCompletion?) {
        // Then get the configuration
        guard let conf = destination.uploaderConfiguration else {
            completion?([LUResult(destinationId: destination.identifier,
                                  logFileName: nil,
                                  result: .failure(.missingDestination))])
            return
        }
        
        // Get the desired log uploader
        let uploader = conf.uploader
        
        // Then upload the logs and log the result to the owner
        uploader.uploadFailedLogs(from: destination) { results in
            for result in results {
                switch result.result {
                case .success:
                    destination.owner?.info("Upload of failed logfile \(result.logFileName!) from destination \(destination.identifier) is successful.")
                case .failure(let error):
                    destination.owner?.error("Upload of failed logfile \(result.logFileName ?? "") from destination \(destination.identifier) failed. \(error.displayMessage)")
                }
            }
            
            completion?(results)
        }
    }
}
