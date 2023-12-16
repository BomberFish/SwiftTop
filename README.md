# SwiftTop

An elegant task manager for iOS. Works on iOS and macOS

## Features

- Written in SwiftUI
- Snappy
- List processes
- Kill processes
- Show process details, including the app bundle the executable belongs to

## Tested on 

- iPhone Xʀ, iOS 16.1 (20B82)
- MacBookPro16,2, macOS 14.1 (23B74) **with SIP disabled and AMFI partially disabled**

## TODO

- Privileged kill with spawn_root (just doesn't work right now')
- More process details (threads, open files, open ports, mapped modules, etc)
- Implement other features from CocoaTop

## Building for iOS

Run `./ipabuild.sh`. It's that easy. If you want a debug build, append the `--debug` argument.

## Building for macOS

**TODO**

## Licencing

SwiftTop is licensed under the MIT license, meaning you have to provide a copyright notice if redistributing in another product. See `LICENSE` for more information.
