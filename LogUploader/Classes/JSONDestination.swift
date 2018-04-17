//
//  JSONDestination.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation
import XCGLogger

public class JSONDestination: CustomFileDestination {
    
    public required override init(owner: XCGLogger?, fileURL: URL, identifier: String, uploaderConf: LogUploaderConfiguration?) {
        // Initialize superclass
        super.init(owner: owner, fileURL: fileURL, identifier: identifier, uploaderConf: uploaderConf)
    }
    
    /// Write logs to JSON
    override public func output(log: Log) {
        let encoder = JSONEncoder()
        
        do {
            self.logFileHandle?.seekToEndOfFile()
            let jsonData = try encoder.encode(log)
            self.logFileHandle?.write(jsonData)
            if let newLine = "\n".data(using: .utf8) {
                self.logFileHandle?.write(newLine)
            }
        } catch let error {
            print("Exception occured: \(error)")
        }
    }
    
}
