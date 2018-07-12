//
//  AssimpImageCache.h
//  AssimpKit-iOS
//
//  Created by The Almighty Dwayne Coussement on 12/07/2018.
//

@import ImageIO;
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssimpImageCache : NSObject

- (nullable CGImageRef)cachedFileAtPath:(NSString *)path;
- (void)storeImage:(CGImageRef)image toPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
