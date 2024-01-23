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

/// Get all loaded dylibs for a given PID.
/// Returns an array of NSDictionary: [imageName: NSString, imagePath: NSString, loadAddr: mach_header].
/// In Swift, treat imageName and imagePath as `String` types or equivalent. loadAddr should be typecast to `mach_header` and nothing else. See `<mach-o/loader.h>` for more info.
func getDylibs(_ pid: Int32) throws -> [NSDictionary] {
    if pid == 0 && !UserDefaults.standard.bool(forKey: "iHaveTFP0") {
        throw "I cannot get task_for_pid for the kernel. If you are jailbroken with a tfp0 patch (i.e. palera1n), please enable the \"I CAN HAZ TFP0\" debug setting."
    }
    guard let procs = getDylibsForPID(pid) as? [NSDictionary] else { throw "Unable to get loaded dylibs" }
    return procs
}

// FIXME: Most likely broken on macOS, needs testing!
/// What did you think this would do?
func getAppInfoFromExecutablePath(_ path: String) -> SBApp? {
    print("[AppInfo] Getting info for \(path)")
    let fm: FileManager = .default
    var sbapp: SBApp = .init(bundleIdentifier: "", name: "", version: "", bundleURL: URL(fileURLWithPath: ""), plistIconName: nil, pngIconPaths: [], hiddenFromSpringboard: false)
    
    // MARK: - Check if executable is in a valid application bundle

    /*guard*/ let url = URL(fileURLWithPath: path) /*else { print("[AppInfo] \(path) was not a valid URL. Goodbye."); return nil }*/
    let dir = url.deletingLastPathComponent()
    let infoPlistPath = dir.appendingPathComponent("Info.plist")
//    guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { print("[AppInfo] Error getting contents of parent folder for \(dir.lastPathComponent). Goodbye."); return nil }
//
//    if !contents.contains(where: { $0.lastPathComponent == "Info.plist" }) { print("[AppInfo] Info.plist not found for \(dir.lastPathComponent). Goodbye."); return nil }
    if !fm.fileExists(atPath: infoPlistPath.path) {
        print("[AppInfo] Warning: file \(infoPlistPath.path) does not exist. This could end badly.")
    } else {
        print("[AppInfo] Found Info.plist for \(url.lastPathComponent) at \(infoPlistPath.path).")
    }
    
    guard let contentsOfInfoPlist = NSDictionary(contentsOf: infoPlistPath) as? [String: AnyObject] else { print("[AppInfo] Error getting contents of Info.plist for \(url.lastPathComponent). Goodbye."); return nil }
    print("[AppInfo] Info.plist found for \(url.lastPathComponent)")
    guard contentsOfInfoPlist["CFBundleExecutable"] is String else { print("[AppInfo] CFBundleExecutable not found for \(url.lastPathComponent). Goodbye."); return nil }
    
    // MARK: - Get application info

    print("[AppInfo] Getting application info of \(url.lastPathComponent).")
    sbapp.bundleIdentifier = contentsOfInfoPlist["CFBundleIdentifier"] as! String
    print("[AppInfo] Got bundle id \(sbapp.bundleIdentifier) for \(url.lastPathComponent).")
    sbapp.bundleURL = dir
    print("[AppInfo] Got bundle url \(sbapp.bundleURL) for \(url.lastPathComponent).")
    sbapp.name = contentsOfInfoPlist["CFBundleDisplayName"] as? String ?? contentsOfInfoPlist["CFBundleName"] as? String ?? "Unknown"
    print("[AppInfo] Got name \(sbapp.name) for \(url.lastPathComponent).")
    sbapp.version = contentsOfInfoPlist["CFBundleShortVersionString"] as? String ?? "1.0"
    print("[AppInfo] Got bundle version \(sbapp.version) for \(url.lastPathComponent).")
    if let CFBundleIcons = contentsOfInfoPlist["CFBundleIcons"] {
        if let CFBundlePrimaryIcon = CFBundleIcons["CFBundlePrimaryIcon"] as? [String: AnyObject] {
            if let CFBundleIconFiles = CFBundlePrimaryIcon["CFBundleIconFiles"] as? [String] {
                sbapp.pngIconPaths += CFBundleIconFiles.map { $0 + "@2x.png" }
                print("[AppInfo] Got icon \(sbapp.pngIconPaths.count > 1 ? "files" : "file") \(sbapp.pngIconPaths.joined(separator: ", ")) for \(sbapp.name).")
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
    
    print("[AppInfo] We are done. Good night. (\(sbapp.name))")
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
        let ret = spawnAsRoot(helperPath, ["kill", pid, sig.rawValue])
        if ret != 0 {
            throw "Priviledged kill helper returned non-zero exit code \(ret)."
        }
    } else {
        throw "Could not find kill helper in bundle."
    }
}

// MARK: - Stolen from SpawnPoint (failed project :nfr:)

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
        print("Error occurred checking: \(error). Silently failing.")
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
        print("Error occurred checking: \(error). Silently failing.")
        return nil
    }
}

public let helperPath: String? = Bundle.main.url(forResource: "roothelper", withExtension: nil)?.path
public func spawnAsRoot(_ path: String, _ args: [Any], silent: Bool = false) -> Int {
    var stdout: NSString?
    var stderr: NSString?
    let mod = chmod(path, 0755)
    let own = chown(path, 0, 0)
    print("[SpawnRoot] \(mod) \(own)")
    // FIXME: There has to be a better way to do this.......
    var args_stringified: [String] = []
    for arg in args {
        args_stringified.append("\(arg)")
    }
    if silent {
        args_stringified.append("--silent")
    }
    let retval = Int(spawnRoot(path, args_stringified, &stdout, &stderr))
    print("[SpawnRoot]" + ((stdout as? String) ?? "Nothing from stdout"))
    print("[SpawnRoot]" + ((stderr as? String) ?? "Nothing from stderr"))
    return retval
}

public func spawnRootWithOutput(_ path: String, _ args: [Any], silent: Bool = false) -> (ret: Int, stdout: String, stderr: String) {
    var stdout: NSString?
    var stderr: NSString?
    let mod = chmod(path, 0755)
    let own = chown(path, 0, 0)
    print("[SpawnRoot] \(mod) \(own)")
    // FIXME: There has to be a better way to do this.......
    var args_stringified: [String] = []
    for arg in args {
        args_stringified.append("\(arg)")
    }
    if silent {
        args_stringified.append("--silent")
    }
    let retval = Int(spawnRoot(path, args_stringified, &stdout, &stderr))
    print("[SpawnRoot]" + ((stdout as? String) ?? "Nothing from stdout"))
    print("[SpawnRoot]" + ((stderr as? String) ?? "Nothing from stderr"))
    return (retval, (stdout as String?) ?? "", (stderr as String?) ?? "")
}
