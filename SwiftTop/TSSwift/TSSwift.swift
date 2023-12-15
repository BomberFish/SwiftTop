//
//  TSSwift.swift
//  
//
//  Created by Hariz Shirazi on 2023-10-06.
//

import Foundation
import OSLog

/// TSSwift: Interface with TrollStore Root Helper
public class TrollStoreUtils {
    public static func spawnAsRoot(_ path: String, _ args: [Any]) -> Int {
        let mod = chmod(path, 0755)
        let own = chown(path, 0, 0)
        Logger().debug("[-DEBUG] \(mod) \(own)")
        return Int(spawnRoot(path, args, nil, nil))
    }
}

public class TrollStoreRootHelper {
    
    static let rootHelperPath = Bundle.main.url(forAuxiliaryExecutable: "roothelper")!.path
    
    
    static func write(_ str: String, to url: URL) throws  {
        let code = TrollStoreUtils.spawnAsRoot(rootHelperPath, ["write", str, url.path])
        guard code == 0 else { throw "roothelper.writedata: returned a non-zero code \(code)" }
    }
    
    static func move(from sourceURL: URL, to destURL: URL) throws {
        let code = TrollStoreUtils.spawnAsRoot(rootHelperPath, ["mv", sourceURL.path, destURL.path])
        guard code == 0 else { throw "roothelper.move: returned a non-zero code \(code)" }
    }
    
    static func copy(from sourceURL: URL, to destURL: URL) throws {
        let code = TrollStoreUtils.spawnAsRoot(rootHelperPath, ["cp", sourceURL.path, destURL.path])
        guard code == 0 else { throw "roothelper.copy: returned a non-zero code \(code)" }
    }
    
    static func createDirectory(at url: URL) throws {
        let code = TrollStoreUtils.spawnAsRoot(rootHelperPath,  ["mkdir", url.path, ""])
        guard code == 0 else { throw "roothelper.createDirectory: returned a non-zero code \(code)" }
    }
    
    static func createSymLink(from sourceURL: URL, to destURL: URL) throws {
        let code = TrollStoreUtils.spawnAsRoot(rootHelperPath, ["ln", sourceURL.path, destURL.path])
        guard code == 0 else { throw "roothelper.createSymLink: returned a non-zero code \(code)" }
    }
    
    static func removeItem(at url: URL) throws  {
        let code = TrollStoreUtils.spawnAsRoot(rootHelperPath, ["rm", url.path, ""])
        guard code == 0 else { throw "roothelper.removeItem: returned a non-zero code \(code)" }
    }
    
    static func setPermission(url: URL) throws {
        let code = TrollStoreUtils.spawnAsRoot(rootHelperPath, ["chmod", url.path, ""])
        guard code == 0 else { throw "roothelper.setPermission: returned a non-zero code \(code)" }
    }
    
    static func rebuildIconCache() throws {
        let code = TrollStoreUtils.spawnAsRoot(rootHelperPath, ["rebuildiconcache", "", ""])
        guard code == 0 else { throw "roothelper.rebuildIconCache: returned a non-zero code \(code)" }
    }
    
    static func refreshAppRegistration(from appBundle: URL) throws {
        let code = TrollStoreUtils.spawnAsRoot(rootHelperPath, ["refregapp", appBundle.path])
        guard code == 0 else { throw "roothelper.refreshAppRegistration: returned a non-zero code \(code)" }
    }
    
    static func kill(pid: Int) throws {
        let code = TrollStoreUtils.spawnAsRoot(rootHelperPath, ["kill", "\(pid)"])
        guard code == 0 else { throw "roothelper.kill: returned a non-zero code \(code)" }
    }
    
    static func kill(pid: Int, signal: Int) throws {
        let code = TrollStoreUtils.spawnAsRoot(rootHelperPath, ["kill", "\(pid)", "\(signal)"])
        guard code == 0 else { throw "roothelper.kill: returned a non-zero code \(code)" }
    }
}
