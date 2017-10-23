# FeedHenry iOS SDK

![Maintenance](https://img.shields.io/maintenance/yes/2017.svg)
[![circle-ci](https://img.shields.io/circleci/project/github/feedhenry/fh-ios-swift-sdk/master.svg)](https://circleci.com/gh/feedhenry/fh-ios-swift-sdk)
[![Codecov](https://img.shields.io/codecov/c/github/codecov/fh-ios-swift-sdk/master.svg)](https://codecov.io/gh/feedhenry/fh-ios-swift-sdk)
[![License](https://img.shields.io/badge/-Apache%202.0-blue.svg)](https://opensource.org/s/Apache-2.0)
[![GitHub release](https://img.shields.io/github/release/feedhenry/fh-ios-swift-sdk.svg)](https://github.com/feedhenry/fh-ios-swift-sdk/releases)
[![CocoaPods](https://img.shields.io/cocoapods/v/FeedHenry.svg)](https://cocoapods.org/pods/FeedHenry)
[![Platform](https://img.shields.io/cocoapods/p/FeedHenry.svg)](https://cocoapods.org/pods/FeedHenry)

The iOS Software Development Kit to connect to the [FeedHenry platform.](http://www.feedhenry.com)

**The Swift version of FeedHenry SDK is a Work In Progress. If you want to use full feature SDK go to [fh-ios-sdk](https://github.com/feedhenry/fh-ios-sdk/).**

## Release Process

The project relies on [CocoaPods](http://cocoapods.org) and it's respective plugin  ['cocoapods-packager'](https://github.com/CocoaPods/cocoapods-packager), so please ensure that are installed in your system. If not, please execute the following:

```
[sudo] gem install cocoapods cocoapods-packager
```

### Common Actions

* Update `CHANGELOG.md` with the new release and content.

### a) Release on CocoaPods  [Required Step]
* Update `FeedHenry.podspec`, `s.version` attribute with the new version number.
* Tag the repository with the new version number:

```
git tag -s -a {VERSION} -m 'version {VERSION}'   // e.g. {VERSION} format is  '4.0.0'
```

* Push the new release tag on GitHub:

```
git push origin {TAG}
```

* Publish the `FeedHenry.podspec` on the [CocoaPods](http://cocoapods.org) repo with:

```
 	pod trunk push --allow-warnings
```

>	`--allow-warnings` is required to skip some deprecation warnings from a underlying dependency library. This will be circumvented in a future release.

### c) Generate API Documentation

To generate API documentation and sync with the [GitHub pages placeholder](http://feedhenry.github.io/fh-ios-swift-sdk/FeedHenry/docset/index.html), switch to ['gh-pages'](https://github.com/feedhenry/fh-ios-swift-sdk/tree/gh-pages) branch and follow the instructions there.

## Usage

See [iOS Swift SDK Guide](https://access.redhat.com/documentation/en-us/red_hat_mobile_application_platform_hosted/3/html/client_sdk/native-ios-swift).

### Links
* [AeroGear iOS Http](https://github.com/aerogear/aerogear-ios-http)
* [AeroGear iOS Push](https://github.com/aerogear/aerogear-ios-push)
