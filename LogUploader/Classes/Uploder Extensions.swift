//
//  Uploder Extensions.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 20.04.18.
//

import Foundation
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
}
