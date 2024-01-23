// bomberfish
// proc.m – SwiftTop
// created on 2023-12-14

// objc (womp womp)

#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#import <mach-o/dyld_images.h>
#import <libgen.h>
#include <pwd.h>
#include "procinfo.h"


NSArray *sysctl_ps(void) {
    NSMutableArray *array = [[NSMutableArray alloc] init];

    int numberOfProcesses = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    pid_t pids[numberOfProcesses];
//    pid_t owners[numberOfProcesses];
    bzero(pids, sizeof(pids));
//    proc_listpids(PROC_ALL_PIDS, 0, pids, (int)sizeof(pids));
    proc_listallpids(pids, (int)sizeof(pids));
    for (int i = 0; i < numberOfProcesses; ++i) {
        if (pids[i] == 0) { continue; }
        char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
        bzero(pathBuffer, PROC_PIDPATHINFO_MAXSIZE);
        proc_pidpath(pids[i], pathBuffer, sizeof(pathBuffer));
        
        struct proc_bsdinfo procInfo;
        proc_pidinfo(pids[i], PROC_PIDTBSDINFO, 0, &procInfo, sizeof(procInfo));
        

        if (strlen(pathBuffer) > 0) {
            NSString *processID = [[NSString alloc] initWithFormat:@"%d", pids[i]];
            NSString *parentProcessID = [[NSString alloc] initWithFormat:@"%d", procInfo.pbi_ppid];
            NSString *processPath = [[NSString stringWithUTF8String:pathBuffer] stringByResolvingSymlinksInPath];
            NSString *processName = [[NSString stringWithUTF8String:pathBuffer] lastPathComponent];
            NSString *processOwner = [[NSString alloc] initWithFormat:@"%s (%d)", getpwuid(procInfo.pbi_uid)->pw_name, procInfo.pbi_uid];
            
            NSDictionary *dict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:processID, parentProcessID, processPath, processName, processOwner, nil] forKeys:[NSArray arrayWithObjects:@"pid", @"ppid", @"proc_path", @"proc_name", @"proc_owner", nil]];
            
            [array addObject:dict];
        }
    }

    return [array copy];
}
