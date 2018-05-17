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
    
    /// Finalize file and make it ready for operations i.e. upload
    override open func finalize() -> Bool {
        // Get the file handler
        guard let logFileHandle = self.logFileHandle else {
                owner?.error("Finalization for destination \(identifier) failed! FileHandler could not be found.")
                return false
        }
        
        // Create a LogDetails object that states the beginning of finalization
        let logDetails = LogDetails(level: .debug, date: Date(), message: "Finalizing LogFile of \(identifier)", functionName: #function, fileName: #file, lineNumber: #line)
        // Create a codable Log object with LogDetails
        let log = Log(logDetails)
        // Initialize and setup the JSONEncoder
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .secondsSince1970
        
        do {
            // Synchronize file to prevent queued interventions
            logFileHandle.synchronizeFile()
            // Seek to the beginning of the file
            logFileHandle.seek(toFileOffset: 0)
            // Try and get contents of the file as String
            let text = try String(contentsOf: fileURL)
            
            // Add array starting literal at the beginning of the string
            guard let contentData = "[\(text)".data(using: .utf8),
                // Get array ending literal as data
                let arrayEnding = "]".data(using: .utf8) else {
                    owner?.error("Finalization for destination \(identifier) failed!")
                    return false
            }
            
            // Seek to the beginning of the file
            logFileHandle.seek(toFileOffset: 0)
            // Write the altered contents string
            logFileHandle.write(contentData)
            
            // Encode and write the new log data
            let logData = try jsonEncoder.encode(log)
            logFileHandle.write(logData)
            // Write the array ending literal
            logFileHandle.write(arrayEnding)
            
            // Close file and stop incoming logs
            closeFile()
            
            return true
            
        } catch (let error) {
            owner?.error("Exception occured while trying to finalize logfile \(identifier). Reason: \(error)")
            return false
        }
        
        
    }
}
