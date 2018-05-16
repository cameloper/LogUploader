# LogUploader

[![CI Status](http://img.shields.io/travis/cameloper/LogUploader.svg?style=flat)](https://travis-ci.org/cameloper/LogUploader)
![Status](https://img.shields.io/badge/status-early%20development-yellow.svg)
<!--[![Version](https://img.shields.io/cocoapods/v/LogUploader.svg?style=flat)](http://cocoapods.org/pods/LogUploader)-->
<!--[![License](https://img.shields.io/cocoapods/l/LogUploader.svg?style=flat)](http://cocoapods.org/pods/LogUploader)-->
<!--[![Platform](https://img.shields.io/cocoapods/p/LogUploader.svg?style=flat)](http://cocoapods.org/pods/LogUploader)-->

LogUploader helps you upload your logs to your own server using HTTP POST. If you already use [XCGLogger](https://github.com/DaveWoodCom/XCGLogger), all you need to do is to create and add a `JSONDestination` and a `LogUploaderConfiguration` then it's ready! Check out the example project if you want. ([SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver) configuration is also similar with XCGLogger so you can switch without a big effort)

More file formats will be added in the future. But if you don't want to wait, you can add your own destination as well. Just create a subclass of `CustomFileDestination`.

There will be a documentation with the release of CocaPods too.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- XCGLogger
- Alamofire

## Installation

LogUploder is currently in development but you can still install it with CocoaPods. Just execute `pod repo add cameloperPodspec 'https://github.com/cameloper/Podspec'`, then add `source 'https://github.com/cameloper/LogUploader'
` and `pod 'LogUploader'` in your Podfile.

We appreciate any kind of contribution!
<!--LogUploader is available through [CocoaPods](http://cocoapods.org). To install-->
<!--it, simply add the following line to your Podfile:-->
<!---->
<!--```ruby-->
<!--pod 'LogUploader'-->
<!--```-->

## Basic Usage

### Setting up XCGLogger

The following is a basic setup of XCGLogger with a console destination added as default. For more information please visit [here](https://github.com/DaveWoodCom/XCGLogger/blob/master/README.md#basic-usage-quick-start)
```swift
let log: XCGLogger = {
    let log = XCGLogger.default
    
    log.setup(level: .debug, showFunctionName: false, showLevel: true, showFileNames: true, showLineNumbers: true, showDate: true)
	// The destination setups will come here
    
    return log
}()
```
### JSON Destination

#### Destination? What?

XCGLogger works with destinations and the destinations handle what should be done with the logs. LogUploader has its own destnation superclass `CustomFileDestination`. It passes the the arguments of a log as a codable struct which helps by creating data interchange files. 

The default file destination that is included by now is `JSONDestination`. It saves the logs in a JSON which is one of the most used human-readable data interchange file formats.

#### Adding a JSONDestination to the XCGLogger

Initializing a JSON Destination and adding it to XCGLogger is pretty easy. Here's an example with log uploader configurations
```swift
// The following 2 lines are for log uploading. If you just want to save your logs as 
// a JSON file, these lines are not necessary
let logUploadConf = LogUploadConfiguration(requestURL: requestURL) // URL of the HTTP server
let logUploaderConf = LogUploaderConfiguration(uploader: DefaultLogUploader(), uploadConf: logUploadConf)

let jsonDestination = JSONDestination(owner: log, // XCGLogger object. `log` if you used the basic setup above
				      fileURL: logFileURL, // Where to save the JSON file
				      identifier: "logger.jsonLogger", // An unique id for the destination
				      uploaderConf: logUploaderConf) // Also for log upload. Can be omitted
				      
log.add(destination: jsonDestination)
```

### Logging

Now that JSON destination is registered in XCGLogger, any logs that are written using XCGLogger will be saved in the JSON file. To log anywhere in your code, simply type `log.LEVEL` where level can be i.e. `debug`, `info`, `error` etc.

For more info please visit [XCGLogger documentation](https://github.com/DaveWoodCom/XCGLogger#basic-usage-quick-start)

### Uploading logs

If you have a valid [`LogUploadConfiguration`](https://github.com/cameloper/LogUploader#log-uploader-configuration) you can upload your logs as easy as logging. Just type `log.uploadLogs()` to uploads logs of every available `UploadableFileDestination`'s or `log.uploadLogs(for: 'destinationId')` to upload logs of a single destination. You can also get the results in a completion closure.
 
<!--## Advanced Configuration

<!--### Log Uploader Configuration

<!--#### Log Upload Configuration

## Contributing

- Create an issue
- Simply clone the project and solve the issue on a new branch
- Create a pull request

Thank's in advance :)

## Author

Ihsan B. Yilmaz, Ihsan.Yilmaz@EXXETA.com

## License

LogUploader is available under the MIT license. See the LICENSE file for more info.
