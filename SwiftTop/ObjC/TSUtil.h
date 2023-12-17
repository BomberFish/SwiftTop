@import Foundation;
#import "CoreServices.h"

extern NSString* safe_getExecutablePath(void);
extern NSString* rootHelperPath(void);
extern int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);  
