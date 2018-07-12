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
		self.cacheDictionary = [NSMutableDictionary new];
	}
	return self;
}

- (nullable CGImageRef)cachedFileAtPath:(NSString *)path
{
	id image = self.cacheDictionary[path];
	return (__bridge CGImageRef _Nullable)(image);
}

- (void)storeImage:(CGImageRef)image toPath:(NSString *)path
{
	[self.cacheDictionary setObject:(__bridge id _Nonnull)(image) forKey:path];
}

@end
