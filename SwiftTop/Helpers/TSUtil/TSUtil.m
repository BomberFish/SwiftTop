#import "TSUtil.h"

NSString* rootHelperPath(void) {
    return [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"roothelper"];
}

@interface PSAppDataUsagePolicyCache : NSObject
+ (instancetype)sharedInstance;
- (void)setUsagePoliciesForBundle:(NSString*)bundleId cellular:(BOOL)cellular wifi:(BOOL)wifi;
@end

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);
extern char*** _NSGetArgv(void);

NSString* safe_getExecutablePath(void)
{
    char* executablePathC = **_NSGetArgv();
    return [NSString stringWithUTF8String:executablePathC];
}

NSString* getNSStringFromFile(int fd)
{
    NSMutableString* ms = [NSMutableString new];
    ssize_t num_read;
    char c;
    while((num_read = read(fd, &c, sizeof(c))))
    {
        [ms appendString:[NSString stringWithFormat:@"%c", c]];
    }
    return ms.copy;
}

void printMultilineNSString(NSString* stringToPrint)
{
    NSCharacterSet *separator = [NSCharacterSet newlineCharacterSet];
    NSArray* lines = [stringToPrint componentsSeparatedByCharactersInSet:separator];
    for(NSString* line in lines)
    {
        NSLog(@"%@", line);
    }
}

int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr)
{
    NSMutableArray* argsM = args.mutableCopy ?: [NSMutableArray new];
    [argsM insertObject:path atIndex:0];
    
    NSUInteger argCount = [argsM count];
    char **argsC = (char **)malloc((argCount + 1) * sizeof(char*));

    for (NSUInteger i = 0; i < argCount; i++)
    {
        argsC[i] = strdup([[argsM objectAtIndex:i] UTF8String]);
    }
    argsC[argCount] = NULL;

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);

    int outErr[2];
    if(stdErr)
    {
        pipe(outErr);
        posix_spawn_file_actions_adddup2(&action, outErr[1], STDERR_FILENO);
        posix_spawn_file_actions_addclose(&action, outErr[0]);
    }

    int out[2];
    if(stdOut)
    {
        pipe(out);
        posix_spawn_file_actions_adddup2(&action, out[1], STDOUT_FILENO);
        posix_spawn_file_actions_addclose(&action, out[0]);
    }
    
    pid_t task_pid;
    int status = -200;
    int spawnError = posix_spawn(&task_pid, [path UTF8String], &action, &attr, (char* const*)argsC, NULL);
    posix_spawnattr_destroy(&attr);
    for (NSUInteger i = 0; i < argCount; i++)
    {
        free(argsC[i]);
    }
    free(argsC);
    
    if(spawnError != 0)
    {
        NSLog(@"posix_spawn error %d: %s\n", spawnError, strerror(spawnError));
        return spawnError;
    }

    __block volatile BOOL _isRunning = YES;
    NSMutableString* outString = [NSMutableString new];
    NSMutableString* errString = [NSMutableString new];
    dispatch_semaphore_t sema = 0;
    dispatch_queue_t logQueue;
    if(stdOut || stdErr)
    {
        logQueue = dispatch_queue_create("net.sourceloc.Picasso.LogCollector", NULL);
        sema = dispatch_semaphore_create(0);

        int outPipe = out[0];
        int outErrPipe = outErr[0];

        __block BOOL outEnabled = (BOOL)stdOut;
        __block BOOL errEnabled = (BOOL)stdErr;
        dispatch_async(logQueue, ^
        {
            while(_isRunning)
            {
                @autoreleasepool
                {
                    if(outEnabled)
                    {
                        [outString appendString:getNSStringFromFile(outPipe)];
                    }
                    if(errEnabled)
                    {
                        [errString appendString:getNSStringFromFile(outErrPipe)];
                    }
                }
            }
            dispatch_semaphore_signal(sema);
        });
    }

    do
    {
        if (waitpid(task_pid, &status, 0) != -1) {
            NSLog(@"Child status %d", WEXITSTATUS(status));
        } else
        {
            perror("waitpid");
            _isRunning = NO;
            return -222;
        }
    } while (!WIFEXITED(status) && !WIFSIGNALED(status));

    _isRunning = NO;
    if(stdOut || stdErr)
    {
        if(stdOut)
        {
            close(out[1]);
        }
        if(stdErr)
        {
            close(outErr[1]);
        }

        // wait for logging queue to finish
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

        if(stdOut)
        {
            *stdOut = outString.copy;
        }
        if(stdErr)
        {
            *stdErr = errString.copy;
        }
    }

    return WEXITSTATUS(status);
}

/// NOTE: Returns own PID on failure.
pid_t spawnRootButReturnPID(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr)
{
    NSMutableArray* argsM = args.mutableCopy ?: [NSMutableArray new];
    [argsM insertObject:path atIndex:0];
    
    NSUInteger argCount = [argsM count];
    char **argsC = (char **)malloc((argCount + 1) * sizeof(char*));

    for (NSUInteger i = 0; i < argCount; i++)
    {
        argsC[i] = strdup([[argsM objectAtIndex:i] UTF8String]);
    }
    argsC[argCount] = NULL;

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);

    int outErr[2];
    if(stdErr)
    {
        pipe(outErr);
        posix_spawn_file_actions_adddup2(&action, outErr[1], STDERR_FILENO);
        posix_spawn_file_actions_addclose(&action, outErr[0]);
    }

    int out[2];
    if(stdOut)
    {
        pipe(out);
        posix_spawn_file_actions_adddup2(&action, out[1], STDOUT_FILENO);
        posix_spawn_file_actions_addclose(&action, out[0]);
    }
    
    pid_t task_pid;
//    int status = -200;
    int spawnError = posix_spawn(&task_pid, [path UTF8String], &action, &attr, (char* const*)argsC, NULL);
    posix_spawnattr_destroy(&attr);
    for (NSUInteger i = 0; i < argCount; i++)
    {
        free(argsC[i]);
    }
    free(argsC);
    
    if(spawnError != 0)
    {
        NSLog(@"posix_spawn error %d: %s\n", spawnError, strerror(spawnError));
        return getpid();
    }
    
    return task_pid;
}
