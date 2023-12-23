# SwiftTop

An elegant task manager written in SwiftUI. Works on iOS and macOS\*. Inspired by [CocoaTop](https://github.com/D0m0/CocoaTop).

> \* macOS support is experimental and not guaranteed to work. It's also not very useful, since you can just use Activity Monitor.

## Features

- Written in SwiftUI
- Snappy
- List processes
- Kill processes
- Show process details, including the app bundle the executable belongs to

## Tested on 

- iPhone Xʀ, iOS 16.1 (20B82)
- The same iPhone Xʀ, iOS 17.0 (21A329)
- MacBookPro16,2, macOS 14.1 (23B74) **with SIP disabled and AMFI partially disabled**

## Installing

For iOS, you'll need an iPhone, iPad, or iPod Touch with TrollStore installed. Download the latest `.tipa` from the [Releases section](https://github.com/BomberFish/SwiftTop/releases) and install it with TrollStore.

## TODO

- More process details (threads, open files, open ports, mapped modules, etc)
- Implement other features from CocoaTop
- Test more on macOS

## Building for iOS

Run `./ipabuild.sh`. It's that easy. If you want a debug build, append the `--debug` argument. You will need at least Xcode 14 (for the main app), a recent version of ldid (for fakesigning), and Theos (for the roothelper) installed.

## Building for macOS

**TODO**

## Licencing

SwiftTop is licensed under the MIT license, meaning you have to provide a copyright notice if redistributing in another product. See `LICENSE` for more information.
