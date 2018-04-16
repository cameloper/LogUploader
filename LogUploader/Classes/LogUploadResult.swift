//
//  LogUploadResult.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation

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
