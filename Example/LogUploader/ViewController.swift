//
//  ViewController.swift
//  LogUploader
//
//  Created by Ihsan B. Yilmaz on 04/13/2018.
//  Copyright (c) 2018 Ihsan B. Yilmaz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var txtLogs: UITextView!
    @IBOutlet weak var txtNewLog: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        txtLogs.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func newLog(_ sender: Any) {
        guard let text = txtNewLog.text else {
            return
        }
        
        logMsg(text: text)
    }
    
    func logMsg(text: String) {
        log.debug(txtNewLog.text)
        txtLogs.text = "\(txtLogs.text ?? "")\n>\(text)"
    }
    @IBAction func uploadFailed(_ sender: Any) {
        log.uploadFailedLogs() { results in
            for result in results where result.result.isFailure {
                self.logMsg(text: "LogUpload of \(result.destinationId)/\(result.logFileName ?? "") failed. \(result.result.error!)")
            }
        }
    }
    
    @IBAction func uploadLogs(_ sender: Any) {
        log.uploadLogs() { results in
            for result in results {
                self.logMsg(text: "LogUpload of \(result.destinationId) failed. \(String(describing: result.result.error))")
            }
        }
    }
    
}

