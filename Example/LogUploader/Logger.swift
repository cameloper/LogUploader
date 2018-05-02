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
    let secondLogFileURL = URL(fileURLWithPath: documentsPath + "/xcglog2.json")
    
    let requestUrl = URL(string: "http://localhost:8080/")
    let secondRequestUrl = URL(string: "http://localhost:8081/")
    
    let conf = LogUploaderConfiguration(uploader: DefaultLogUploader(),
                                        uploadConf: LogUploadConfiguration(requestURL: requestUrl!))
    
    let uploadConf = LogUploadConfiguration(requestURL: secondRequestUrl!) {
        return ["token": "1234567890"]
    }
    
    let secondConf = LogUploaderConfiguration(uploader: DefaultLogUploader(), uploadConf: uploadConf, storeSuccessfulUploads: true)
    
    let jsonDestination = JSONDestination(owner: log, fileURL: logFileURL, identifier: "logger.jsonLogger", uploaderConf: conf)
    jsonDestination.showLogIdentifier = true
    
    jsonDestination.logQueue = XCGLogger.logQueue
    log.add(destination: jsonDestination)
    
    let secondJsonDestination = JSONDestination(owner: log, fileURL: secondLogFileURL, identifier: "logger.scndJsonLogger", uploaderConf: secondConf)
    secondJsonDestination.showLogIdentifier = true
    log.add(destination: secondJsonDestination)
    
    log.logAppDetails()
    
    log.dateFormatter?.dateFormat = "HH:mm:ss.SSS"
    return log
}()
