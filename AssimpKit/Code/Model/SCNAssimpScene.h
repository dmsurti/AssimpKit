//
//  SCNAssimpScene.h
//  AssimpKit
//
//  Created by Deepak Surti on 10/29/16.
//
//

#import <SceneKit/SceneKit.h>
#import "SCNAssimpAnimNode.h"

@interface SCNAssimpScene : SCNScene

@property(readwrite, nonatomic) SCNNode* skeleton;
@property(readwrite, nonatomic) NSArray* boneNames;
@property(readwrite, nonatomic) NSArray* boneTransforms;

@property(readwrite, nonatomic) SCNAssimpAnimNode* animatedSkeleton;
- (void)addAnimation:(SCNAssimpScene*)animation forKey:(NSString*)animKey;

@end
