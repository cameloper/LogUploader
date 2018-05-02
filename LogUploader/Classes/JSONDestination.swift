//
//  JSONDestination.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation
import XCGLogger

/// CustomFileDestination that writes the logs in a JSON file
public class JSONDestination: CustomFileDestination {
    
    public required override init(owner: XCGLogger?, fileURL: URL, identifier: String, uploaderConf: LogUploaderConfiguration?) {
        // Initialize superclass
        super.init(owner: owner, fileURL: fileURL, identifier: identifier, uploaderConf: uploaderConf)
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
    
}
