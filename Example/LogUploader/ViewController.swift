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
    
    @IBAction func uploadLogs(_ sender: Any) {
        log.uploadLogs(from: "logger.jsonLogger") { result in
            switch result {
            case .success:
                self.logMsg(text: "Log upload successful")
            case .failure(let error):
                self.logMsg(text: "Log upload failed. \(error)")
            }
        }
    }
    
}

