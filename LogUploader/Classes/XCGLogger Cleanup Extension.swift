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
        let destinations = self.destinations.compactMap { $0 as? CustomFileDestination }
        let uploaderFolders = Set<URL>(destinations.compactMap {
            $0.uploaderConfiguration?.uploader.homeURL
        })
        
        // If empty, return false
        guard !uploaderFolders.isEmpty else {
            self.warning("There are no uploaders with existing logfiles!")
            return true
        }
        
        let fileManager = FileManager()
        
        // For all uploader folders...
        for folderURL in uploaderFolders {
            do {
                // ...get contents...
                let contents = try fileManager.contentsOfDirectory(atPath: folderURL.path)
                // ...and delete them.
                try contents.forEach { try fileManager.removeItem(atPath: $0) }
            } catch (let error) {
                self.error("An error occured when trying to delete contents of \(folderURL.path). Reason: \(error)")
                return false
            }
        }
        
        return true
    }
}
