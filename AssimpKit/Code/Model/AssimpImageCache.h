//
//  AssimpImageCache.h
//  AssimpKit-iOS
//
//  Created by The Almighty Dwayne Coussement on 12/07/2018.
//

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssimpImageCache : NSObject

- (CGImageRef)cachedFileAtPath:(NSString *)path;
- (void)storeImage:(CGImageRef)image toPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
