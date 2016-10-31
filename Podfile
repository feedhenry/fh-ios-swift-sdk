source 'https://github.com/CocoaPods/Specs.git'

project 'FeedHenry.xcodeproj'
platform :ios, '8.0'
use_frameworks!

target 'FeedHenry' do
	pod 'AeroGearHttp', '0.8.0'
	pod 'ReachabilitySwift', '2.4'
	pod 'AeroGear-Push-Swift', '1.3.0'

	target 'FeedHenryTests' do
		pod 'OHHTTPStubs', '5.2.0'
		pod 'OHHTTPStubs/Swift', '5.2.0'
		pod 'OCMock', '3.3.1'
	end
end

# Workaround to fix swift version to 2.3 for Pods.
# it could be removed once CocoaPods 1.1.0 is released.
# https://github.com/CocoaPods/CocoaPods/issues/5521
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end
end