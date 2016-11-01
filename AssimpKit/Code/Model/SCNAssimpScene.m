//
//  SCNAssimpScene.m
//  AssimpKit
//
//  Created by Deepak Surti on 10/29/16.
//
//

#import "SCNAssimpScene.h"
#import "SCNSkinnedNode.h"

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

- (void)addAnimationForKey:(NSString*)animKey {
  self.currentAnimation = [self.animations valueForKey:animKey];
  self.boneAnimationMats =
      [[NSMutableArray alloc] initWithCapacity:self.boneNames.count];
  for (int i = 0; i < self.boneNames.count; i++) {
    [self.boneAnimationMats
        addObject:[NSValue valueWithSCNMatrix4:SCNMatrix4Identity]];
  }
}

- (void)applyAnimationAtTime:(NSTimeInterval)animTime {
  NSLog(@"++++++++ APPLYING ANIMATION at time: %f", animTime);
  self.boneAnimationMats = [[NSMutableArray alloc] init];
  for (int i = 0; i < self.boneNames.count; i++) {
    [self.boneAnimationMats
        addObject:[NSValue valueWithSCNMatrix4:SCNMatrix4Identity]];
  }
  [self animateSkeleton:self.currentAnimation.animatedSkeleton
          withParentMat:SCNMatrix4Identity
                 atTime:animTime];
  [self updateSkinnedNodesGeometry];
}

- (void)printSCNMatrix4:(SCNMatrix4)m {
  NSLog(@" %f %f %f %f", m.m11, m.m21, m.m31, m.m41);
  NSLog(@" %f %f %f %f", m.m12, m.m22, m.m32, m.m42);
  NSLog(@" %f %f %f %f", m.m13, m.m23, m.m33, m.m43);
  NSLog(@" %f %f %f %f", m.m14, m.m24, m.m34, m.m44);
}

- (void)printGLKMatrix4:(GLKMatrix4)m {
  NSLog(@" %f %f %f %f", m.m00, m.m10, m.m20, m.m30);
  NSLog(@" %f %f %f %f", m.m01, m.m11, m.m21, m.m31);
  NSLog(@" %f %f %f %f", m.m02, m.m12, m.m22, m.m32);
  NSLog(@" %f %f %f %f", m.m03, m.m13, m.m23, m.m33);
}

- (void)animateSkeleton:(SCNAssimpAnimNode*)animNode
          withParentMat:(SCNMatrix4)parentMat
                 atTime:(NSTimeInterval)animTime {
  assert(animNode);
  NSLog(@"### Calculating anim mat for bone %@ pos keys %lu rot keys %lu scale "
        @"keys %lu  at time: %f",
        animNode.name, animNode.nPosKeys, animNode.nRotKeys, animNode.nRotKeys,
        animTime);

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
    NSLog(@" Calculate translation matrix");
    int prevKey = 0;
    int nextKey = 0;
    for (int i = 0; i < animNode.nPosKeys - 1; i++) {
      prevKey = i;
      nextKey = i + 1;
      double nextKeyTime =
          [[animNode.posKeyTimes objectAtIndex:nextKey] doubleValue];
      if (nextKeyTime >= animTime) {
        NSLog(@" T: Next key time %f > animTime", nextKeyTime);
        break;
      }
    }
    if (prevKey != nextKey) {
      float nextTime =
          [[animNode.posKeyTimes objectAtIndex:nextKey] doubleValue];
      float prevTime =
          [[animNode.posKeyTimes objectAtIndex:prevKey] doubleValue];
      NSLog(@"   next key: %d prev key: %d", nextKey, prevKey);
      NSLog(@"   next time: %f prev time: %f", nextTime, prevTime);
      NSTimeInterval totalTime = nextTime - prevTime;
      NSTimeInterval delta = (animTime - prevTime) / totalTime;
      // assert(delta <= 1.0);
      NSLog(@"   total time: %f delta: %f", totalTime, delta);
      GLKVector3 posi = SCNVector3ToGLKVector3(
          [[animNode.posKeys objectAtIndex:prevKey] SCNVector3Value]);
      NSLog(@" pos i: %f %f %f", posi.x, posi.y, posi.z);
      GLKVector3 posn = SCNVector3ToGLKVector3(
          [[animNode.posKeys objectAtIndex:nextKey] SCNVector3Value]);
      NSLog(@" pos n: %f %f %f", posi.x, posi.y, posi.z);
      SCNVector3 lerped = SCNVector3FromGLKVector3(
          GLKVector3Add(GLKVector3MultiplyScalar(posi, (1.0 - delta)),
                        GLKVector3MultiplyScalar(posn, delta)));
      NSLog(@"   lerped T: %f %f %f", lerped.x, lerped.y, lerped.z);
      nodeT = SCNMatrix4MakeTranslation(lerped.x, lerped.y, lerped.z);
      NSLog(@" node T:");
      // [self printSCNMatrix4:nodeT];
    }
  }

  SCNMatrix4 nodeR = SCNMatrix4Identity;
  if (animNode.nRotKeys > 0) {
    NSLog(@" Calculate rotation matrix");
    int prevKey = 0;
    int nextKey = 0;
    for (int i = 0; i < animNode.nRotKeys - 1; i++) {
      prevKey = i;
      nextKey = i + 1;
      double nextKeyTime =
          [[animNode.rotKeyTimes objectAtIndex:nextKey] doubleValue];
      if (nextKeyTime >= animTime) {
        NSLog(@" R: Next key time %f > animTime", nextKeyTime);
        break;
      }
    }
    if (nextKey != prevKey) {
      float nextTime =
          [[animNode.rotKeyTimes objectAtIndex:nextKey] doubleValue];
      float prevTime =
          [[animNode.rotKeyTimes objectAtIndex:prevKey] doubleValue];
      float totalTime = nextTime - prevTime;
      float delta = (animTime - prevTime) / totalTime;
      SCNVector4 q1 =
          [[animNode.rotKeys objectAtIndex:prevKey] SCNVector4Value];
      GLKQuaternion qi = GLKQuaternionMake(q1.x, q1.y, q1.z, q1.w);
      SCNVector4 q2 =
          [[animNode.rotKeys objectAtIndex:nextKey] SCNVector4Value];
      GLKQuaternion qn = GLKQuaternionMake(q2.x, q2.y, q2.z, q2.w);
      GLKQuaternion slerped = GLKQuaternionSlerp(qi, qn, delta);
      nodeR = SCNMatrix4FromGLKMatrix4(GLKMatrix4MakeWithQuaternion(slerped));
      NSLog(@" node R:");
      // [self printSCNMatrix4:nodeR];
    }
  }

  SCNMatrix4 nodeS = SCNMatrix4Identity;
  if (animNode.nScaleKeys > 0) {
    NSLog(@" Calculate scale matrix");
    int prevKey = 0;
    int nextKey = 0;
    for (int i = 0; i < animNode.nScaleKeys - 1; i++) {
      prevKey = i;
      nextKey = i + 1;
      double nextKeyTime =
          [[animNode.scaleKeyTimes objectAtIndex:nextKey] doubleValue];
      if (nextKeyTime >= animTime) {
        NSLog(@" S: Next key time %f > animTime", nextKeyTime);
        break;
      }
    }
    if (nextKey != prevKey) {
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
      NSLog(@" node S:");
      // [self printSCNMatrix4:nodeS];
    }
  }

  localAnim = SCNMatrix4Mult(nodeT, nodeR);
  NSLog(@" local anim mat");
  // [self printSCNMatrix4:localAnim];
  SCNMatrix4 boneOffsetMat = [animNode.boneOffsetMat SCNMatrix4Value];
  NSLog(@" bone offset mat");
  // [self printSCNMatrix4:boneOffsetMat];
  ourMat = SCNMatrix4Mult(parentMat, localAnim);
  NSLog(@" our mat");
  // [self printSCNMatrix4:ourMat];
  SCNMatrix4 boneAnimMat =
      SCNMatrix4Mult(parentMat, SCNMatrix4Mult(localAnim, boneOffsetMat));
  NSLog(@" bone anim mat");
  // [self printSCNMatrix4:boneAnimMat];

  if ([self.boneNames containsObject:animNode.name]) {
    NSUInteger boneIndex = [self.boneNames indexOfObject:animNode.name];
    NSLog(@" Setting bone anim mat for bone: %@ at index: %lu", animNode.name,
          boneIndex);
    [self.boneAnimationMats
        replaceObjectAtIndex:boneIndex
                  withObject:[NSValue valueWithSCNMatrix4:boneAnimMat]];
  }

  for (SCNAssimpAnimNode* childNode in animNode.childNodes) {
    [self animateSkeleton:childNode withParentMat:ourMat atTime:animTime];
  }
}

- (NSArray*)getBoneAnimationMatrices {
  return self.boneAnimationMats;
}

- (void)updateSkinnedNodesGeometry {
  for (SCNSkinnedNode* skinnedNode in self.skinnedNodes.allValues) {
    NSLog(@" Calculating animated geometry for skinned node: %@ %lu %lu",
          skinnedNode.name, skinnedNode.nVertices, skinnedNode.maxWeights);
    NSString* nodeName = skinnedNode.name;
    SCNNode* sceneNode =
        [self.rootNode childNodeWithName:nodeName recursively:YES];
    NSLog(@" $$$$$ SCENE NODE is %@", sceneNode);
    NSArray* sources = sceneNode.geometry.geometrySources;
    NSArray* elements = sceneNode.geometry.geometryElements;

    // ---------------------------
    // Calcuate animated vnertices
    // ---------------------------
    float scnVertices[skinnedNode.nVertices * 3];
    int verticesCounter = 0;
    for (NSInteger i = 0; i < skinnedNode.nVertices; i++) {
      NSInteger k = i * skinnedNode.maxWeights;
      GLKVector3 v = SCNVector3ToGLKVector3(
          [[skinnedNode.vertices objectAtIndex:i] SCNVector3Value]);
      // NSLog(@"  animate v: %f %f %f", v.x, v.y, v.z);
      GLKVector4 gv = GLKVector4Make(v.x, v.y, v.z, 1.0);
      GLKVector4 animV = GLKVector4Make(0, 0, 0, 0);
      for (NSInteger j = 0; j < skinnedNode.maxWeights; j++) {
        NSInteger boneIndex =
            [[skinnedNode.boneIndices objectAtIndex:k + j] integerValue];
        float boneWeight =
            [[skinnedNode.boneWeights objectAtIndex:k + j] floatValue];
        // NSString* boneName = [self.boneNames objectAtIndex:boneIndex];
        //        NSLog(@"  bone: index %lu weight: %f at (k + j) %lu for %@",
        //        boneIndex,
        //              boneWeight, (k + j), boneName);
        if (boneWeight > 0) {
          SCNMatrix4 scnBoneMat = [
              [self.boneAnimationMats objectAtIndex:boneIndex] SCNMatrix4Value];
          // [self printSCNMatrix4:scnBoneMat];
          GLKMatrix4 boneMat = SCNMatrix4ToGLKMatrix4(scnBoneMat);
          // [self printSCNMatrix4:scnBoneMat];
          GLKVector4 boneAnimV = GLKMatrix4MultiplyVector4(
              boneMat, GLKVector4MultiplyScalar(gv, boneWeight));
          // NSLog(@"  bone animV: %f %f %f", boneAnimV.x, boneAnimV.y,
          // boneAnimV.z);
          animV = GLKVector4Add(animV, boneAnimV);
          // NSLog(@"  animV: %f %f %f %f", animV.x, animV.y, animV.z, animV.w);
        }
      }
      scnVertices[verticesCounter++] = animV.x / animV.w;
      scnVertices[verticesCounter++] = animV.y / animV.w;
      scnVertices[verticesCounter++] = animV.z / animV.w;
    }

    NSLog(@" Skinned vertices %d", verticesCounter);
    assert(verticesCounter == skinnedNode.nVertices * 3);
    SCNGeometrySource* newVertexSource = [SCNGeometrySource
        geometrySourceWithData:[NSData dataWithBytes:scnVertices
                                              length:skinnedNode.nVertices * 3 *
                                                     sizeof(float)]
                      semantic:SCNGeometrySourceSemanticVertex
                   vectorCount:skinnedNode.nVertices
               floatComponents:YES
           componentsPerVector:3
             bytesPerComponent:sizeof(float)
                    dataOffset:0
                    dataStride:3 * sizeof(float)];

    // ----------------
    // Recreate normals
    // ----------------
    SCNGeometrySource* normals = [sources objectAtIndex:1];
    float* values = (float*)[normals.data bytes];
    float scnNormals[skinnedNode.nVertices * 3];
    verticesCounter = 0;
    for (NSInteger i = 0; i < skinnedNode.nVertices * 3; i++) {
      scnNormals[verticesCounter++] = values[i];
    }
    SCNGeometrySource* newNormalSource = [SCNGeometrySource
        geometrySourceWithData:[NSData dataWithBytes:scnNormals
                                              length:skinnedNode.nVertices * 3 *
                                                     sizeof(float)]
                      semantic:SCNGeometrySourceSemanticNormal
                   vectorCount:skinnedNode.nVertices
               floatComponents:YES
           componentsPerVector:3
             bytesPerComponent:sizeof(float)
                    dataOffset:0
                    dataStride:3 * sizeof(float)];
    NSLog(@" Skinned normals %d", verticesCounter);
    assert(verticesCounter == skinnedNode.nVertices * 3);

    // ------------------
    // Recreate texcoords
    // ------------------
    SCNGeometrySource* texcoords = [sources objectAtIndex:2];
    float* texValues = (float*)[texcoords.data bytes];
    float scnTextures[skinnedNode.nVertices * 2];
    verticesCounter = 0;
    for (int i = 0; i < skinnedNode.nVertices * 2; i++) {
      scnTextures[verticesCounter++] = texValues[i];
    }
    SCNGeometrySource* newTextureSource = [SCNGeometrySource
        geometrySourceWithData:[NSData dataWithBytes:scnTextures
                                              length:skinnedNode.nVertices * 2 *
                                                     sizeof(float)]
                      semantic:SCNGeometrySourceSemanticTexcoord
                   vectorCount:skinnedNode.nVertices
               floatComponents:YES
           componentsPerVector:2
             bytesPerComponent:sizeof(float)
                    dataOffset:0
                    dataStride:2 * sizeof(float)];
    NSLog(@" Skinned texcoords %d", verticesCounter);
    assert(verticesCounter == skinnedNode.nVertices * 2);

    // -----------------
    // Recreate elements
    // -----------------
    NSMutableArray* newElements = [[NSMutableArray alloc] init];
    NSInteger allIndicesCounter = 0;
    for (int i = 0; i < elements.count; i++) {
      SCNGeometryElement* elt = [elements objectAtIndex:i];
      int indicesCounter = 0;
      NSInteger nIndices = elt.data.length / elt.bytesPerIndex;
      short* idxValues = (short*)[elt.data bytes];
      short scnIndices[nIndices];
      for (int j = 0; j < nIndices; j++) {
        scnIndices[indicesCounter++] = idxValues[j];
      }
      NSData* indicesData =
          [NSData dataWithBytes:scnIndices length:sizeof(scnIndices)];
      SCNGeometryElement* indices = [SCNGeometryElement
          geometryElementWithData:indicesData
                    primitiveType:SCNGeometryPrimitiveTypeTriangles
                   primitiveCount:elt.primitiveCount
                    bytesPerIndex:sizeof(short)];
      [newElements addObject:indices];
      allIndicesCounter += indicesCounter;
    }
    NSLog(@" Skinned indices %lu", allIndicesCounter);
    assert(allIndicesCounter == skinnedNode.nIndices);

    // -----------------------------------
    // Now make new vertex geometry source
    // -----------------------------------
    NSArray* materials = sceneNode.geometry.materials;
    NSMutableArray* newSources = [[NSMutableArray alloc] init];

    [newSources addObject:newVertexSource];
    //    [newSources addObject:newNormalSource];
    //    [newSources addObject:newTextureSource];
    for (int i = 1; i < sources.count; i++) {
      [newSources addObject:[sources objectAtIndex:i]];
    }
    SCNGeometry* animGeometry =
        [SCNGeometry geometryWithSources:newSources elements:elements];
    animGeometry.materials = materials;
    sceneNode.geometry = animGeometry;
  }
}

@end
