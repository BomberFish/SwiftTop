// bomberfish
// UIImage+applicationIconImageForBundleIdentifier.h – TrolleyStore
// created on 2024-01-02

#ifndef UIImage_Private
#define UIImage_Private

#import <UIKit/UIKit.h>
@interface UIImage ()
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)id format:(NSInteger)format scale:(double)scale;
@end


#endif /* UIImage_Private */
