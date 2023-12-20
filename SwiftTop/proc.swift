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

// FIXME: Most likely broken on macOS, needs testing!
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

func kill_priviledged(_ pid: Int32, _ sig: Signal = .KILL) throws {
    if let helperPath {
        let ret = spawnAsRoot(helperPath, [pid, sig.rawValue])
        if ret != 0 {
            throw "Priviledged kill helper returned non-zero exit code \(ret)."
        }
    } else {
        throw "Could not find kill helper in bundle."
    }
}

enum MachOFileType: String {
    case thirtytwoLE = "Mach-O 32-bit Little Endian"
    case sixtyFourLE = "Mach-O 64-bit Little Endian"
    case thirtytwoBE = "Mach-O 32-bit Big Endian"
    case sixtyFourBE = "Mach-O 64-bit Big Endian"
    case fat = "Mach-O Universal Binary"
}

func parseMachO(_ file: URL) -> MachOFileType? {
    do {
        let data: Data = try .init(contentsOf: file)
        let magic = data.subdata(in: 0..<4)
        
        switch magic {
        case Data([]):
            throw "File was empty"
        case Data([0xCE, 0xFA, 0xED, 0xFE]):
            return .thirtytwoLE
        case Data([0xCF, 0xFA, 0xED, 0xFE]):
            return .sixtyFourLE
        case Data([0xFE, 0xED, 0xFA, 0xCE]):
            return .thirtytwoBE
        case Data([0xFE, 0xED, 0xFA, 0xCF]):
            return .sixtyFourBE
        case Data([0xCA, 0xFE, 0xBA, 0xBE]):
            return .fat
        default:
            throw "File is not Mach-O"
        }
    } catch {
        os_log("Error occurred checking: \(error). Silently failing.")
        return nil
    }
}

func parseMachO(_ path: String) -> MachOFileType? {
    do {
        let data: Data = try .init(contentsOf: .init(fileURLWithPath: path))
        let magic = data.subdata(in: 0..<4)
        
        switch magic {
        case Data([]):
            throw "File was empty"
        case Data([0xCE, 0xFA, 0xED, 0xFE]):
            return .thirtytwoLE
        case Data([0xCF, 0xFA, 0xED, 0xFE]):
            return .sixtyFourLE
        case Data([0xFE, 0xED, 0xFA, 0xCE]):
            return .thirtytwoBE
        case Data([0xFE, 0xED, 0xFA, 0xCF]):
            return .sixtyFourBE
        case Data([0xCA, 0xFE, 0xBA, 0xBE]):
            return .fat
        default:
            throw "File is not Mach-O"
        }
    } catch {
        os_log("Error occurred checking: \(error). Silently failing.")
        return nil
    }
}

// TODO: IMPLEMENT THIS IN SWIFT!!!!!
// can't implement this in swift rn
//func getLoadedModules(_ pid: pid_t) -> [String] {
//    defer { ptrace(PT_DETACH, pid, nil, 0) } // detach if attached
//    // attach to pid
//    if (ptrace(PT_ATTACH, pid, nil, 0) == -1) {
//        os_log("[getLoadedModules] Failed to PT_ATTACH to \(pid). Is the process using PT_DENY_ATTACH?")
//        return []
//    }
//    
//    var task: mach_port_t = 0
//    if (task_for_pid(mach_task_self_, pid, &task) == -1) {
//        os_log("[getLoadedModules] Failed to get task for pid \(pid). Are we missing entitlements?")
//        return []
//    }
//    
//    
//    return []
//}

public let helperPath: String? = Bundle.main.url(forResource: "roothelper", withExtension: nil)?.path
public func spawnAsRoot(_ path: String, _ args: [Any]) -> Int {
    let mod = chmod(path, 0755)
    let own = chown(path, 0, 0)
    os_log("[SpawnRoot] \(mod) \(own)")
    return Int(spawnRoot(path, args, nil, nil))
}
