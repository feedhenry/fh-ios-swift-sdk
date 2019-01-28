Pod::Spec.new do |s|
  s.name         = 'FeedHenry'
  s.version      = '6.1.0'
  s.summary      = 'FeedHenry Swift iOS Software Development Kit'
  s.homepage     = 'http://feedhenry.org/'
  s.social_media_url = 'https://twitter.com/feedhenry'
  s.license      = 'FeedHenry'
  s.author       = 'Red Hat, Inc.'
  s.source       = { :git => 'https://github.com/feedhenry/fh-ios-swift-sdk.git', :tag => s.version }
  s.platform     = :ios, 9.0
  s.source_files = 'FeedHenry/**/*.{swift}', 'FeedHenry/**/*.{h,m}', 'FeedHenry/*.{h,m}'
  s.module_map = 'FeedHenry/FeedHenry.modulemap'
  s.requires_arc = true
  s.dependency 'AeroGearHttp', '2.0.0'
  s.dependency 'AeroGearPush-Swift', '3.0.0'
  s.dependency 'ReachabilitySwift', '4.1.0'
end
