// bomberfish
// proc.h – SwiftTop
// created on 2023-12-14

#ifndef proc_h
#define proc_h
#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#import <mach-o/dyld_images.h>
#import <libgen.h>
int proc_pidpath(int pid, void *buffer, uint32_t buffersize);
int proc_listpids(uint32_t type, uint32_t typeinfo, void *buffer, int buffersize);
NSArray *sysctl_ps(void);

#endif /* proc_h */
