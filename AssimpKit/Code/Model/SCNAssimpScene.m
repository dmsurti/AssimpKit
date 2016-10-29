//
//  SCNAssimpScene.m
//  AssimpKit
//
//  Created by Deepak Surti on 10/29/16.
//
//

#import "SCNAssimpScene.h"

@interface SCNAssimpScene ()

@property(readwrite, nonatomic) NSMutableDictionary* animations;

@end

@implementation SCNAssimpScene

- (void)storeAnimation:(SCNAssimpScene*)animation forKey:(NSString*)animKey {
  if (self.animations == nil) {
    self.animations = [[NSMutableDictionary alloc] init];
  }
  [self.animations setValue:animation forKey:animKey];
}

@end
