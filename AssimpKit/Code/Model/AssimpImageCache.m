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

- (ImageType *)cachedFileAtPath:(NSString *)path
{
	return self.cacheDictionary[path];
}

- (void)storeImage:(ImageType *)image toPath:(NSString *)path
{
	[self.cacheDictionary setObject:image forKey:path];
}

@end
