//
//  Log Struct.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 13.04.18.
//

import Foundation
import XCGLogger

/// Codable log struct that'll be used to create JSON easily
public struct Log: Codable {
    
    /// Codable enum for the Level variable in LogDetails
    public enum Level: Int, Codable {
        case verbose = 0, debug, info, warning, error, severe, none
        
        /// Computed property XCGLogger.Level for decoding
        var value: XCGLogger.Level {
            switch self {
            case .verbose:
                return .verbose
            case .debug:
                return .debug
            case .info:
                return .info
            case .warning:
                return .warning
            case .error:
                return .error
            case .severe:
                return .severe
            case .none:
                return .none
            }
        }
    }
    
    /// Log level required to display this log
    public var level: Level?
    
    /// Date this log was sent
    public var date: Date?
    
    /// The log message to display
    public var message: String
    
    /// Name of the function that generated this log
    public var functionName: String?
    
    /// Name of the file the function exists in
    public var fileName: String?
    
    /// The line number that generated this log
    public var lineNumber: Int?
    
    /// The thread log was generated
    public var threadName: String?
    
    /// The log identifier of destination
    public var logIdentifier: String?
    
    /// Initializer with XCGLogger.LogDetails
    /// - parameter details: LogDetails which the attributes will be gathered from
    init(_ details: LogDetails) {
        self.level = Level.init(rawValue: details.level.rawValue) ?? .none
        self.date = details.date
        self.message = details.message
        self.functionName = details.functionName == "" ? nil : details.functionName
        self.fileName = details.fileName == "" ? nil : details.fileName
        self.lineNumber = details.lineNumber == 0 ? nil : details.lineNumber
        
    }
}
