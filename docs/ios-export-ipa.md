# How to export iOS .ipa file for distribution

This guide quickly describes how to export MediathekViewMobile
as an [.ipa](https://en.wikipedia.org/wiki/.ipa) file in order distribute it outside of Apple's App store.
WITHOUT a paid Apple developer account.

This is only for developers that want to side-load a custom version, or when creating a release of MediathekViewMobile.

## Background

MediathekViewMobile will not be allowed in Apple's App store due to its restrictive policies.
However, I believe that everyone should be able to install any software they like on their own devices.
Apple's App store can be bypassed using the [Alt Store](https://altstore.io/) - an alternative App store that does not require jailbreaks.
For this, MediathekViewMobile must be imported on every user's device using the Alt Store app.
The supported import format is `.ipa`.

## How to 

First, build the application via
`flutter build ios --release`

or in Xcode: 
  - select the "Runner" in the left side-bar
  - Top bar: Product -> Build  (wait until build)

XCode: Build an archive from the build

`Product -> archive (wait - takes a while)`

XCode: View the Archive: 

`Window -> Organizer  (should be called `Runner`)`

If you got a paid developer account: 

`click distribute app -> AdHoc -> export as .ipa`

Free developer account: 

`right click on archive -> show in finder (or cd with terminal)` 

There should be a directory called `Runner.app`
 
Create a directory `Payload` and copy the directory `Runner.app` in to it 
e.g with `cp -r `Runner.app` Payload`
 
Then Zip the `Payload` directory.

Lastly, rename `.zip` to `.ipa`.