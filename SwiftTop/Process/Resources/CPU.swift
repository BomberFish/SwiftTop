// bomberfish
// CPU.swift – SwiftTop
// created on 2024-01-09

import Darwin
import Foundation
import OSLog

public let HOST_BASIC_INFO_COUNT         : mach_msg_type_number_t =
                      UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
public let HOST_LOAD_INFO_COUNT          : mach_msg_type_number_t =
                       UInt32(MemoryLayout<host_load_info_data_t>.size / MemoryLayout<integer_t>.size)
public let HOST_CPU_LOAD_INFO_COUNT      : mach_msg_type_number_t =
                   UInt32(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
public let HOST_VM_INFO64_COUNT          : mach_msg_type_number_t =
                      UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
public let HOST_SCHED_INFO_COUNT         : mach_msg_type_number_t =
                      UInt32(MemoryLayout<host_sched_info_data_t>.size / MemoryLayout<integer_t>.size)
public let PROCESSOR_SET_LOAD_INFO_COUNT : mach_msg_type_number_t =
              UInt32(MemoryLayout<processor_set_load_info_data_t>.size / MemoryLayout<natural_t>.size)

struct CPU {
    public init() { }
    fileprivate static let machHost = mach_host_self()
    fileprivate var loadPrevious = host_cpu_load_info()
        
    /// Stolen from [SystemKit](https://github.com/beltex/SystemKit/blob/master/SystemKit/System.swift), with some changes to make it more modern.
    public mutating func usageCPU() -> (system: Double, user: Double, idle: Double, nice: Double) {
        let load = CPU.hostCPULoadInfo()
           
        let userDiff = Double(load.cpu_ticks.0 - loadPrevious.cpu_ticks.0)
        let sysDiff = Double(load.cpu_ticks.1 - loadPrevious.cpu_ticks.1)
        let idleDiff = Double(load.cpu_ticks.2 - loadPrevious.cpu_ticks.2)
        let niceDiff = Double(load.cpu_ticks.3 - loadPrevious.cpu_ticks.3)
           
        let totalTicks = sysDiff + userDiff + niceDiff + idleDiff
           
        let sys = sysDiff / totalTicks * 100.0
        let user = userDiff / totalTicks * 100.0
        let idle = idleDiff / totalTicks * 100.0
        let nice = niceDiff / totalTicks * 100.0
        loadPrevious = load
           
        // TODO: 2 decimal places
        // TODO: Check that total is 100%
        return (sys, user, idle, nice)
    }

    fileprivate static func hostCPULoadInfo() -> host_cpu_load_info {
        var size = HOST_CPU_LOAD_INFO_COUNT
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        defer { hostInfo.deallocate() }
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(machHost, HOST_CPU_LOAD_INFO,
                            $0,
                            &size)
        }
            
        let data = hostInfo.move()
        if result != KERN_SUCCESS {
            print("ERROR - \(#file):\(#function) - kern_result_t = " + "\(result)")
        }

        return data
    }
}
