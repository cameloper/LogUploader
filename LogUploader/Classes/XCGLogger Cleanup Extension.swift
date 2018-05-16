//
//  XCGLogger Cleanup Extension.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 07.05.18.
//

import Foundation
import XCGLogger

/// Extension of XCGLogger where the cleanup methods for log files stand
extension XCGLogger {
    
    /// Delete all log files that are strored
    /// - Returns: Boolean: Is cleanup successful
    public func deleteAllLogFiles() -> Bool {
        // Get all Custom File Destinations
        let destinations = self.destinations.compactMap { $0 as? UploadableFileDestination }
        let uploaderFolders = destinations.compactMap { $0.uploadFolderURL }
        
        // If empty, return false
        guard !uploaderFolders.isEmpty else {
            self.warning("There are no destinations with log upload folders!")
            return true
        }
        
        // Delete contents and return result
        return deleteContents(of: uploaderFolders)
    }
    
    /// Deletes log files of all successful uploads
    /// - Returns: Boolean: Cleanup is successful
    public func deleteSuccessfulLogFiles() -> Bool {
        // Get all Custom File Destinations
        let destinations = self.destinations.compactMap { $0 as? UploadableFileDestination }
        // Filter and get the ones that store successful uploads
        let destinationsStoringSuccessful = destinations.filter { $0.uploaderConfiguration?.storeSuccessfulUploads ?? false }
        // Get upload folder URLs
        let uploaderFolders = destinationsStoringSuccessful.compactMap { $0.uploadFolderURL }
        // Create successful folder URLs
        let successfulFolders = uploaderFolders.compactMap { $0.appendingPathComponent("successful", isDirectory: true) }
        
        // If empty, return false
        guard !successfulFolders.isEmpty else {
            self.warning("There are no destinations with successful log upload folders!")
            return true
        }
        
        // Delete contents and return result
        return deleteContents(of: successfulFolders)
    }
    
    /// Deletes contents of given folders
    func deleteContents(of folders: [URL]) -> Bool {
        let fileManager = FileManager()
        // For all folders...
        for folderURL in folders {
            do {
                // ...get contents...
                let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [])
                // ...and delete them.
                try contents.forEach { try fileManager.removeItem(at: $0) }
            } catch (let error) {
                self.error("An error occured when trying to delete contents of \(folderURL.path). Reason: \(error)")
                return false
            }
        }
        return true
    }
}
