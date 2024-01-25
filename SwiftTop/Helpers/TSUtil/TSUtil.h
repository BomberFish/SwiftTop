@import Foundation;
#import "CoreServices.h"
#import <Foundation/Foundation.h>
#import <spawn.h>
#import <sys/sysctl.h>
#import <mach-o/fixup-chains.h>

extern NSString* safe_getExecutablePath(void);
extern NSString* rootHelperPath(void);
extern int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);  
extern pid_t spawnRootButReturnPID(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);
extern NSString* rootHelperPath(void);
