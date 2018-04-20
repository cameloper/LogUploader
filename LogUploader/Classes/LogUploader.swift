//
//  LogUploader.swift
//  LogUploader
//
//  Created by Yilmaz, Ihsan on 16.04.18.
//

import Foundation

/// The protocol LogUploaders must conform to
public protocol LogUploader {
    func upload(from destination: CustomFileDestination, completion: LogUploadCompletion?)
}
