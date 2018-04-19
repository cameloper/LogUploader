//
//  Logger.swift
//  LogUploader_Example
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCGLogger
import LogUploader

let log: XCGLogger = {
    let log = XCGLogger.default
    
    log.setup(level: .debug, showFunctionName: false, showLevel: true, showFileNames: true, showLineNumbers: true, showDate: true)
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let logFileURL = URL(fileURLWithPath: documentsPath + "/xcglog.json")
    
    let requestUrl = URL(string: "http://localhost:8080/")
    
    let conf = LogUploaderConfiguration(uploaderId: "",
                                        uploadConf: LogUploadConfiguration(requestURL: requestUrl!))
    let jsonDestination = JSONDestination(owner: log, fileURL: logFileURL, identifier: "logger.jsonLogger", uploaderConf: conf)
    
    jsonDestination.showDate = true
    jsonDestination.showLevel = true
    jsonDestination.showThreadName = true
    jsonDestination.showLogIdentifier = false
    
    jsonDestination.logQueue = XCGLogger.logQueue
    log.add(destination: jsonDestination)
    log.logAppDetails()
    
    log.logAppDetails()
    
    log.dateFormatter?.dateFormat = "HH:mm:ss.SSS"
    return log
}()
