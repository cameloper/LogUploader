//
//  LogUploader.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation

/// Combination of protocol and superclass for destinations that are suitable for upload
public typealias UploadableFileDestination = Uploadable & CustomFileDestination

/// Protocol for destinations that are suitable for upload.
/// Use `UploadableFileDestination` for your custom destinations since it inherits from
/// `CustomFileDestination` as well
public protocol Uploadable {
    /// Configuration struct that holds the upload settings
    var uploaderConfiguration: LogUploaderConfiguration? { get set }
    /// URL of the folder uploads will be saved to
    /// There can't be any other files except LogUploads in this folder
    var uploadFolderURL: URL? { get set }
}

/// The protocol LogUploaders must conform to
public protocol LogUploader {
    /// URL of the uploader folder.
    var homeURL: URL { get }
    /// Begin the process of log uploading
    func upload(from destination: UploadableFileDestination, completion: LogUploadCompletion?)
    /// Gets the failed logs from before and passes them to `uploadFailedLog` method
    /// - Parameters:
    ///     - destination: The CustomFileDestination we'll upload the logs from
    ///     - completion: Completion closure that passes the results
    func uploadFailedLogs(from destination: UploadableFileDestination, completion: LogUploadsCompletion?)
}
