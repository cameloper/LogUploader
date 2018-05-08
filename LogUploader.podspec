#
# Be sure to run `pod lib lint LogUploader.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LogUploader'
  s.version          = '0.2.0'
  s.summary          = 'Upload your XCGLogger logs to your own server easily!'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
LogUploader helps you upload all your app logs whenever you want to your own server. Without any limitations or costs.

It uses XCGLogger which you can configure in minutes and saves all the logs in a file format you want. Then uploads your logs to your server. Adding an uploadable destination is even easier than setting up XCGLogger.

Visit GitHub page for tutorial and examples.
                       DESC

  s.homepage         = 'https://github.com/cameloper/LogUploader'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ihsan B. Yilmaz' => 'Ihsan.Yilmaz@EXXETA.com' }
  s.source           = { :git => 'https://github.com/cameloper/LogUploader.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.swift_version = '4.1'

  s.source_files = 'LogUploader/Classes/**/*'
  
  # s.resource_bundles = {
  #   'LogUploader' => ['LogUploader/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'XCGLogger', '~> 6.0.2'
  s.dependency 'Alamofire', '~> 4.7.2'
end
