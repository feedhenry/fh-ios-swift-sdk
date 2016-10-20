# FeedHenry iOS SDK

[![Build Status](https://travis-ci.org/feedhenry/fh-ios-swift-sdk.png)](https://travis-ci.org/feedhenry/fh-ios-swift-sdk)
[![Coverage Status](https://coveralls.io/repos/github/feedhenry/fh-ios-swift-sdk/badge.svg?branch=master)](https://coveralls.io/github/feedhenry/fh-ios-swift-sdk?branch=master)

The iOS Software Development Kit to connect to the [FeedHenry platform.](http://www.feedhenry.com)

**The Swift version of FeedHenry SDK is a Work In Progress. If you want to use full feature SDK go to [fh-ios-sdk](https://github.com/feedhenry/fh-ios-sdk/).**

## Release Process

The project relies on [CocoaPods](http://cocoapods.org) and it's respective plugins  ['cocoapods-packager'](https://github.com/CocoaPods/cocoapods-packager) and ['cocoapods-appledoc'](https://github.com/CocoaPods/cocoapods-appledoc), so please ensure that are installed in your system. If not, please execute the following:

```
[sudo] gem install cocoapods cocoapods-packager cocoapods-appledoc
```

### Common Actions

* Update ```CHANGELOG.md`` with the new release and content.

### a) Release on CocoaPods  [Required Step]
* Update ```FeedHenry.podspec```, ```s.version``` attribute with the new version number.
* Tag the repository with the new version number:

```
git tag -s -a {VERSION} -m 'version {VERSION}'   // e.g. {VERSION} format is  '4.0.0'
```

* Push the new release tag on GitHub:

```
git push origin {TAG}
```

* Publish the ```FeedHenry.podspec``` on the [CocoaPods](http://cocoapods.org) repo with:

```
 	pod trunk push --allow-warnings
```

>	```--allow-warnings``` is required to skip some deprecation warnings from a underlying dependency library. This will be circumvented in a future release.

### c) Generate API Documentation

To generate API documentation and sync with the [GitHub pages placeholder](http://feedhenry.github.io/fh-ios-sdk/FH/docset/Contents/Resources/Documents/index.html), switch to ['gh-pages'](https://github.com/feedhenry/fh-ios-sdk/tree/gh-pages) branch and follow the instructions there.

## Usage

See [iOS SDK Guide](http://docs.feedhenry.com/v3/api/app_api.html).

### Links
* [FeedHenry Documentation](http://docs.feedhenry.com)
* [AeroGear iOS Http](https://github.com/aerogear/aerogear-ios-http)
* [AeroGear iOS Push](https://github.com/aerogear/aerogear-ios-push)
