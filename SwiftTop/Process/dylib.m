// bomberfish
// dylib.m – SwiftTop
// created on 2024-01-10
// I truly hate Objective-C.

#include "dylib.h"
#include <Foundation/Foundation.h>

#define USEHELPERFORPORT 0

// RootHelper doesn't have TSUtil (and doesn't need it)
#ifndef ROOTHELPER
#include "TSUtil.h"
#include "ps.h"
#endif

#ifdef USEHELPERFORROOT
/// Call function, get port!!1
mach_port_t getAPort(void) {
#ifdef ROOTHELPER
  // Roothelper is already root, we don't need to do much here.
  return mach_task_self();
#else
  task_port_t task;
  // Spawn dummy roothelper
  printf("Spawning the dummy");
  pid_t rootHelper =
      spawnRootButReturnPID(rootHelperPath(), @[ @"spin" ], NULL, NULL);
  if (rootHelper == getpid()) {
    // In case spawnRoot doesn't work. Not completely necessary since it
    // (probably) ends up producing the same result as mach_task_self on failure
    // (since it returns the ppid), so might as well save ourselves a step ;)
    fprintf(
        stderr,
        "Something went wrong while spawning roothelper. Reverting to plain "
        "old mach_task_self :(");
    return mach_task_self();
  }
  // Get task port for roothelper (it should let us, since it has the right
  // entitlements)
  printf("Getting mach task for dummy");
  kern_return_t kr = task_for_pid(mach_task_self(), rootHelper, &task);
  if (kr) {
    fprintf(stderr,
            "Error getting task_for_pid for pid %d: %s (return code %d)",
            rootHelper, mach_error_string(kr), kr);
    return mach_task_self();
  } else {
    return task;
  }
#endif
}
#else
mach_port_t getAPort(void) {
  return mach_task_self();
}
#endif

// (Partially) stolen from CocoaTop. Most likely a workaround for h3lix on 32-bit iOS? (See
// https://www.theiphonewiki.com/wiki/Tfp0_patch#Jailbreaks_lacking_tfp0)
kern_return_t _task_for_pid(pid_t pid, task_port_t *target) {
  if (pid == getpid()) {
    *target = mach_task_self(); // Save a step once more ;D
    return KERN_SUCCESS;
  }
  kern_return_t ret = task_for_pid(getAPort(), pid, target);
  if (ret != KERN_SUCCESS && pid == 0) {
    fprintf(stderr, "task_for_pid failed for pid 0: %s\n",
            mach_error_string(ret));
    ret = host_get_special_port(mach_host_self(), HOST_LOCAL_NODE, 4, target);
  }
  return ret;
}

// vm_read wrapper thingamajig
kern_return_t _vm_read(task_t task, mach_vm_address_t addr, mach_vm_size_t size,
                       vm_offset_t *data, mach_msg_type_number_t *dataCnt) {
  // First try mach_vm_read
  kern_return_t kr = mach_vm_read(task, addr, size, data, dataCnt);
  if (kr) {
    fprintf(stderr,
            "(mach_vm_read) Unable to read target task's memory @%p - kr 0x%x "
            "- %s. Trying vm_read.\n",
            (void *)addr, kr, mach_error_string(kr));
    // Fall back on good ol' vm_read
    kr = vm_read(task, addr, size, data, dataCnt);
  }
  return kr;
}

// https://gist.github.com/xcxcxc/989018646b1f0f2f31f0873a32c4a658

// Reads memory from a process. What else did you expect?!
unsigned char *readProcessMemory(mach_port_t task, mach_vm_address_t addr,
                                 mach_vm_size_t *size) {
  kern_return_t kr;
  mach_msg_type_number_t dataCnt = (mach_msg_type_number_t)*size;
  vm_offset_t readMem;
  kr = _vm_read(task, addr, *size, &readMem, &dataCnt); // Use our nice wrapper
  if (kr) {
    fprintf(stderr,
            "(_vm_read) Unable to read target task's memory @%p - kr 0x%x - "
            "%s. Giving up.\n",
            (void *)addr, kr, mach_error_string(kr));
    return NULL;
  }
  return ((unsigned char *)readMem);
}

/// Get all loaded dylibs for a given PID.
/// Returns an array of NSDictionary: [imageName: NSString, imagePath: NSString,
/// loadAddr: mach_header] In Swift, treat imageName and imagePath as `String`
/// types or equivalent. loadAddr should be converted to `mach_header` (with the
/// handy toHeader function included) and nothing else. See `<mach-o/loader.h>`
/// for more info.
NSArray *getDylibsForPID(pid_t pid) {
  // Set up array
  NSMutableArray *dylibs = [NSMutableArray array];
  task_t task = mach_task_self();
  kern_return_t kr;
  bool isTraced = false;

  kr = ptrace(PT_ATTACH, pid, NULL, 0);
  isTraced = true;
  if (kr != 0) {
    fprintf(stderr, "pt attach failed for pid %d: %s. Continuing anyway\n", pid,
            mach_error_string(kr));
    isTraced = false;
  } else {
    printf("WE ARE ATTACHED (pid %d)\n", pid);
  }

  kr = _task_for_pid(pid, &task);
  if (kr != KERN_SUCCESS) {
    fprintf(stderr, "task_for_pid failed for pid %d: %s\n", pid,
            mach_error_string(kr));
    return NULL;
  }
  struct task_dyld_info dyld_info;
  mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
  kr = task_info(getAPort(), TASK_DYLD_INFO, (task_info_t)&dyld_info,
                 &count);
  if (kr == KERN_SUCCESS) {
    mach_vm_size_t size = sizeof(struct dyld_all_image_infos);
    uint8_t *data =
        readProcessMemory(task, dyld_info.all_image_info_addr, &size);
    if (!data) {
        return NULL;
    }
    struct dyld_all_image_infos *infos = (struct dyld_all_image_infos *)data;
    mach_vm_size_t size2 =
        sizeof(struct dyld_image_info) * infos->infoArrayCount;
    uint8_t *info_addr =
        readProcessMemory(task, (mach_vm_address_t)infos->infoArray, &size2);
    if (!info_addr) {
        return NULL;
    }
    struct dyld_image_info *info = (struct dyld_image_info *)info_addr;
    for (int i = 0; i < infos->infoArrayCount; i++) {
      mach_vm_size_t size3 = PATH_MAX;
      uint8_t *fpath_addr = readProcessMemory(
          task, (mach_vm_address_t)info[i].imageFilePath, &size3);
      if (fpath_addr) {
        printf("path: %s %llu\n", fpath_addr, size3);
      }

      @autoreleasepool {
        NSString *imagePath = @"/foo/bar/UnknownLibrary";
        if (info[i].imageFilePath) {
            @try {
                NSString *imagePathTemp = [NSString stringWithCString:info[i].imageFilePath
                                               encoding:NSNEXTSTEPStringEncoding];
                if (imagePathTemp) {
                    imagePath = imagePathTemp;
                } else {
                    @throw [NSException exceptionWithName:@"ca.bomberfish.SwiftTop.dylib" reason:@"imagePath is null" userInfo:@{}];
                }
            } @catch (NSException *e) {
                NSLog(@"Ignoring dylib #%d (pid %d): Got exception \"%@\" while trying to convert imageFilePath to NSString", i, pid, e);
                continue;
            }
        }
        // thanks dhinakg for fixing the horrendous syntax that used to be
        // here...
        NSString *imageName = imagePath.lastPathComponent;
        @try {
          NSDictionary *dict = @{@"imageName" : imageName, @"imagePath" : imagePath};
          [dylibs addObject:dict];
        } @catch (NSException *exception) {
          NSLog(@"Ignoring dylib #%d (pid %d): Got exception \"%@\" while trying to construct dictionary", i, pid, exception);
          continue;
        }
      }
    }
  } else {
    printf("task_info failed for pid %d: %s\n", pid, mach_error_string(kr));
      return NULL;
  }

  if (isTraced) {
    printf("detaching from pid %d", pid);
    kr = ptrace(PT_DETACH, pid, NULL, 0);
    if (kr != 0) {
      printf("detach failed for pid %d: %s. This could end badly.\n", pid,
             mach_error_string(kr));
    } else {
      printf("detached successfully from pid %d\n", pid);
    }
  } else {
    printf("not detaching from pid %d", pid);
  }

//#ifndef ROOTHELPER
//    NSArray *processes = sysctl_ps();
//    for (NSDictionary *process in processes) {
//        if ([process[@"proc_path"] stringValue] == rootHelperPath()) {
//            printf("Killing spinning process... by spawning another instance of it?!");
//            int ret = spawnRoot(rootHelperPath(), @[ @"kill", process[@"pid"] ], NULL, NULL);
//        }
//    }
//#endif

  return [dylibs copy];
}

// shoutouts to fiore
NSDictionary *toDict(const struct mach_header *header) {
  struct mach_header *mutableHeader = (struct mach_header *)header;
  return @{
    @"magic" : @(mutableHeader->magic),
    @"cputype" : @(mutableHeader->cputype),
    @"cpusubtype" : @(mutableHeader->cpusubtype),
    @"filetype" : @(mutableHeader->filetype),
    @"ncmds" : @(mutableHeader->ncmds),
    @"sizeofcmds" : @(mutableHeader->sizeofcmds),
    @"flags" : @(mutableHeader->flags)
  };
}

struct mach_header toHeader(NSDictionary *dict) {
  struct mach_header header;

  header.magic = [dict[@"magic"] unsignedIntValue];
  header.cputype = [dict[@"cputype"] intValue];
  header.cpusubtype = [dict[@"cpusubtype"] intValue];
  header.filetype = [dict[@"filetype"] unsignedIntValue];
  header.ncmds = [dict[@"ncmds"] unsignedIntValue];
  header.sizeofcmds = [dict[@"sizeofcmds"] unsignedIntValue];
  header.flags = [dict[@"flags"] unsignedIntValue];

  return header;
}
