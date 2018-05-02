//
//  LogUploadError.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation

/// Describes possible errors that can occur while uploading the current log file
public enum LogUploadError: Error {
    case missingDestination
    case missingConfiguration
    case logFileError
    case missingRequest(Error)
    case network(NetworkError)
    
    /// User-friendly message that may be shown
    var displayMessage: String {
        switch self {
        case .missingDestination:
            return "Could not get any eligible destination with the given identifier."
        case .missingConfiguration:
            return "Could not get the required configuration object for networking."
        case .logFileError:
            return "An error occured during the processing of the log file."
        case .missingRequest:
            return "An error occured when generating the URL request"
        case .network(let networkError):
            return "A network error occured. \(networkError.displayMessage)"
        }
    }
}

/// Describes the possible errors that can occur while communicating with the backend
public enum NetworkError: Error {
    
    case connection(Error)
    case authentication
    case clientError
    case serverError
    case missingValue(String)
    
    /// Initializes a network error based on a HTTP response
    init?(response: HTTPURLResponse?) {
        let httpStatusCode = response?.statusCode ?? 0
        switch httpStatusCode {
        case 401:
            self = .authentication
        case 400..<499:
            self = .clientError
        case 500..<599:
            self = .serverError
        default:
            // Status code seems fine
            return nil
        }
    }
    
    /// Initializes a network error based on a HTTP response and error object
    init(response: HTTPURLResponse?, error: Error) {
        if let networkError = NetworkError(response: response) {
            self = networkError
        } else {
            self = .connection(error)
        }
    }
    
    /// An error message which can be presented to the user
    var displayMessage: String {
        switch self {
        case .connection(let error):
            return "Error while connecting to the backend: \(error.localizedDescription)"
        case .authentication:
            return "Unable to authenticate user with the given credentials. Please reenter your credentials."
        case .clientError:
            return "An unknown client error occured."
        case .serverError:
            return "An unknown server error occured."
        case .missingValue(let description):
            return "A value is missing in the response: \(description)"
        }
    }
    
}
