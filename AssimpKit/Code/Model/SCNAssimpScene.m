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
      double nextKeyTime =
          [[animNode.posKeyTimes objectAtIndex:nextKey] doubleValue];
      if (nextKeyTime >= animTime) {
        break;
      }
    }
    float nextTime = [[animNode.posKeyTimes objectAtIndex:nextKey] doubleValue];
    float prevTime = [[animNode.posKeyTimes objectAtIndex:prevKey] doubleValue];
    float totalTime = nextTime - prevTime;
    float delta = (animTime - prevTime) / totalTime;
    GLKVector3 posi = SCNVector3ToGLKVector3(
        [[animNode.posKeys objectAtIndex:prevKey] SCNVector3Value]);
    GLKVector3 posn = SCNVector3ToGLKVector3(
        [[animNode.posKeys objectAtIndex:nextKey] SCNVector3Value]);
    SCNVector3 lerped = SCNVector3FromGLKVector3(
        GLKVector3Add(GLKVector3MultiplyScalar(posi, (1.0 - delta)),
                      GLKVector3MultiplyScalar(posn, delta)));
    nodeT = SCNMatrix4MakeTranslation(lerped.x, lerped.y, lerped.z);
  }

  SCNMatrix4 nodeR = SCNMatrix4Identity;
  if (animNode.nRotKeys > 0) {
    int prevKey = 0;
    int nextKey = 0;
    for (int i = 0; i < animNode.nRotKeys; i++) {
      prevKey = i;
      nextKey = i + 1;
      double nextKeyTime =
          [[animNode.rotKeyTimes objectAtIndex:nextKey] doubleValue];
      if (nextKeyTime >= animTime) {
        break;
      }
    }
    float nextTime = [[animNode.rotKeyTimes objectAtIndex:nextKey] doubleValue];
    float prevTime = [[animNode.rotKeyTimes objectAtIndex:prevKey] doubleValue];
    float totalTime = nextTime - prevTime;
    float delta = (animTime - prevTime) / totalTime;
    SCNVector4 q1 = [[animNode.rotKeys objectAtIndex:prevKey] SCNVector4Value];
    GLKQuaternion qi = GLKQuaternionMake(q1.x, q1.y, q1.z, q1.w);
    SCNVector4 q2 = [[animNode.rotKeys objectAtIndex:nextKey] SCNVector4Value];
    GLKQuaternion qn = GLKQuaternionMake(q2.x, q2.y, q2.z, q2.w);
    GLKQuaternion slerped = GLKQuaternionSlerp(qi, qn, delta);
    SCNVector4 s = SCNVector4Make(slerped.x, slerped.y, slerped.z, slerped.w);
    nodeR = SCNMatrix4MakeRotation(s.w, s.x, s.y, s.z);
  }

  SCNMatrix4 nodeS = SCNMatrix4Identity;
  if (animNode.nScaleKeys > 0) {
    int prevKey = 0;
    int nextKey = 0;
    for (int i = 0; i < animNode.nScaleKeys; i++) {
      prevKey = i;
      nextKey = i + 1;
      double nextKeyTime =
          [[animNode.scaleKeyTimes objectAtIndex:nextKey] doubleValue];
      if (nextKeyTime >= animTime) {
        break;
      }
    }
    float nextTime =
        [[animNode.scaleKeyTimes objectAtIndex:nextKey] doubleValue];
    float prevTime =
        [[animNode.scaleKeyTimes objectAtIndex:prevKey] doubleValue];
    float totalTime = nextTime - prevTime;
    float delta = (animTime - prevTime) / totalTime;
    GLKVector3 posi = SCNVector3ToGLKVector3(
        [[animNode.scaleKeyTimes objectAtIndex:prevKey] SCNVector3Value]);
    GLKVector3 posn = SCNVector3ToGLKVector3(
        [[animNode.scaleKeyTimes objectAtIndex:nextKey] SCNVector3Value]);
    SCNVector3 lerped = SCNVector3FromGLKVector3(
        GLKVector3Add(GLKVector3MultiplyScalar(posi, (1.0 - delta)),
                      GLKVector3MultiplyScalar(posn, delta)));
    nodeS = SCNMatrix4MakeScale(lerped.x, lerped.y, lerped.z);
  }

  localAnim = SCNMatrix4Mult(nodeT, SCNMatrix4Mult(nodeR, nodeS));

  SCNMatrix4 boneOffsetMat = [animNode.boneOffsetMat SCNMatrix4Value];
  ourMat = SCNMatrix4Mult(parentMat, localAnim);
  SCNMatrix4 boneAnimMat =
      SCNMatrix4Mult(parentMat, SCNMatrix4Mult(localAnim, boneOffsetMat));
  NSUInteger boneIndex = [self.boneNames indexOfObject:animNode.name];
  [self.boneAnimationMats
      replaceObjectAtIndex:boneIndex
                withObject:[NSValue valueWithSCNMatrix4:boneAnimMat]];
  for (SCNAssimpAnimNode* childNode in animNode.childNodes) {
    [self animateSkeleton:childNode withParentMat:ourMat atTime:animTime];
  }
}

- (NSArray*)getBoneAnimationMatrices {
  return self.boneAnimationMats;
}

@end
