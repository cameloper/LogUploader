//
//  LogUploadResult.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation

/// Completion closure for single log upload
/// - parameter result: Result of the upload
public typealias LogUploadCompletion = (_ result: LogUploadResult<LogUploadError>) -> Void
/// Completion closure for operation with multiple LogUploads such as `uploadFailed(_:)`
/// - parameter results: Dictionary of results with name of LogFile and its result
///     - key: Name of LogFile. "`n/A`" for uploads that failed before getting the Uploader
///     - value: Result of upload
public typealias LogUploadsCompletion = (_ results: LUResults) -> Void
/// Typealias to make it more compact
public typealias LUResults = [LUResult]

/// Log Uploader Result struct for multiple uploads
public struct LUResult {
    /// ID of the destination
    public var destinationId: String
    /// Name of the logfile
    public var logFileName: String?
    /// Result enum object
    public var result: LogUploadResult<LogUploadError>
}

/// Swift result enum for LogUpload
public enum LogUploadResult<CustomError: Error> {
    case success
    case failure(CustomError)
    
    /// Returns `true` if the result is a success, `false` otherwise.
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// Returns `true` if the result is a failure, `false` otherwise.
    public var isFailure: Bool {
        return !isSuccess
    }
    
    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    public var error: CustomError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
