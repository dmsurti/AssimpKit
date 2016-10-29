//
//  SCNAssimpAnimNode.h
//  AssimpKit
//
//  Created by Deepak Surti on 10/29/16.
//
//

#import <SceneKit/SceneKit.h>

@interface SCNAssimpAnimNode : SCNNode

@property(readwrite, nonatomic) NSValue* boneOffsetMat;
@property(readwrite, nonatomic) NSInteger nPosKeys;
@property(readwrite, nonatomic) NSInteger nRotKeys;
@property(readwrite, nonatomic) NSInteger nScaleKeys;

// An array of NSValue SCNVector3, each is pos key
@property(readwrite, nonatomic) NSArray* posKeys;
// An array of NSNumber float, each is pos key time
@property(readwrite, nonatomic) NSArray* posKeyTimes;
// An array of NSValue SCNVector4, each is rot key, a quaternion
@property(readwrite, nonatomic) NSArray* rotKeys;
// An array of NSNumber float, each is rot key time
@property(readwrite, nonatomic) NSArray* rotKeyTimes;
// An array of NSValue SCNVector3, each is scale key
@property(readwrite, nonatomic) NSArray* scaleKeys;
// An array of NSNumber float, each is scale key time
@property(readwrite, nonatomic) NSArray* scaleKeyTimes;

@end
