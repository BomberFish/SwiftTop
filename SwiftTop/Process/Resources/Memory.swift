// bomberfish
// Resources.swift – SwiftTop
// created on 2024-01-09

import Foundation
import Darwin

struct Memory {
    public init() {}
    fileprivate static let machHost = mach_host_self()
    
    fileprivate static func VMStatistics64() -> vm_statistics64 {
        var size = HOST_VM_INFO64_COUNT
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)
        defer { hostInfo.deallocate() }
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(machHost,
                              HOST_VM_INFO64,
                              $0,
                              &size)
        }

        let data = hostInfo.move()
        
        #if DEBUG
            if result != KERN_SUCCESS {
                print("ERROR - \(#file):\(#function) - kern_result_t = "
                    + "\(result)")
            }
        #endif
            
        return data
    }
    
    /// Total memory in bytes
    func getTotalMemory() -> UInt64 {
//        var pagesize: vm_size_t = 0
//        
//        let host_port: mach_port_t = mach_host_self()
//        var host_size = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
//        host_page_size(host_port, &pagesize)
//        
//        var vm_stat: vm_statistics = vm_statistics_data_t()
//        withUnsafeMutablePointer(to: &vm_stat) { vmStatPointer in
//            vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
//                if host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS {
//                    NSLog("Error: Failed to fetch vm statistics")
//                }
//            }
//        }
//        
//        /* Stats in bytes */
//        let mem_used = Int64(vm_stat.active_count +
//            vm_stat.inactive_count +
//            vm_stat.wire_count) * Int64(pagesize)
//        let mem_free = Int64(vm_stat.free_count) * Int64(pagesize)
//        
//        return mem_used + mem_free
        return ProcessInfo.processInfo.physicalMemory
    }
    
    func getUsedMemory() -> Int64 {
        var pagesize: vm_size_t = 0
        
        let host_port: mach_port_t = mach_host_self()
        var host_size = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        host_page_size(host_port, &pagesize)
        
        var vm_stat: vm_statistics = vm_statistics_data_t()
        withUnsafeMutablePointer(to: &vm_stat) { vmStatPointer in
            vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
                if host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS {
                    NSLog("Error: Failed to fetch vm statistics")
                }
            }
        }
        
        /* Stats in bytes */
        let mem_used = Int64(vm_stat.active_count +
            vm_stat.inactive_count +
            vm_stat.wire_count) * Int64(pagesize)
        
        return mem_used
    }
    
    func getFreeMemory() -> Int64 {
        var pagesize: vm_size_t = 0
        
        let host_port: mach_port_t = mach_host_self()
        var host_size = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        host_page_size(host_port, &pagesize)
        
        var vm_stat: vm_statistics = vm_statistics_data_t()
        withUnsafeMutablePointer(to: &vm_stat) { vmStatPointer in
            vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
                if host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS {
                    NSLog("Error: Failed to fetch vm statistics")
                }
            }
        }
        
        /* Stats in bytes */
        let mem_free = Int64(vm_stat.free_count) * Int64(pagesize)
        
        return mem_free
    }
}
