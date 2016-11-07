//
//  SCNAssimpScene.m
//  AssimpKit
//
//  Created by Deepak Surti on 11/7/16.
//
//

#import "SCNAssimpScene.h"

@interface SCNAssimpScene ()

@property(readwrite, nonatomic) NSMutableDictionary* animations;

@end

@implementation SCNAssimpScene

-(id)init {
  self = [super init];
  if (self) {
    self.animations = [[NSMutableDictionary alloc] init];
  }
  return self;
}

-(void)addAnimation:(SCNAssimpAnimation*)assimpAnimation {
  NSDictionary* frameAnims = assimpAnimation.frameAnims;
  for (NSString* nodeName in frameAnims.allKeys) {
    SCNNode* boneNode = [self.rootNode childNodeWithName:nodeName recursively:YES];
    NSDictionary* channelKeys = [frameAnims valueForKey:nodeName];
    CAKeyframeAnimation* posAnim = [channelKeys valueForKey:@"position"];
    CAKeyframeAnimation* quatAnim = [channelKeys valueForKey:@"orientation"];
    CAKeyframeAnimation* scaleAnim = [channelKeys valueForKey:@"scale"];
    NSLog(@" for node %@ pos anim is %@ quat anim is %@", boneNode, posAnim, quatAnim);
    if (posAnim) {
      [boneNode addAnimation:posAnim forKey:[nodeName stringByAppendingString:@"-pos"]];
    }
    if (quatAnim) {
      [boneNode addAnimation:quatAnim forKey:[nodeName stringByAppendingString:@"-quat"]];
    }
    if (scaleAnim) {
      [boneNode addAnimation:scaleAnim forKey:[nodeName stringByAppendingString:@"-scale"]];
    }
  }
}

-(SCNAssimpAnimation*)animationForKey:(NSString*)key {
  return [self.animations valueForKey:key];
}


@end
