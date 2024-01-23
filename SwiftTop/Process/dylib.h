// bomberfish
// dylib.h – SwiftTop
// created on 2024-01-10

#ifndef dylib_h
#define dylib_h

#import <Foundation/Foundation.h>
#include <mach/mach.h>
#include <mach-o/dyld_images.h>
#include <mach-o/loader.h>
#include "procinfo.h"
#include "mach.h"
#include <MacTypes.h>

NSArray *getDylibsForPID(pid_t pid);
struct mach_header toHeader(NSDictionary *dict);
NSDictionary *toDict(const struct mach_header *header);

#endif /* dylib_h */
