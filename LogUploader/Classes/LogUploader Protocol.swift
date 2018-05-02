//
//  LogUploader.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation

/// The protocol LogUploaders must conform to
public protocol LogUploader {
    /// URL of the uploader folder.
    var homeURL: URL { get }
    /// Begin the process of log uploading
    func upload(from destination: CustomFileDestination, completion: LogUploadCompletion?)
    /// Gets the failed logs from before and passes them to `uploadFailedLog` method
    /// - Parameters:
    ///     - destination: The CustomFileDestination we'll upload the logs from
    ///     - completion: Completion closure that passes the results
    func uploadFailedLogs(from destination: CustomFileDestination, completion: LogUploadsCompletion?)
}
