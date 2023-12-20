// bomberfish
// Utils.swift – SwiftTop
// created on 2023-12-14

import Foundation

func killProcess(_ pid: Int32, _ sig: Signal = .KILL) throws {
    let ret = kill(pid, sig.rawValue)
    if ret != 0 {
        throw "kill() returned a non-zero exit code"
    }
}

func log(_ objs: Any...) { // stolen from cardculator :trol:
    let string = objs.map { String(describing: $0) }.joined(separator: "; ")
    let args: [CVarArg] = [ "[SwiftTop-\(Date().description)] \(string)" ]
    withVaList(args) { RLogv("%@", $0) }
}

// signal.h
/// A signal to send to a process
enum Signal: Int32 {
    /// hangup
    case HUP = 1
    /// interrupt
    case INT = 2
    /// quit
    case QUIT = 3
    /// illegal instruction (not reset when caught)
    case ILL = 4
    /// trace trap (not reset when caught)
    case TRAP = 5
    /// abort()
    case ABRT = 6
    /// pollable event ([XSR] generated, not supported)
    case POLL = 7
    /// floating point exception
    case FPE = 8
    /// kill (cannot be caught or ignored)
    case KILL = 9
    /// bus error
    case BUS = 10
    /// segmentation violation
    case SEGV = 11
    /// bad argument to system call
    case SYS = 12
    /// write on a pipe with no one to read it
    case PIPE = 13
    /// alarm clock
    case ALRM = 14
    /// software termination signal from kill
    case TERM = 15
    /// urgent condition on IO channel
    case URG = 16
    /// sendable stop signal not from tty
    case STOP = 17
    /// stop signal from tty
    case TSTP = 18
    /// continue a stopped process
    case CONT = 19
    /// to parent on child stop or exit
    case CHLD = 20
    /// to readers pgrp upon background tty read
    case TTIN = 21
    /// like TTIN for output if (tp->t_local&LTOSTOP)
    case TTOU = 22
    /// input/output possible signal
    case IO = 23
    /// exceeded CPU time limit
    case XCPU = 24
    /// exceeded file size limit
    case XFSZ = 25
    /// virtual time alarm
    case VTALRM = 26
    /// profiling time alarm
    case PROF = 27
    /// window size changes
    case WINCH = 28
    /// information request
    case INFO = 29
    /// user defined signal 1
    case USR1 = 30
    /// user defined signal 2
    case USR2 = 31
}
