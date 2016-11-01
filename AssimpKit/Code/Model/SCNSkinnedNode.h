//
//  SCNSkinnedNode.h
//  AssimpKit
//
//  Created by Deepak Surti on 10/29/16.
//
//

#import <SceneKit/SceneKit.h>

@interface SCNSkinnedNode : SCNNode

@property(strong, nonatomic) NSArray* vertices;
@property(strong, nonatomic) NSArray* boneWeights;
@property(strong, nonatomic) NSArray* boneIndices;
@property NSInteger maxWeights;
@property NSInteger nVertices;
@property NSInteger nIndices;

@end
