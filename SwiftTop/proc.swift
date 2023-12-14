// bomberfish
// proc.swift – SwiftTop
// created on 2023-12-14

//import Foundation
//
//func proc_pidpath(pid: Int32, buffer: UnsafeMutablePointer<Int8>, buffersize: Int32) -> Int32 {
//    return proc_pidpath(pid, UnsafeMutablePointer<Int8>(buffer), buffersize)
//}
//
//func proc_listpids(type: Int32, typeinfo: Int32, buffer: UnsafeMutablePointer<Int8>, buffersize: Int32) -> Int32 {
//    return proc_listpids(type, typeinfo, UnsafeMutablePointer<Int8>(buffer), buffersize)
//}
//
//func sysctl_ps() -> NSArray {
//    let array = NSMutableArray()
//    let numberOfProcesses = Int(proc_listpids(1, 0, nil, 0))
//    var pids = [Int32](count: numberOfProcesses, repeatedValue: 0)
//    proc_listpids(1, 0, &pids, Int32(sizeof(Int32) * numberOfProcesses))
//    
//    for i in 0..<numberOfProcesses {
//        if pids[i] == 0 {
//            continue
//        }
//        var pathBuffer = [Int8](count: Int(PROC_PIDPATHINFO_MAXSIZE), repeatedValue: 0)
//        proc_pidpath(pids[i], &pathBuffer, Int32(sizeof(Int8) * Int(PROC_PIDPATHINFO_MAXSIZE)))
//        let processID = String(format: "%d", pids[i])
//        let processPath = String.fromCString(pathBuffer)
//        let processName = String.fromCString(pathBuffer).lastPathComponent
//        let dict = NSDictionary(objects: [processID, processPath!, processName!], forKeys: ["pid", "proc_path", "proc_name"])
//        array.addObject(dict)
//    }
//    
//    return array.copy() as NSArray
//}
