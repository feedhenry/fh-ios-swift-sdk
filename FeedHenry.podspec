Pod::Spec.new do |s|
  s.name         = 'FeedHenry'
  s.version      = '5.0.5'
  s.summary      = 'FeedHenry Swift iOS Software Development Kit'
  s.homepage     = 'https://www.feedhenry.com'
  s.social_media_url = 'https://twitter.com/feedhenry'
  s.license      = 'FeedHenry'
  s.author       = 'Red Hat, Inc.'
  s.source       = { :git => 'https://github.com/feedhenry/fh-ios-swift-sdk.git', :tag => s.version }
  s.platform     = :ios, 8.0
  s.source_files = 'FeedHenry/**/*.{swift}', 'FeedHenry/**/*.{h,m}', 'FeedHenry/*.{h,m}'
  s.module_map = 'FeedHenry/FeedHenry.modulemap'
  s.requires_arc = true
  s.dependency 'AeroGearHttp', '1.0.0'
  s.dependency 'AeroGear-Push-Swift', '2.0.1'
  s.dependency 'ReachabilitySwift', '3'
end
