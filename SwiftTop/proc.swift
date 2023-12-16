// bomberfish
// proc.swift – SwiftTop
// created on 2023-12-14

import Darwin
import Foundation
import OSLog

let PROC_ALL_PIDS: UInt32 = 1
let PROC_PIDPATHINFO_SIZE = MAXPATHLEN
let PROC_PIDPATHINFO_MAXSIZE = PROC_PIDPATHINFO_SIZE * 4
let PROC_PIDPATHINFO = 11

// idk if i should keep this as a throwing function or make it return an empty array on failure
/// Get list of running processes
func getProcesses() throws -> [NSDictionary] {
    // TODO: Make the whole thing Swift-native?
//    let numberOfProcesses: Int32 = proc_listpids(PROC_ALL_PIDS, 0, nil, 0);
//    var processIDs = [Int32](repeating: 0, count: Int(numberOfProcesses))
//
//    let pids = proc_listpids(PROC_ALL_PIDS, 0, processIDs, <#T##buffersize: Int32##Int32#>)
    
    guard let procs = sysctl_ps() as? [NSDictionary] else { throw "Unable to get processes" }
    return procs
}

/// What did you think this would do?
func getAppInfoFromExecutablePath(_ path: String) -> SBApp? {
    os_log("[AppInfo] Getting info for \(path)")
    let fm: FileManager = .default
    var sbapp: SBApp = .init(bundleIdentifier: "", name: "", version: "", bundleURL: URL(fileURLWithPath: ""), plistIconName: nil, pngIconPaths: [], hiddenFromSpringboard: false)
    
    // MARK: - Check if executable is in a valid application bundle

    /*guard*/ let url = URL(fileURLWithPath: path) /*else { os_log("[AppInfo] \(path) was not a valid URL. Goodbye."); return nil }*/
    let dir = url.deletingLastPathComponent()
    let infoPlistPath = dir.appendingPathComponent("Info.plist")
//    guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { os_log("[AppInfo] Error getting contents of parent folder for \(dir.lastPathComponent). Goodbye."); return nil }
//    
//    if !contents.contains(where: { $0.lastPathComponent == "Info.plist" }) { os_log("[AppInfo] Info.plist not found for \(dir.lastPathComponent). Goodbye."); return nil }
    if !fm.fileExists(atPath: infoPlistPath.path) {
        os_log("[AppInfo] Warning: file \(infoPlistPath.path) does not exist. This could end badly.")
    } else {
        os_log("[AppInfo] Found Info.plist for \(url.lastPathComponent) at \(infoPlistPath.path).")
    }
    
    guard let contentsOfInfoPlist = NSDictionary(contentsOf: infoPlistPath) as? [String: AnyObject] else { os_log("[AppInfo] Error getting contents of Info.plist for \(url.lastPathComponent). Goodbye."); return nil }
    os_log("[AppInfo] Info.plist found for \(url.lastPathComponent)")
    guard let executableFile = contentsOfInfoPlist["CFBundleExecutable"] as? String else { os_log("[AppInfo] CFBundleExecutable not found for \(url.lastPathComponent). Goodbye."); return nil }
    
    // MARK: - Get application info

    os_log("[AppInfo] Getting application info of \(url.lastPathComponent).")
    sbapp.bundleIdentifier = contentsOfInfoPlist["CFBundleIdentifier"] as! String
    os_log("[AppInfo] Got bundle id \(sbapp.bundleIdentifier) for \(url.lastPathComponent).")
    sbapp.bundleURL = dir
    os_log("[AppInfo] Got bundle url \(sbapp.bundleURL) for \(url.lastPathComponent).")
    sbapp.name = contentsOfInfoPlist["CFBundleDisplayName"] as? String ?? contentsOfInfoPlist["CFBundleName"] as? String ?? "Unknown"
    os_log("[AppInfo] Got name \(sbapp.name) for \(url.lastPathComponent).")
    sbapp.version = contentsOfInfoPlist["CFBundleShortVersionString"] as? String ?? "1.0"
    os_log("[AppInfo] Got bundle version \(sbapp.version) for \(url.lastPathComponent).")
    if let CFBundleIcons = contentsOfInfoPlist["CFBundleIcons"] {
        if let CFBundlePrimaryIcon = CFBundleIcons["CFBundlePrimaryIcon"] as? [String: AnyObject] {
            if let CFBundleIconFiles = CFBundlePrimaryIcon["CFBundleIconFiles"] as? [String] {
                sbapp.pngIconPaths += CFBundleIconFiles.map { $0 + "@2x.png" }
                os_log("[AppInfo] Got icon \(sbapp.pngIconPaths.count > 1 ? "files" : "file") \(sbapp.pngIconPaths.joined(separator: ", ")) for \(sbapp.name).")
            }
//            if let CFBundleIconName = CFBundlePrimaryIcon["CFBundleIconName"] as? String {
//                sbapp.plistIconName = CFBundleIconName
//            }
        }
    }
    
    if let SBAppTags = contentsOfInfoPlist["SBAppTags"] as? [String], !SBAppTags.isEmpty {
        if SBAppTags.contains("hidden") {
            sbapp.hiddenFromSpringboard = true
        }
    }
    
    if let _ = contentsOfInfoPlist["LSApplicationLaunchProhibited"] {
        sbapp.hiddenFromSpringboard = true
    }
    
    os_log("[AppInfo] We are done. Good night. (\(sbapp.name))")
    return sbapp
}

// this has been bounced between so many projects its wild
// i think it came from cowabunga first :trol:
/// Application
struct SBApp {
    private let fm = FileManager.default
    
    var bundleIdentifier: String
    var name: String
    var version: String
    var bundleURL: URL
    
    var plistIconName: String?
    var pngIconPaths: [String]
    var hiddenFromSpringboard: Bool
    
    var isSystem: Bool {
        bundleURL.pathComponents.count >= 2 && bundleURL.pathComponents[1] == "Applications"
    }
    
    func catalogIconName() -> String? {
        if bundleIdentifier == "com.apple.mobiletimer" {
            return "ClockIconBackgroundSquare"
        } else {
            return plistIconName
        }
    }
}
