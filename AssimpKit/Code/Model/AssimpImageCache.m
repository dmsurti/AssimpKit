//
//  AssimpImageCache.m
//  AssimpKit-iOS
//
//  Created by The Almighty Dwayne Coussement on 12/07/2018.
//

#import "AssimpImageCache.h"

@interface AssimpImageCache()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *cacheDictionary;
@end

@implementation AssimpImageCache

- (instancetype)init
{
	if (self = [super init])
	{
		self.cacheDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
	}
	return self;
}

- (void)dealloc
{
    self.cacheDictionary = nil;    
}

- (CGImageRef)cachedFileAtPath:(NSString *)path
{
    return (__bridge CGImageRef _Nonnull)(self.cacheDictionary[path]);
}

- (void)storeImage:(CGImageRef)image toPath:(NSString *)path
{
    if (image == NULL) {
        [self.cacheDictionary removeObjectForKey:path];
    } else {
        [self.cacheDictionary setObject:(__bridge id _Nonnull)(image) forKey:path];
    }
}

@end
