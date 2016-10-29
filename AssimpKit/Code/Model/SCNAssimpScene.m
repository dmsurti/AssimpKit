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
@property(readwrite, nonatomic) SCNAssimpScene* currentAnimation;
@property(readwrite, nonatomic) NSMutableArray* boneAnimationMats;

@end

@implementation SCNAssimpScene

- (void)storeAnimation:(SCNAssimpScene*)animation forKey:(NSString*)animKey {
  if (self.animations == nil) {
    self.animations = [[NSMutableDictionary alloc] init];
  }
  [self.animations setValue:animation forKey:animKey];
}

- (NSArray*)animationKeys {
  return self.animations.allKeys;
}

- (void)addAnimation:(SCNAssimpScene*)animation forKey:(NSString*)animKey {
  self.currentAnimation = [self.animations valueForKey:animKey];
  self.boneAnimationMats = [[NSMutableArray alloc] init];
}

- (void)applyAnimationAtTime:(double)animTime {
  [self animateSkeleton:self.currentAnimation.animatedSkeleton
          withParentMat:SCNMatrix4Identity
                 atTime:animTime];
}

- (void)animateSkeleton:(SCNAssimpAnimNode*)animNode
          withParentMat:(SCNMatrix4)parentMat
                 atTime:(double)animTime {
  assert(animNode);

  // ----------------------------
  // inherit the parent animation
  // ----------------------------
  SCNMatrix4 ourMat = parentMat;

  // --------------------------------------
  // a specific bone animation at this time
  // --------------------------------------
  SCNMatrix4 localAnim = SCNMatrix4Identity;

  SCNMatrix4 nodeT = SCNMatrix4Identity;

  if (animNode.nPosKeys > 0) {
    int prevKey = 0;
    int nextKey = 0;
    for (int i = 0; i < animNode.nPosKeys; i++) {
      prevKey = i;
      nextKey = i + 1;
      if ([animNode getPosKeyTimeAtPosKeyIndex:nextKey] >= animTime) {
        break;
      }
    }
    float nextTime = [[animNode.posKeyTimes objectAtIndex:nextKey] doubleValue];
    float prevTime = [[animNode.posKeyTimes objectAtIndex:prevKey] doubleValue];
    float totalTime = nextTime - prevTime;
    float delta =
        (animTime - [animNode getPosKeyTimeAtPosKeyIndex:prevKey]) / totalTime;
    GLKVector3 posi = SCNVector3ToGLKVector3(
        [[animNode.posKeys objectAtIndex:prevKey] SCNVector3Value]);
    GLKVector3 posn = SCNVector3ToGLKVector3(
        [[animNode.posKeys objectAtIndex:nextKey] SCNVector3Value]);
    SCNVector3 lerped = SCNVector3FromGLKVector3(
        GLKVector3Add(GLKVector3MultiplyScalar(posi, (1.0 - delta)),
                      GLKVector3MultiplyScalar(posn, delta)));
    nodeT = SCNMatrix4MakeTranslation(lerped.x, lerped.y, lerped.z);
  }
}

@end
