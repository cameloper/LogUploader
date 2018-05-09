//
//  JSONDestination.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation
import XCGLogger

/// CustomFileDestination that writes the logs in a JSON file
public class JSONDestination: UploadableFileDestination {
    
    public var uploaderConfiguration: LogUploaderConfiguration?
    
    public var uploadFolderURL: URL?
    
    
    public required init(owner: XCGLogger?, fileURL: URL, identifier: String, uploaderConf: LogUploaderConfiguration?, uploadFolderURL: URL? = nil) {
        // Initialize superclass
        super.init(owner: owner, fileURL: fileURL, identifier: identifier)
        
        // Assign the fileType parameter using fileExtension
        var configuration = uploaderConf
        configuration?.uploadConf.parameters["fileType"] = self.defaultFileExtension.uppercased()
        self.uploaderConfiguration = configuration
        
        self.uploadFolderURL = uploadFolderURL ?? configuration?.uploader.homeURL.appendingPathComponent(identifier, isDirectory: true)
        
    }
    
    /// Write logs to JSON
    /// - paramter log: Log object that'll be written in the file
    override public func output(log: Log) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        do {
            // Write new logs at the end of the file
            self.logFileHandle?.seekToEndOfFile()
            let jsonData = try encoder.encode(log)
            self.logFileHandle?.write(jsonData)
            // Write comma after log since our file should be a json array
            if let newLine = ",".data(using: .utf8) {
                self.logFileHandle?.write(newLine)
            }
        } catch let error {
            self.owner?.error("Exception occured while trying to write logs of \(self.identifier). \(error)")
        }
    }
    
    public func prepareForUpload() -> URL? {
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
        let date = Date().timeIntervalSince1970
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
