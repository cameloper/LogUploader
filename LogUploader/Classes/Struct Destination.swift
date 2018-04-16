//
//  Struct Destination.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 13.04.18.
//

import Foundation
import XCGLogger

/// Destination that passes a codable Log struct object to the write method.
/// Should be overriden
open class StructDestination: DestinationProtocol {
    /// Logger object that owns this destination
    open var owner: XCGLogger?
    
    /// Unique identifier of the destination
    open var identifier: String
    
    /// Default output level of logger. Anything lower won't get processed
    open var outputLevel: XCGLogger.Level = .debug
    
    /// Flag if app details were logged
    open var haveLoggedAppDetails: Bool = false
    
    /// Array of formatters that will be applied
    open var formatters: [LogFormatterProtocol]?
    
    /// Array of filters that will be applied
    open var filters: [FilterProtocol]?
    
    // MARK: - Log detail options
    /// Option: whether or not to output the log identifier
    open var showLogIdentifier: Bool = false
    
    /// Option: whether or not to output the function name that generated the log
    open var showFunctionName: Bool = true
    
    /// Option: whether or not to output the thread's name the log was created on
    open var showThreadName: Bool = false
    
    /// Option: whether or not to output the fileName that generated the log
    open var showFileName: Bool = true
    
    /// Option: whether or not to output the line number where the log was generated
    open var showLineNumber: Bool = true
    
    /// Option: whether or not to output the log level of the log
    open var showLevel: Bool = true
    
    /// Option: whether or not to output the date the log was created
    open var showDate: Bool = true
    
    // MARK: - Initializer
    public init(owner: XCGLogger? = nil, identifier: String = "") {
        self.owner = owner
        self.identifier = identifier
    }
    
    // MARK: - Processing methods
    /// Process the log details (internal use, same as process(logDetails:) but omits function/file/line info).
    ///
    /// - Parameter logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    open func processInternal(logDetails: LogDetails) {
        let outputClosure = {
            // Create mutable versions of our parameters
            var logDetails = logDetails
            var message = logDetails.message
            
            // Apply filters, if any indicate we should drop the message, we abort before doing the actual logging
            guard !self.shouldExclude(logDetails: &logDetails, message: &message) else { return }
            
            // Apply formatters
            self.applyFormatters(logDetails: &logDetails, message: &message)
            
            // Get codable log object from log details
            var log = self.createCodableDetails(logDetails: logDetails)
            
            // Remove the internal parameters
            log.functionName = nil
            log.fileName = nil
            log.lineNumber = nil
            
            self.output(log: log)
        }
        
        if let logQueue = logQueue {
            logQueue.async(execute: outputClosure)
        }
        else {
            outputClosure()
        }
    }
    
    /// Check if the destination's log level is equal to or lower than the specified level.
    ///
    /// - Parameter level: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Log destination is at the log level specified or lower.
    ///     - false:    Log destination is at a higher log level.
    ///
    open func isEnabledFor(level: XCGLogger.Level) -> Bool {
        return level >= self.outputLevel
    }
    
    open var debugDescription: String {
        return "\(identifier) - Level: \(outputLevel)"
    }
    
    /// The dispatch queue to process the log on
    open var logQueue: DispatchQueue? = nil
    
    /// Process the log details.
    ///
    /// - Parameter logDetails: Structure with all of the details for the log to process.
    /// - Returns:  Nothing
    ///
    open func process(logDetails: LogDetails) {
        let outputClosure = {
            // Create mutable versions of our parameters
            var logDetails = logDetails
            var message = logDetails.message
            
            // Apply filters, if any indicate we should drop the message, we abort before doing the actual logging
            guard !self.shouldExclude(logDetails: &logDetails, message: &message) else { return }
            
            // Apply formatters
            self.applyFormatters(logDetails: &logDetails, message: &message)
            
            // Get codable log object from log details
            let log = self.createCodableDetails(logDetails: logDetails)
            
            self.output(log: log)
        }
        
        if let logQueue = logQueue {
            logQueue.async(execute: outputClosure)
        }
        else {
            outputClosure()
        }
    }
    
    /// Pass the created struct to overriding method
    ///
    /// - Parameter log: The created log object
    /// - Returns:  Nothing
    ///
    open func output(log: Log) {
        // Do something with the text in an overridden version of this method
        precondition(false, "Must override this")
    }
    
    /// Converts the logDetails object to codable Log struct.
    /// Does not include the not-wanted parameters.
    ///
    /// - Parameter logDetails: LogDetails object that will get converted
    /// - Returns: Codable Log struct
    ///
    open func createCodableDetails(logDetails: LogDetails) -> Log {
        var details = Log(logDetails)
        
        if !showDate {
            details.date = nil
        }
        
        if !showLevel {
            details.level = nil
        }
        
        if !showFileName {
            details.fileName = nil
        }
        
        if !showLineNumber {
            details.lineNumber = nil
        }
        
        // Gets current thread name from system
        if showThreadName {
            // Print just main if it's main thread
            if Thread.isMainThread {
                details.threadName = "main"
            }
            else {
                if let threadName = Thread.current.name, !threadName.isEmpty {
                    // Print thread name if we're in a thread
                    details.threadName = "T: \(threadName)"
                }
                else if let queueName = DispatchQueue.currentQueueLabel, !queueName.isEmpty {
                    // Print queue name if we're in a DispachQueue
                    details.threadName = "Q: \(queueName)"
                }
                else {
                    details.threadName = String(format: "T: %p", Thread.current)
                }
            }
        }
        
        if !showFunctionName {
            details.functionName = nil
        }
        
        if showLogIdentifier {
            details.logIdentifier = self.identifier
        }
        
        return details
    }
    
}
