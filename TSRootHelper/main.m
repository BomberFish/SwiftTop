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
        [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/testrebuild" withIntermediateDirectories:true attributes:nil error:nil];

		// loadMCMFramework();
        NSString* action = [NSString stringWithUTF8String:argv[1]];
        NSString* source = [NSString stringWithUTF8String:argv[2]];
        NSString* destination = [NSString stringWithUTF8String:argv[3]];
		pid_t pid = atoi(argv[2]);
		int sig = atoi(argv[3]);
//        NSString* bundle = [NSString stringWithUTF8String:argv[4]];


        if ([action isEqual: @"write"]) {
            RLog(@"[RootHelper] Writing %@ to %@", source, destination);
            RLog(@"[RootHelper] Writing %@ to %@", source, destination);
			[source writeToFile:destination atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else if ([action isEqual: @"mv"]) {
            NSLog(@"[RootHelper] Moving %@ to %@", source, destination);
            RLog(@"[RootHelper] Moving %@ to %@", source, destination);
            [[NSFileManager defaultManager] moveItemAtPath:source toPath:destination error:nil];
        } else if ([action isEqual: @"cp"]) {
            RLog(@"[RootHelper] Copying %@ to %@", source, destination);
            [[NSFileManager defaultManager] copyItemAtPath:source toPath:destination error:nil];
        } else if ([action isEqual: @"mkdir"]) {
            NSLog(@"[RootHelper] Making directory %@", source);
            RLog(@"[RootHelper] Making directory %@", source);
            [[NSFileManager defaultManager] createDirectoryAtPath:source withIntermediateDirectories:true attributes:nil error:nil];
        } else if ([action isEqual: @"rm"]) {
            NSLog(@"[RootHelper] Removing %@", source);
            RLog(@"[RootHelper] Removing %@", source);
            [[NSFileManager defaultManager] removeItemAtPath:source error:nil];
        } else if ([action isEqual: @"chmod"]) {
            NSLog(@"[RootHelper] Changing perms of %@", source);
            RLog(@"[RootHelper] Changing perms of %@", source);
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:[NSNumber numberWithInt:511]  forKey:NSFilePosixPermissions];
            [[NSFileManager defaultManager] setAttributes:dict ofItemAtPath:source error:nil];
        } else if ([action isEqual: @"rebuildiconcache"]) {
            NSLog(@"[RootHelper] Rebuilding iconcache");
            RLog(@"[RootHelper] Rebuilding iconcache");
            cleanRestrictions();
            [[LSApplicationWorkspace defaultWorkspace] _LSPrivateRebuildApplicationDatabasesForSystemApps:YES internal:YES user:YES];
            refreshAppRegistrations();
            killall(@"backboardd", true);
        } else if ([action isEqual: @"refregapp"]) {
//            refreshAppRegistration(bundle);
        } else if ([action isEqual: @"ln"]) {
            NSLog(@"[RootHelper] Linking %@ to %@", source, destination);
            RLog(@"[RootHelper] Linking %@ to %@", source, destination);
            [[NSFileManager defaultManager] createSymbolicLinkAtPath:destination withDestinationPath:source error:nil];
        } else if ([action isEqual: @"pidkill"]) {
			if (argc == 3) {
				int ret = kill(pid, sig);
                NSLog(@"[RootHelper] Killing pid %d returned code %d", pid, ret);
                RLog(@"[RootHelper] Killing pid %d returned code %d", pid, ret);
				if (ret != 0) {
					return 6;
				}
                return ret;
			} else if (argc == 2) {
				int ret = kill(pid, SIGKILL);
                NSLog(@"[RootHelper] Killing pid %d returned code %d", pid, ret);
                RLog(@"[RootHelper] Killing pid %d returned code %d", pid, ret);
				if (ret != 0) {
					return 6;
				}
                return ret;
			} else {
				NSLog(@"[RootHelper] Invalid number of arguments: %d", argc);
                RLog(@"[RootHelper] Invalid number of arguments: %d", argc);
				return 4;
			}
        } else if ([action isEqual: @"pkill"]) {
            if (argc < 2) {
                NSLog(@"[RootHelper] Invalid number of arguments: %d", argc);
                RLog(@"[RootHelper] Invalid number of arguments: %d", argc);
                return 4;
            } else {
                killall(source, true);
            }
        }else {
			NSLog(@"[RootHelper] Unknown action: %@", action);
            RLog(@"[RootHelper] Unknown action: %@", action);
			return 4;
		}

        return 0;
    }
}
