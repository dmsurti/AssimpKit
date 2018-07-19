//
//  AssimpImageCache.h
//  AssimpKit-iOS
//
//  Created by The Almighty Dwayne Coussement on 12/07/2018.
//

@import ImageIO;
#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
@import AppKit;
#define ImageType NSImage
#else
@import UIKit;
#define ImageType UIImage
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AssimpImageCache : NSObject

- (ImageType *)cachedFileAtPath:(NSString *)path;
- (void)storeImage:(ImageType *)image toPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
