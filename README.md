# GitHub pages for [FeedHenry SDK](http://feedhenry.github.io/fh-ios-swift-sdk/FeedHenry/docset/index.html)

> As part of [FHMOBSDK-61](https://issues.jboss.org/browse/FHMOBSDK-61) this branch will be eventually removed .

## Prerequisites

1. Install [Jazzy](https://github.com/realm/jazzy) 
`gem install jazzy`
2. Install [CocoaPods](https://guides.cocoapods.org/using/getting-started.html)
`gem install cocoapods`


## Update Docs

The `gh-pages` branch includes `master` branch as a git submodule in order to generate docs.

Steps: 

1. Init submodule `git submodule init`
1. Update submodule `git submodule update --remote`
1. Go to the module directory `cd fh-ios-swift-sdk`
1. Install CocoaPod dependencies `pod install`
1. Go back to root folder `cd ..`
1. Generate the documentation with jazzy `jazzy -o ./FeedHenry/docset --source-directory fh-ios-swift-sdk/  --author "Red Hat, Inc." --github_url https://github.com/feedhenry/fh-ios-swift-sdk`

Single line command

```
git submodule init && git submodule update --remote && cd fh-ios-swift-sdk && pod install && cd .. && jazzy -o ./FeedHenry/docset --source-directory fh-ios-swift-sdk/  --author "Red Hat, Inc." --github_url https://github.com/feedhenry/fh-ios-swift-sdk
```

Send a Pull Request with the changes and after it's merged, access the  [FeedHenry SDK GitHub page](http://feedhenry.github.io/fh-ios-swift-sdk/FeedHenry/docset/index.html) and ensure any changes have been propagated.
