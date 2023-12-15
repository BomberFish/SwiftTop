// bomberfish
// LSApplicationProxy+AltList.h – SwiftTop
// created on 2023-12-15

#ifndef LSApplicationProxy_AltList_h
#define LSApplicationProxy_AltList_h

#import "CoreServices.h"

@interface LSApplicationRecord : NSObject
@property (nonatomic,readonly) NSArray* appTags; // 'hidden'
@property (getter=isLaunchProhibited,readonly) BOOL launchProhibited;
@end

@interface LSApplicationProxy (Additions)
@property (readonly, nonatomic) NSString *shortVersionString;
@property (nonatomic,readonly) NSString* localizedName;
@property (nonatomic,readonly) NSString* applicationType; // (User/System)
@property (nonatomic,readonly) NSArray* appTags; // 'hidden'
@property (getter=isLaunchProhibited,nonatomic,readonly) BOOL launchProhibited;
+ (instancetype)applicationProxyForIdentifier:(NSString*)identifier;
- (LSApplicationRecord*)correspondingApplicationRecord;
@end

@interface LSApplicationWorkspace (Additions)
- (void)addObserver:(id)arg1;
- (void)removeObserver:(id)arg1;
- (void)enumerateApplicationsOfType:(NSUInteger)type block:(void (^)(LSApplicationProxy*))block;
@end

@interface LSApplicationProxy (AltList)
- (BOOL)atl_isSystemApplication;
- (BOOL)atl_isUserApplication;
- (BOOL)atl_isHidden;
- (NSString*)atl_fastDisplayName;
- (NSString*)atl_nameToDisplay;
- (NSString*)atl_shortVersionString;
@property (nonatomic,readonly) NSString* atl_bundleIdentifier;
@end

@interface LSApplicationWorkspace (AltList)
- (NSArray*)atl_allInstalledApplications;
@end

#endif /* LSApplicationProxy_AltList_h */
