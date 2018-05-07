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

## Contributing

- Create an issue
- Simply clone the project and solve the issue on a new branch
- Create a pull request

Thank's in advance :)

## Author

Ihsan B. Yilmaz, Ihsan.Yilmaz@EXXETA.com

## License

LogUploader is available under the MIT license. See the LICENSE file for more info.
