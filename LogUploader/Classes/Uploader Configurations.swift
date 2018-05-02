//
//  Uploader Configurations.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 20.04.18.
//

import Foundation
import Alamofire
import XCGLogger

/// Struct that holds the networking/request settings etc.
public struct LogUploadConfiguration {
    /// The URL for the POST request
    var requestURL: URL
    /// Request parameters about device/system/app.
    /// Change this variable if you want your own parameters or to remove defaults
    /// - Default parameters:
    ///     - UUID
    ///     - Device model
    ///     - Device name
    ///     - System name
    ///     - System version
    ///     - App version
    ///     - App build version
    ///     - Logs
    var parameters: [String: Any]
    /// Encoding type for the POST parameters.
    /// - default value: `JSON`
    var parameterEncoding: ParameterEncoding
    /// Closure that must return required headers for the POST request.
    /// i.e. Authentication tokens that change everytime.
    var headers: (() -> [String: String])?
    
    public init(requestURL: URL,
                parameterEncoding: ParameterEncoding = JSONEncoding.default,
                storeSuccessfulUploads: Bool = false,
                headerHandler headers: (() -> [String: String])? = nil) {
        
        self.requestURL = requestURL
        
        // Get the device object to gather system and app info
        let device = UIDevice.current
        let versionNumber = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "undefined"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "undefined"
        
        self.parameters = ["deviceIdentifier": device.identifierForVendor?.uuidString ?? "n/A",
                           "deviceModel": device.model,
                           "deviceName": device.name,
                           "systemName": device.systemName,
                           "systemVersion": device.systemVersion,
                           "appVersion": versionNumber,
                           "appBuildVersion": buildNumber]
        
        self.parameterEncoding = parameterEncoding
        self.headers = headers
        
    }
}

/// Struct that holds the preferences for uploader
public struct LogUploaderConfiguration {
    /// Identifier of the uploader that will be used for the operation.
    var uploader: LogUploader
    /// Upload configuration that will be used to generate a valid
    /// HTTP POST request.
    var uploadConf: LogUploadConfiguration
    /// Boolean that decides if the failed log uploads should be stored
    /// in the device until they get successfuly uploaded.
    /// - default value: `true`
    var storeFailedUploads: Bool
    /// Boolean that decides if the failed and stored uploads should be
    /// automatically retried to upload after next successful upload.
    /// - default value: `true`
    /// - precondition: `storeFailedUploads == true`
    var autoRetryFailedUploads: Bool
    /// Boolean that decides if the successful log uploads should be
    /// stored in the device until they get manually deleted.
    /// - default value: `false`
    var storeSuccessfulUploads: Bool
    
    public init(uploader: LogUploader,
                uploadConf: LogUploadConfiguration,
                storeFailedUploads: Bool = true,
                autoRetryFailedUploads: Bool = true,
                storeSuccessfulUploads: Bool = false) {
        
        self.uploader = uploader
        self.uploadConf = uploadConf
        self.storeFailedUploads = storeFailedUploads
        self.autoRetryFailedUploads = autoRetryFailedUploads
        self.storeSuccessfulUploads = storeSuccessfulUploads
        
    }
    
}
