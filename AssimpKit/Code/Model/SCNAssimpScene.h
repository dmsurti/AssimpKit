//
//  SCNAssimpScene.h
//  AssimpKit
//
//  Created by Deepak Surti on 11/7/16.
//
//

#import <SceneKit/SceneKit.h>
#import "SCNAssimpAnimation.h"

@interface SCNAssimpScene : SCNScene

@property(readonly, nonatomic) NSMutableDictionary* animations;

-(void)addAnimation:(SCNAssimpAnimation*)assimpAnimation;
-(SCNAssimpAnimation*)animationForKey:(NSString*)key;

@end
