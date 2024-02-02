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

func getNameFromExecutablePath(_ path: String) -> String? {
    print("(\(#file):\(#line)) [AppInfo] Getting info for \(path)")
    let url = URL(fileURLWithPath: path)
    let dir = url.deletingLastPathComponent()
    let infoPlistPath = dir.appendingPathComponent("Info.plist")
    guard let contentsOfInfoPlist = NSDictionary(contentsOf: infoPlistPath) as? [String: AnyObject] else { print("(\(#file):\(#line)) [AppInfo] Error getting contents of Info.plist for \(url.lastPathComponent). Goodbye."); return nil }
    print("(\(#file):\(#line)) [AppInfo] Info.plist found for \(url.lastPathComponent)")
    guard contentsOfInfoPlist["CFBundleExecutable"] is String else { print("(\(#file):\(#line)) [AppInfo] CFBundleExecutable not found for \(url.lastPathComponent). Goodbye."); return nil }
    return contentsOfInfoPlist["CFBundleDisplayName"] as? String ?? contentsOfInfoPlist["CFBundleName"] as? String
}

func getBundleIDFromExecutablePath(_ path: String) -> String? {
    print("(\(#file):\(#line)) [AppInfo] Getting info for \(path)")
    let url = URL(fileURLWithPath: path)
    let dir = url.deletingLastPathComponent()
    let infoPlistPath = dir.appendingPathComponent("Info.plist")
    guard let contentsOfInfoPlist = NSDictionary(contentsOf: infoPlistPath) as? [String: AnyObject] else { print("(\(#file):\(#line)) [AppInfo] Error getting contents of Info.plist for \(url.lastPathComponent). Goodbye."); return nil }
    print("(\(#file):\(#line)) [AppInfo] Info.plist found for \(url.lastPathComponent)")
    guard contentsOfInfoPlist["CFBundleExecutable"] is String else { print("(\(#file):\(#line)) [AppInfo] CFBundleExecutable not found for \(url.lastPathComponent). Goodbye."); return nil }
    return contentsOfInfoPlist["CFBundleIdentifier"] as? String
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
        print("(\(#file):\(#line)) Error occurred checking: \(error). Silently failing.")
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
        print("(\(#file):\(#line)) Error occurred checking: \(error). Silently failing.")
        return nil
    }
}

public let helperPath: String? = Bundle.main.url(forResource: "roothelper", withExtension: nil)?.path
public func spawnAsRoot(_ path: String, _ args: [Any], silent: Bool = false) -> Int {
    var stdout: NSString?
    var stderr: NSString?
    let mod = chmod(path, 0755)
    let own = chown(path, 0, 0)
    print("(\(#file):\(#line)) [SpawnRoot] \(mod) \(own)")
    // FIXME: There has to be a better way to do this.......
    var args_stringified: [String] = []
    for arg in args {
        args_stringified.append("\(arg)")
    }
    if silent {
        args_stringified.append("--silent")
    }
    let retval = Int(spawnRoot(path, args_stringified, &stdout, &stderr))
    print("(\(#file):\(#line)) [SpawnRoot]" + ((stdout as? String) ?? "Nothing from stdout"))
    print("(\(#file):\(#line)) [SpawnRoot]" + ((stderr as? String) ?? "Nothing from stderr"))
    return retval
}

public func spawnRootWithOutput(_ path: String, _ args: [Any], silent: Bool = false) -> (ret: Int, stdout: String, stderr: String) {
    var stdout: NSString?
    var stderr: NSString?
    let mod = chmod(path, 0755)
    let own = chown(path, 0, 0)
    print("(\(#file):\(#line)) [SpawnRoot] \(mod) \(own)")
    // FIXME: There has to be a better way to do this.......
    var args_stringified: [String] = []
    for arg in args {
        args_stringified.append("\(arg)")
    }
    if silent {
        args_stringified.append("--silent")
    }
    let retval = Int(spawnRoot(path, args_stringified, &stdout, &stderr))
    print("(\(#file):\(#line)) [SpawnRoot]" + ((stdout as? String) ?? "Nothing from stdout"))
    print("(\(#file):\(#line)) [SpawnRoot]" + ((stderr as? String) ?? "Nothing from stderr"))
    return (retval, (stdout as String?) ?? "", (stderr as String?) ?? "")
}
