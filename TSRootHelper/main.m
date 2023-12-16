//#include <csignal>
#include <RemoteLog.h>
#include <signal.h>
#import <stdio.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "uicache.h"
#import <sys/stat.h>
#import <dlfcn.h>
#import <spawn.h>
#import <objc/runtime.h>
#import "TSUtil.h"
#import <sys/utsname.h>

#import <SpringBoardServices/SpringBoardServices.h>
#import <Security/Security.h>

void Log(NSString* logMessage)
{
    NSLog(@"%@", logMessage);
    RLog(logMessage);
    
    // I love Copilot
    // Get the Document directory path.
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    // Append the log file name to the document directory path.
    NSString *logFilePath = [docDir stringByAppendingPathComponent:@"logjam.log"];

    // Get current date and time for timestamp.
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];

    // Prepare the log message with timestamp.
    NSString *logMessageWithTimestamp = [NSString stringWithFormat:@"%@: %@", dateString, logMessage];

    // Check if file exists.
    if([[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
        // If file exists, append the log message.
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logMessageWithTimestamp dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else {
        // If file doesn't exist, create a new file and write the log message.
        [logMessageWithTimestamp writeToFile:logFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

NSSet<NSString*>* immutableAppBundleIdentifiers(void)
{
	NSMutableSet* systemAppIdentifiers = [NSMutableSet new];

	LSEnumerator* enumerator = [LSEnumerator enumeratorForApplicationProxiesWithOptions:0];
	LSApplicationProxy* appProxy;
	while(appProxy = [enumerator nextObject])
	{
		if(appProxy.installed)
		{
			if(![appProxy.bundleURL.path hasPrefix:@"/private/var/containers"])
			{
				[systemAppIdentifiers addObject:appProxy.bundleIdentifier.lowercaseString];
			}
		}
	}

	return systemAppIdentifiers.copy;
}

void refreshAppRegistrations()
{
	registerPath((char*)trollStoreAppPath().UTF8String, 0, YES);

	for(NSString* appPath in trollStoreInstalledAppBundlePaths())
	{
		registerPath((char*)appPath.UTF8String, 0, YES);
	}
}

void refreshAppRegistration(NSString* appBundle)
{
    registerPath((char*)appBundle.UTF8String, 1, YES);
}

// Apparently there is some odd behaviour where TrollStore installed apps sometimes get restricted
// This works around that issue at least and is triggered when rebuilding icon cache
void cleanRestrictions(void)
{
	NSString* clientTruthPath = @"/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/ClientTruth.plist";
	NSURL* clientTruthURL = [NSURL fileURLWithPath:clientTruthPath];
	NSDictionary* clientTruthDictionary = [NSDictionary dictionaryWithContentsOfURL:clientTruthURL];

	if(!clientTruthDictionary) return;

	NSArray* valuesArr;

	NSDictionary* lsdAppRemoval = clientTruthDictionary[@"com.apple.lsd.appremoval"];
	if(lsdAppRemoval && [lsdAppRemoval isKindOfClass:NSDictionary.class])
	{
		NSDictionary* clientRestrictions = lsdAppRemoval[@"clientRestrictions"];
		if(clientRestrictions && [clientRestrictions isKindOfClass:NSDictionary.class])
		{
			NSDictionary* unionDict = clientRestrictions[@"union"];
			if(unionDict && [unionDict isKindOfClass:NSDictionary.class])
			{
				NSDictionary* removedSystemAppBundleIDs = unionDict[@"removedSystemAppBundleIDs"];
				if(removedSystemAppBundleIDs && [removedSystemAppBundleIDs isKindOfClass:NSDictionary.class])
				{
					valuesArr = removedSystemAppBundleIDs[@"values"];
				}
			}
		}
	}

	if(!valuesArr || !valuesArr.count) return;

	NSMutableArray* valuesArrM = valuesArr.mutableCopy;
	__block BOOL changed = NO;

	[valuesArrM enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString* value, NSUInteger idx, BOOL *stop)
	{
		if(![value hasPrefix:@"com.apple."])
		{
			[valuesArrM removeObjectAtIndex:idx];
			changed = YES;
		}
	}];

	if(!changed) return;

	NSMutableDictionary* clientTruthDictionaryM = (__bridge_transfer NSMutableDictionary*)CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (__bridge CFDictionaryRef)clientTruthDictionary, kCFPropertyListMutableContainersAndLeaves);
	
	clientTruthDictionaryM[@"com.apple.lsd.appremoval"][@"clientRestrictions"][@"union"][@"removedSystemAppBundleIDs"][@"values"] = valuesArrM;

	[clientTruthDictionaryM writeToURL:clientTruthURL error:nil];
}

int main(int argc, char *argv[], char *envp[]) {
    @autoreleasepool {
        NSString *logMessage1 = [NSString stringWithFormat:@"[RootHelper] RootHelper called"];
        Log(logMessage1);
        [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/testrebuild" withIntermediateDirectories:true attributes:nil error:nil];

        NSString* action = [NSString stringWithUTF8String:argv[1]];
        NSString* source = [NSString stringWithUTF8String:argv[2]];
        NSString* destination = [NSString stringWithUTF8String:argv[3]];
        pid_t pid = atoi(argv[2]);
        int sig = atoi(argv[3]);

        if ([action isEqual: @"write"]) {
            NSString *logMessage2 = [NSString stringWithFormat:@"[RootHelper] Writing %@ to %@", source, destination];
            Log(logMessage2);
            [source writeToFile:destination atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else if ([action isEqual: @"mv"]) {
            NSString *logMessage3 = [NSString stringWithFormat:@"[RootHelper] Moving %@ to %@", source, destination];
            Log(logMessage3);
            [[NSFileManager defaultManager] moveItemAtPath:source toPath:destination error:nil];
        } else if ([action isEqual: @"cp"]) {
            NSString *logMessage4 = [NSString stringWithFormat:@"[RootHelper] Copying %@ to %@", source, destination];
            Log(logMessage4);
            [[NSFileManager defaultManager] copyItemAtPath:source toPath:destination error:nil];
        } else if ([action isEqual: @"mkdir"]) {
            NSString *logMessage5 = [NSString stringWithFormat:@"[RootHelper] Making directory %@", source];
            Log(logMessage5);
            [[NSFileManager defaultManager] createDirectoryAtPath:source withIntermediateDirectories:true attributes:nil error:nil];
        } else if ([action isEqual: @"rm"]) {
            NSString *logMessage6 = [NSString stringWithFormat:@"[RootHelper] Removing %@", source];
            Log(logMessage6);
            [[NSFileManager defaultManager] removeItemAtPath:source error:nil];
        } else if ([action isEqual: @"chmod"]) {
            NSString *logMessage7 = [NSString stringWithFormat:@"[RootHelper] Changing perms of %@", source];
            Log(logMessage7);
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:[NSNumber numberWithInt:511]  forKey:NSFilePosixPermissions];
            [[NSFileManager defaultManager] setAttributes:dict ofItemAtPath:source error:nil];
        } else if ([action isEqual: @"rebuildiconcache"]) {
            NSString *logMessage8 = [NSString stringWithFormat:@"[RootHelper] Rebuilding iconcache"];
            Log(logMessage8);
            cleanRestrictions();
            [[LSApplicationWorkspace defaultWorkspace] _LSPrivateRebuildApplicationDatabasesForSystemApps:YES internal:YES user:YES];
            refreshAppRegistrations();
            killall(@"backboardd", true);
        } else if ([action isEqual: @"ln"]) {
            NSString *logMessage9 = [NSString stringWithFormat:@"[RootHelper] Linking %@ to %@", source, destination];
            Log(logMessage9);
            [[NSFileManager defaultManager] createSymbolicLinkAtPath:destination withDestinationPath:source error:nil];
        } else if ([action isEqual: @"pidkill"]) {
            NSString *logMessage10, *logMessage11, *logMessage12;
            if (argc == 3) {
                int ret = kill(pid, sig);
                logMessage10 = [NSString stringWithFormat:@"[RootHelper] Killing pid %d returned code %d", pid, ret];
                Log(logMessage10);
                if (ret != 0) {
//                    logMessage11 = [NSString stringWithFormat:@"[RootHelper] Errno %d", errno];
                    Log(logMessage11);
                    return 6;
                }
                return ret;
            } else if (argc == 2) {
                int ret = kill(pid, SIGKILL);
                logMessage10 = [NSString stringWithFormat:@"[RootHelper] Killing pid %d returned code %d", pid, ret];
                Log(logMessage10);
                if (ret != 0) {
//                    logMessage11 = [NSString stringWithFormat:@"[RootHelper] Errno %d", errno];
                    Log(logMessage11);
                    return 6;
                }
                return ret;
            } else {
                logMessage12 = [NSString stringWithFormat:@"[RootHelper] Invalid number of arguments: %d", argc];
                Log(logMessage12);
                return 4;
            }
        } else if ([action isEqual: @"pkill"]) {
            NSString *logMessage13;
            if (argc < 2) {
                logMessage13 = [NSString stringWithFormat:@"[RootHelper] Invalid number of arguments: %d", argc];
                Log(logMessage13);
                return 4;
            } else {
                killall(source, true);
            }
        } else {
            NSString *logMessage14 = [NSString stringWithFormat:@"[RootHelper] Unknown action: %@", action];
            Log(logMessage14);
            return 4;
        }

        return 0;
    }
}
