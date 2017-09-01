
/*
 ---------------------------------------------------------------------------
 Assimp to Scene Kit Library (AssimpKit)
 ---------------------------------------------------------------------------
 Copyright (c) 2016, AssimpKit team
 All rights reserved.
 Redistribution and use of this software in source and binary forms,
 with or without modification, are permitted provided that the following
 conditions are met:
 * Redistributions of source code must retain the above
 copyright notice, this list of conditions and the
 following disclaimer.
 * Redistributions in binary form must reproduce the above
 copyright notice, this list of conditions and the
 following disclaimer in the documentation and/or other
 materials provided with the distribution.
 * Neither the name of the AssimpKit team, nor the names of its
 contributors may be used to endorse or promote products
 derived from this software without specific prior
 written permission of the AssimpKit team.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ---------------------------------------------------------------------------
 */

#import <XCTest/XCTest.h>
#import "AssimpImporter.h"
#import "ModelFile.h"
#import "ModelLog.h"
#import "PostProcessingFlags.h"
#import "SCNAssimpAnimation.h"
#import "SCNScene+AssimpImport.h"
#include "assimp/cimport.h"     // Plain-C interface
#include "assimp/light.h"       // Lights
#include "assimp/material.h"    // Materials
#include "assimp/postprocess.h" // Post processing flags
#include "assimp/scene.h"       // Output data structure

/**
 The test class for AssimpImporter.

 This class tests the model files placed in a directory named assets, which
 has subdirectories: apple, of and assimp; which are the owners of the model
 files. (Note: of represents open frameworks).

 Each asset owner subdirectory is further classified into:
 * models - which contain open source model files
 * models-properietary - which contain properietary model files.

 Each model directory categorized by license has a subdirectory for each file
 format that AssimpKit supports.

 The list of file formats that AssimpKit supports is in valid-extensions.txt
 file under assets directory.
 */
@interface AssimpImporterTests : XCTestCase

@property (strong, nonatomic) NSMutableDictionary *modelLogs;
@property (strong, nonatomic) NSString *testAssetsPath;

@end

@implementation AssimpImporterTests

#pragma mark - Set up and tear down

/**
 @name Set up and tear down
 */

/**
 The common initialization for each test method.

 This method initializes the assets path from the TEST_ASSETS_PATH which is
 a processor macro defined in the AssimpSceneKit_LogicTests target defined in
 both OSX-Example and iOS-Example projects.
 */
- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
    self.modelLogs = [[NSMutableDictionary alloc] init];

    self.testAssetsPath = TEST_ASSETS_PATH;
}

/**
 The common clean up for each test method.
 */
- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.
    [super tearDown];
}

#pragma mark - Check node geometry

/**
 @name Check node geometry
 */

/**
 Checks the scenekit node geometry has the correct vertex, normal and texture
 coordinate geometry sources for the specifed assimp node.

 @param aiNode The assimp node.
 @param nodeName The node name.
 @param sceneNode The scenekit node, whose geometry is tested.
 @param aiScene The assimp scene.
 @param testLog The log for the file being tested.
 */
- (void)checkNodeGeometry:(const struct aiNode *)aiNode
                 nodeName:(NSString *)nodeName
            withSceneNode:(SCNNode *)sceneNode
                  aiScene:(const struct aiScene *)aiScene
                  testLog:(ModelLog *)testLog
{
    int nVertices = 0;
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        nVertices += aiMesh->mNumVertices;
    }
    XCTAssertEqual(sceneNode.geometry.geometrySources.count, 4,
                   @" Expected 4 geometry sources but got %lu",
                   sceneNode.geometry.geometrySources.count);
    SCNGeometrySource *vertexSource =
        [sceneNode.geometry.geometrySources objectAtIndex:0];
    if (nVertices != vertexSource.vectorCount)
    {
        NSString *errorLog = [NSString
            stringWithFormat:
                @"Scene node %@ geometry does not have expected %d vertices",
                nodeName, nVertices];

        [testLog addErrorLog:errorLog];
    }
    XCTAssertEqual(vertexSource.dataStride, 12,
                   @" The vertex source data stride is %ld instead of 12",
                   (long)vertexSource.dataStride);
    SCNGeometrySource *normalSource =
        [sceneNode.geometry.geometrySources objectAtIndex:1];
    if (nVertices != normalSource.vectorCount)
    {
        NSString *errorLog = [NSString
            stringWithFormat:
                @"Scene node %@ geometry does not have expected %d normals",
                nodeName, nVertices];
        [testLog addErrorLog:errorLog];
    }
    XCTAssertEqual(normalSource.dataStride, 12,
                   @" The texture source data stride is %ld instead of 12",
                   (long)normalSource.dataStride);
    SCNGeometrySource *texSource =
    [sceneNode.geometry.geometrySources objectAtIndex:2];
    if (nVertices != texSource.vectorCount)
    {
        {
            NSString *errorLog = [NSString
                                  stringWithFormat:@"Scene node %@ geometry does not have "
                                  @"expected %d tex coords",
                                  nodeName, nVertices];
            [testLog addErrorLog:errorLog];
        }
    }
    XCTAssertEqual(texSource.dataStride, 8,
                   @" The texture source data stride is %ld instead of 8",
                   (long)texSource.dataStride);
    SCNGeometrySource *tangentSource =
    [sceneNode.geometry.geometrySources objectAtIndex:3];
    if (nVertices != tangentSource.vectorCount)
    {
        NSString *errorLog = [NSString
            stringWithFormat:
                @"Scene node %@ geometry does not have expected %d tangents",
                nodeName, nVertices];
        [testLog addErrorLog:errorLog];
    }
    XCTAssertEqual(tangentSource.dataStride, 12,
                   @" The tangent source data stride is %ld instead of 12",
                   (long)tangentSource.dataStride);
}

#pragma mark - Check node materials

/**
 @name Check node materials
 */

/**
 Check the scenekit node's materials from the corrersponding material
 materials of the specified node.

 This checks each material property of the material.

 @param aiNode The assimp node.
 @param nodeName The node name.
 @param sceneNode The scenekit node.
 @param aiScene The assimp scene.
 @param modelPath The path to the file being tested.
 @param testLog The log for the file being tested.
 */
- (void)checkNodeMaterials:(const struct aiNode *)aiNode
                  nodeName:(NSString *)nodeName
             withSceneNode:(SCNNode *)sceneNode
                   aiScene:(const struct aiScene *)aiScene
                 modelPath:(NSString *)modelPath
                   testLog:(ModelLog *)testLog
{
    XCTAssertEqual(sceneNode.geometry.materials.count, aiNode->mNumMeshes,
                   @" Expected %lu materials but only %d were applied",
                   sceneNode.geometry.materials.count, aiNode->mNumMeshes);
}

#pragma mark - Check lights

/**
 @name Check lights
 */

/**
 Checks the lights in the scenekit scene correspond to the lights in the assimp
 scene.

 @param aiScene The assimp. scene.
 @param scene The scenekit scene.
 @param testLog The log for the file being tested.
 */
- (void)checkLights:(const struct aiScene *)aiScene
          withScene:(SCNScene *)scene
            testLog:(ModelLog *)testLog
{
    for (int i = 0; i < aiScene->mNumLights; i++)
    {
        const struct aiLight *aiLight = aiScene->mLights[i];
        const struct aiString aiLightNodeName = aiLight->mName;
        NSString *lightNodeName = [NSString
            stringWithUTF8String:(const char *_Nonnull) & aiLightNodeName.data];
        SCNNode *lightNode =
            [scene.rootNode childNodeWithName:lightNodeName recursively:YES];
        if (lightNode == nil)
        {
            NSString *errorLog =
                [NSString stringWithFormat:@"The light node %@ does not exist",
                                           lightNodeName];
            [testLog addErrorLog:errorLog];
        }
        SCNLight *light = lightNode.light;
        if (light == nil)
        {
            NSString *errorLog = [NSString
                stringWithFormat:@"The light node does not have light"];
            [testLog addErrorLog:errorLog];
        }
        if (aiLight->mType == aiLightSource_DIRECTIONAL)
        {
            if (![light.type isEqualToString:SCNLightTypeDirectional])
            {
                NSString *errorLog = @"The light type is not directional light";
                [testLog addErrorLog:errorLog];
            }
        }
        else if (aiLight->mType == aiLightSource_POINT)
        {
            if (![light.type isEqualToString:SCNLightTypeOmni])
            {
                NSString *errorLog = @"The light type is not point light";
                [testLog addErrorLog:errorLog];
            }
        }
        else if (aiLight->mType == aiLightSource_SPOT)
        {
            if (![light.type isEqualToString:SCNLightTypeSpot])
            {
                NSString *errorLog = @"The light type is not spot light";
                [testLog addErrorLog:errorLog];
            }
        }
    }
}

#pragma mark - Check node

/**
 @name Check node
 */

/**
 Checks the scenekit node corresponds to the assimp node and has the correct
 geometry and materials.

 @param aiNode The assimp node.
 @param sceneNode The scenekit node.
 @param aiScene The scenekit scene.
 @param modelPath The path to the file being tested.
 @param testLog The log for the file being tested.
 */
- (void)checkNode:(const struct aiNode *)aiNode
    withSceneNode:(SCNNode *)sceneNode
          aiScene:(const struct aiScene *)aiScene
        modelPath:(NSString *)modelPath
          testLog:(ModelLog *)testLog
{
    const struct aiString *aiNodeName = &aiNode->mName;
    NSString *nodeName =
        [NSString stringWithUTF8String:(const char *)&aiNodeName->data];
    if (![nodeName isEqualToString:sceneNode.name])
    {
        NSString *errorLog =
            [NSString stringWithFormat:@"aiNode %@ does not match SCNNode %@",
                                       nodeName, sceneNode.name];
        [testLog addErrorLog:errorLog];
    }
    if (aiNode->mNumMeshes > 0)
    {
        [self checkNodeGeometry:aiNode
                       nodeName:nodeName
                  withSceneNode:sceneNode
                        aiScene:aiScene
                        testLog:testLog];
        [self checkNodeMaterials:aiNode
                        nodeName:nodeName
                   withSceneNode:sceneNode
                         aiScene:aiScene
                       modelPath:modelPath
                         testLog:testLog];
    }
    for (int i = 0; i < aiNode->mNumChildren; i++)
    {
        const struct aiNode *aiChildNode = aiNode->mChildren[i];
        SCNNode *sceneChildNode = [sceneNode.childNodes objectAtIndex:i];
        [self checkNode:aiChildNode
            withSceneNode:sceneChildNode
                  aiScene:aiScene
                modelPath:modelPath
                  testLog:testLog];
    }
}

#pragma mark - Check cameras

/**
 @name Check cameras.
 */

/**
 Checks the cameras in the scenekit scene correspond to the cameras in the
 assimp scene.

 @param aiScene The assimp. scene.
 @param scene The scenekit scene.
 @param testLog The log for the file being tested.
 */

- (void)checkCameras:(const struct aiScene *)aiScene
           withScene:(SCNScene *)scene
             testLog:(ModelLog *)testLog
{
    for (int i = 0; i < aiScene->mNumCameras; i++)
    {
        const struct aiCamera *aiCamera = aiScene->mCameras[i];
        const struct aiString aiCameraName = aiCamera->mName;
        NSString *cameraNodeName = [NSString
            stringWithUTF8String:(const char *_Nonnull) & aiCameraName.data];
        SCNNode *cameraNode =
            [scene.rootNode childNodeWithName:cameraNodeName recursively:YES];
        if (cameraNode == nil)
        {
            NSString *errorLog =
                [NSString stringWithFormat:@"The camera node %@ does not exist",
                                           cameraNode];
            [testLog addErrorLog:errorLog];
        }
        SCNCamera *camera = cameraNode.camera;
        if (camera == nil)
        {
            NSString *errorLog = @"The camera node does not have a camera";
            [testLog addErrorLog:errorLog];
        }
    }
}

#pragma mark - Check animations

/**
 @name Check animations
 */

/**
 Checks the animation data for bone positions in scenekit scene contains
 the animation data from the assimp scene for each bone in the animation.

 @param aiNodeAnim The assimp node.
 @param aiAnimation The assimp animation.
 @param channelKeys The bone channels in the assimp animation.
 @param duration The duration of the assimp animation.
 @param testLog The log for the file being tested.
 */
- (void)checkPositionChannels:(const struct aiNodeAnim *)aiNodeAnim
                  aiAnimation:(const struct aiAnimation *)aiAnimation
                  channelKeys:(NSDictionary *)channelKeys
                     duration:(float)duration
                      testLog:(ModelLog *)testLog
{
    if (aiNodeAnim->mNumPositionKeys > 0)
    {
        CAKeyframeAnimation *posAnim = [channelKeys valueForKey:@"position"];
        if (posAnim.keyTimes.count != aiNodeAnim->mNumPositionKeys)
        {
            NSString *errorLog =
                [NSString stringWithFormat:@"The position animation contains "
                                           @"%lu channel key "
                                           @"times "
                                           @"instead of %d key times",
                                           posAnim.keyTimes.count,
                                           aiNodeAnim->mNumPositionKeys];
            [testLog addErrorLog:errorLog];
        }
        if (posAnim.values.count != aiNodeAnim->mNumPositionKeys)
        {
            NSString *errorLog =
                [NSString stringWithFormat:@"The position animation contains "
                                           @"%lu channel key "
                                           @"values "
                                           @"instead of %d key values",
                                           posAnim.values.count,
                                           aiNodeAnim->mNumPositionKeys];
            [testLog addErrorLog:errorLog];
        }
        if (posAnim.speed != 1)
        {
            NSString *errorLog = @"The position animation speed is not 1";
            [testLog addErrorLog:errorLog];
        }
        if (posAnim.duration != duration)
        {
            NSString *errorLog = [NSString
                stringWithFormat:@"The position animation duration is not %f",
                                 duration];
            [testLog addErrorLog:errorLog];
        }
        for (int k = 0; k < aiNodeAnim->mNumPositionKeys; k++)
        {
            const struct aiVectorKey *aiTranslationKey =
                &aiNodeAnim->mPositionKeys[k];
            const struct aiVector3D aiTranslation = aiTranslationKey->mValue;
            SCNVector3 posKey =
                [[posAnim.values objectAtIndex:k] SCNVector3Value];
            if (posKey.x != aiTranslation.x)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has pos.x "
                                     @"value %f instead of %f",
                                     k, posKey.x, aiTranslation.x];
                [testLog addErrorLog:errorLog];
            }
            if (posKey.y != aiTranslation.y)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has pos.y "
                                     @"value %f instead of %f",
                                     k, posKey.y, aiTranslation.y];
                [testLog addErrorLog:errorLog];
            }
            if (posKey.z != aiTranslation.z)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has pos.z "
                                     @"value %f instead of %f",
                                     k, posKey.z, aiTranslation.z];
                [testLog addErrorLog:errorLog];
            }
            NSNumber *keyTime = [posAnim.keyTimes objectAtIndex:k];
            if (keyTime.floatValue != aiTranslationKey->mTime)
            {
                NSString *errorLog =
                    [NSString stringWithFormat:@"The channel num %d key has %f "
                                               @"key time instead "
                                               @"of %f",
                                               k, keyTime.floatValue,
                                               aiTranslationKey->mTime];
                [testLog addErrorLog:errorLog];
            }
        }
    }
}

/**
 Checks the animation data for bone orientations in scenekit scene contains
 the animation data from the assimp scene for each bone in the animation.

 @param aiNodeAnim The assimp node.
 @param aiAnimation The assimp animation.
 @param channelKeys The bone channels in the assimp animation.
 @param duration The duration of the assimp animation.
 @param testLog The log for the file being tested.
 */
- (void)checkRotationChannels:(const struct aiNodeAnim *)aiNodeAnim
                  aiAnimation:(const struct aiAnimation *)aiAnimation
                  channelKeys:(NSDictionary *)channelKeys
                     duration:(float)duration
                      testLog:(ModelLog *)testLog
{
    if (aiNodeAnim->mNumRotationKeys > 0)
    {
        CAKeyframeAnimation *rotationAnim =
            [channelKeys valueForKey:@"orientation"];
        if (rotationAnim.keyTimes.count != aiNodeAnim->mNumRotationKeys)
        {
            NSString *errorLog =
                [NSString stringWithFormat:@"The position animation contains "
                                           @"%lu channel key "
                                           @"times "
                                           @"instead of %d key times",
                                           rotationAnim.keyTimes.count,
                                           aiNodeAnim->mNumRotationKeys];
            [testLog addErrorLog:errorLog];
        }
        if (rotationAnim.values.count != aiNodeAnim->mNumRotationKeys)
        {
            NSString *errorLog =
                [NSString stringWithFormat:@"The position animation contains "
                                           @"%lu channel key "
                                           @"values "
                                           @"instead of %d key values",
                                           rotationAnim.values.count,
                                           aiNodeAnim->mNumRotationKeys];
            [testLog addErrorLog:errorLog];
        }
        if (rotationAnim.speed != 1)
        {
            NSString *errorLog = @"The position animation speed is not 1";
            [testLog addErrorLog:errorLog];
        }
        if (rotationAnim.duration != duration)
        {
            NSString *errorLog = [NSString
                stringWithFormat:@"The position animation duration is not %f",
                                 duration];
            [testLog addErrorLog:errorLog];
        }
        for (int k = 0; k < aiNodeAnim->mNumPositionKeys; k++)
        {
            const struct aiQuatKey *aiQuatKey = &aiNodeAnim->mRotationKeys[k];
            const struct aiQuaternion aiQuaternion = aiQuatKey->mValue;
            SCNVector4 quatKey =
                [[rotationAnim.values objectAtIndex:k] SCNVector4Value];
            if (quatKey.x != aiQuaternion.x)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has quat.x "
                                     @"value %f instead of %f",
                                     k, quatKey.x, aiQuaternion.x];
                [testLog addErrorLog:errorLog];
            }
            if (quatKey.y != aiQuaternion.y)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has quat.y "
                                     @"value %f instead of %f",
                                     k, quatKey.y, aiQuaternion.y];
                [testLog addErrorLog:errorLog];
            }
            if (quatKey.z != aiQuaternion.z)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has quat.z "
                                     @"value %f instead of %f",
                                     k, quatKey.z, aiQuaternion.z];
                [testLog addErrorLog:errorLog];
            }
            if (quatKey.w != aiQuaternion.w)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has quat.w "
                                     @"value %f instead of %f",
                                     k, quatKey.w, aiQuaternion.w];
                [testLog addErrorLog:errorLog];
            }
            NSNumber *keyTime = [rotationAnim.keyTimes objectAtIndex:k];
            if (keyTime.floatValue != aiQuatKey->mTime)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has %f "
                                     @"key time instead "
                                     @"of %f",
                                     k, keyTime.floatValue, aiQuatKey->mTime];
                [testLog addErrorLog:errorLog];
            }
        }
    }
}

/**
 Checks the animation data for bone scales in scenekit scene contains
 the animation data from the assimp scene for each bone in the animation.

 @param aiNodeAnim The assimp node.
 @param aiAnimation The assimp animation.
 @param channelKeys The bone channels in the assimp animation.
 @param duration The duration of the assimp animation.
 @param testLog The log for the file being tested.
 */
- (void)checkScalingChannels:(const struct aiNodeAnim *)aiNodeAnim
                 aiAnimation:(const struct aiAnimation *)aiAnimation
                 channelKeys:(NSDictionary *)channelKeys
                    duration:(float)duration
                     testLog:(ModelLog *)testLog
{
    if (aiNodeAnim->mNumScalingKeys > 0)
    {
        CAKeyframeAnimation *scaleAnim = [channelKeys valueForKey:@"position"];
        if (scaleAnim.keyTimes.count != aiNodeAnim->mNumPositionKeys)
        {
            NSString *errorLog =
                [NSString stringWithFormat:@"The position animation contains "
                                           @"%lu channel key "
                                           @"times "
                                           @"instead of %d key times",
                                           scaleAnim.keyTimes.count,
                                           aiNodeAnim->mNumPositionKeys];
            [testLog addErrorLog:errorLog];
        }
        if (scaleAnim.values.count != aiNodeAnim->mNumPositionKeys)
        {
            NSString *errorLog =
                [NSString stringWithFormat:@"The position animation contains "
                                           @"%lu channel key "
                                           @"values "
                                           @"instead of %d key values",
                                           scaleAnim.values.count,
                                           aiNodeAnim->mNumPositionKeys];
            [testLog addErrorLog:errorLog];
        }
        if (scaleAnim.speed != 1)
        {
            NSString *errorLog = @"The position animation speed is not 1";
            [testLog addErrorLog:errorLog];
        }
        if (scaleAnim.duration != duration)
        {
            NSString *errorLog = [NSString
                stringWithFormat:@"The position animation duration is not %f",
                                 duration];
            [testLog addErrorLog:errorLog];
        }
        for (int k = 0; k < aiNodeAnim->mNumPositionKeys; k++)
        {
            const struct aiVectorKey *aiScaleKey =
                &aiNodeAnim->mPositionKeys[k];
            const struct aiVector3D aiScale = aiScaleKey->mValue;
            SCNVector3 scaleKey =
                [[scaleAnim.values objectAtIndex:k] SCNVector3Value];
            if (scaleKey.x != aiScale.x)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has pos.x "
                                     @"value %f instead of %f",
                                     k, scaleKey.x, aiScale.x];
                [testLog addErrorLog:errorLog];
            }
            if (scaleKey.y != aiScale.y)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has pos.y "
                                     @"value %f instead of %f",
                                     k, scaleKey.y, aiScale.y];
                [testLog addErrorLog:errorLog];
            }
            if (scaleKey.z != aiScale.z)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has pos.z "
                                     @"value %f instead of %f",
                                     k, scaleKey.z, aiScale.z];
                [testLog addErrorLog:errorLog];
            }
            NSNumber *keyTime = [scaleAnim.keyTimes objectAtIndex:k];
            if (keyTime.floatValue != aiScaleKey->mTime)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The channel num %d key has %f "
                                     @"key time instead "
                                     @"of %f",
                                     k, keyTime.floatValue, aiScaleKey->mTime];
                [testLog addErrorLog:errorLog];
            }
        }
    }
}

/**
 Checks the animation data for bones in scenekit scene contains
 the animation data from the assimp scene for each bone in the animation.

 @param aiScene The assimp scene.
 @param scene The scenekit scene.
 @param modelPath The path to the file being tested.
 @param testLog The log for the file being tested.
 */
- (void)checkAnimations:(const struct aiScene *)aiScene
              withScene:(SCNAssimpScene *)scene
              modelPath:(NSString *)modelPath
                testLog:(ModelLog *)testLog
{
    if (aiScene->mNumAnimations > 0)
    {
        for (int i = 0; i < aiScene->mNumAnimations; i++)
        {
            NSInteger actualAnimations = scene.animations.allKeys.count;
            int expectedAnimations = aiScene->mNumAnimations;
            if (actualAnimations != expectedAnimations)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:@"The scene contains %ld animations "
                                     @"instead of expected %d animations",
                                     (long)actualAnimations,
                                     expectedAnimations];
                [testLog addErrorLog:errorLog];
            }
            const struct aiAnimation *aiAnimation = aiScene->mAnimations[i];
            NSString *animKey = [[[modelPath lastPathComponent]
                stringByDeletingPathExtension] stringByAppendingString:@"-1"];
            SCNAssimpAnimation *animation = [scene animationForKey:animKey];
            if (animation == nil)
            {
                NSString *errorLog = [NSString
                    stringWithFormat:
                        @"The scene does not contain animation with key %@",
                        animKey];
                [testLog addErrorLog:errorLog];
            }
            if (![animation.key isEqualToString:animKey])
            {
                NSString *errorLog = [NSString
                    stringWithFormat:
                        @"The animation does not have the correct key %@",
                        animKey];
                [testLog addErrorLog:errorLog];
            }
            for (int j = 0; j < aiAnimation->mNumChannels; j++)
            {
                const struct aiNodeAnim *aiNodeAnim = aiAnimation->mChannels[j];
                const struct aiString *aiNodeName = &aiNodeAnim->mNodeName;
                NSString *name =
                    [NSString stringWithUTF8String:aiNodeName->data];
                NSDictionary *channelKeys =
                    [animation.frameAnims valueForKey:name];
                if (channelKeys == nil)
                {
                    NSString *errorLog = [NSString
                        stringWithFormat:@"The channel keys for bone %@ "
                                         @"channel does not exist",
                                         name];
                    [testLog addErrorLog:errorLog];
                }

                float duration;
                if (aiAnimation->mTicksPerSecond != 0)
                {
                    duration =
                        aiAnimation->mDuration / aiAnimation->mTicksPerSecond;
                }
                else
                {
                    duration = aiAnimation->mDuration;
                }

                [self checkPositionChannels:aiNodeAnim
                                aiAnimation:aiAnimation
                                channelKeys:channelKeys
                                   duration:duration
                                    testLog:testLog];

                [self checkRotationChannels:aiNodeAnim
                                aiAnimation:aiAnimation
                                channelKeys:channelKeys
                                   duration:duration
                                    testLog:testLog];

                [self checkScalingChannels:aiNodeAnim
                               aiAnimation:aiAnimation
                               channelKeys:channelKeys
                                  duration:duration
                                   testLog:testLog];
            }
        }
    }
}

#pragma mark - Check model

/**
 Checks the scene kit scene corresponds to the assimp scene.

 This is the entry point check method for each model file that is tested.

 This verifies that:
 1. The scenekit scene has the same node hierarchy as the assimp scene where
 each node has the correct geometry with geometry sources, elements and
 textures.
 2. The scenekit has the correct lights.
 3. The scenekit scene has the correct cameras.
 4. If the scenekit scene has animations, it checks that the key frames created
 for the animation data are correct for values, timing, duration and the bone
 channel to which the key frame belongs.

 @param path The path to the model file being tested.
 @param testLog The log for the file being tested.
 */
- (void)checkModel:(NSString *)path testLog:(ModelLog *)testLog
{
    const char *pFile = [path UTF8String];
    const struct aiScene *aiScene = aiImportFile(pFile, aiProcess_FlipUVs);
    // If the import failed, report it
    if (!aiScene)
    {
        NSString *errorString =
            [NSString stringWithUTF8String:aiGetErrorString()];
        [testLog addErrorLog:errorString];
        return;
    }

    AssimpImporter *importer = [[AssimpImporter alloc] init];
    SCNAssimpScene *scene =
        [importer importScene:path
             postProcessFlags:AssimpKit_Process_FlipUVs |
                              AssimpKit_Process_Triangulate];

    NSLog(@"   SCENE Root node: %@ with children: %lu", scene.rootNode,
          (unsigned long)scene.rootNode.childNodes.count);
    [self checkNode:aiScene->mRootNode
        withSceneNode:[scene.modelScene.rootNode.childNodes objectAtIndex:0]
              aiScene:aiScene
            modelPath:path
              testLog:testLog];

    // [self checkLights:aiScene withScene:scene.modelScene testLog:testLog];

    [self checkCameras:aiScene withScene:scene.modelScene testLog:testLog];

    [self checkAnimations:aiScene
                withScene:scene
                modelPath:path
                  testLog:testLog];
}

#pragma mark - Test all models

/**
 @name Test all models
 */

/**
 Creates an array of the model files that can be tested.

 This filters the assets directory for the file formats that are supported
 by AssimpKit.

 The list of valid file formats is stored in assets/valid-extensions.txt.

 See: The test class description for more details about the assets directory.

 @return The array of model files that can be tested.
 */
- (NSArray *)getModelFiles
{
    // -------------------------------------------------------------
    // All asset directories by owner: Apple, OpenFrameworks, Assimp
    // -------------------------------------------------------------
    NSString *appleAssets = @"apple/";
    NSString *ofAssets = @"of/";
    NSString *assimpAssets = @"assimp/";
    // issues subdir contains all models submitted by users for bugs/features
    NSString *issuesAssets = @"issues/";
    NSArray *assetDirs =
        [NSArray arrayWithObjects:appleAssets, ofAssets, assimpAssets,
                                  issuesAssets, nil];
    // ---------------------------------------------------------
    // Asset subdirectories sorted by open and proprietary files
    // ---------------------------------------------------------
    NSArray *subDirs =
        [NSArray arrayWithObjects:@"models/", @"models-proprietary/", nil];

    // ------------------------------------------------------
    // Read the valid extensions that are currently supported
    // ------------------------------------------------------
    NSString *validExtsFile =
        [self.testAssetsPath stringByAppendingString:@"valid-extensions.txt"];
    NSArray *validExts = [[NSString
        stringWithContentsOfFile:validExtsFile
                        encoding:NSUTF8StringEncoding
                           error:nil] componentsSeparatedByString:@"\n"];

    // -----------------------------------------------
    // Generate a list of model files that we can test
    // -----------------------------------------------
    NSMutableArray *modelFilePaths = [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    for (NSString *assetDir in assetDirs)
    {
        for (NSString *subDir in subDirs)
        {
            NSString *assetSubDir = [assetDir stringByAppendingString:subDir];
            NSString *scanPath =
                [self.testAssetsPath stringByAppendingString:assetSubDir];
            NSLog(@"========== Scanning asset dir: %@", scanPath);
            NSArray *modelFiles =
                [fileManager subpathsOfDirectoryAtPath:scanPath error:nil];
            for (NSString *modelFileName in modelFiles)
            {
                BOOL isDir = NO;
                NSString *modelFilePath =
                    [scanPath stringByAppendingString:modelFileName];

                if ([fileManager fileExistsAtPath:modelFilePath
                                      isDirectory:&isDir])
                {
                    if (!isDir)
                    {
                        NSString *fileExt =
                            [[modelFilePath lastPathComponent] pathExtension];
                        if (![fileExt isEqualToString:@""] &&
                            ([validExts
                                 containsObject:fileExt.uppercaseString] ||
                             [validExts
                                 containsObject:fileExt.lowercaseString]))
                        {
                            NSLog(@"   %@ : %@ : %@", modelFileName,
                                  assetSubDir, modelFilePath);
                            ModelFile *modelFile = [[ModelFile alloc]
                                initWithFileName:modelFileName
                                          atPath:modelFilePath
                                        inSubDir:assetSubDir];
                            [modelFilePaths addObject:modelFile];
                        }
                    }
                }
            }
        }
    }

    return modelFilePaths;
}

/**
 The test method that tests the structure and serialization of all the testable
 models.

 For every valid supported file extension:
 1. The scene graph is checked by comparing it with a separate scene graph
    loaded using Assimp.
 2. For every model that passes the verification test in 1 above:
    1. The model scene is serialized.
    2. The animation scenes, if existing, are serialized.

 The pass percentage is 90% for the structure test.
 The pass percentage is 99% for the serialization test.
 */
- (void)testAssimpModelFormats
{
    int numFilesTested = 0;
    int numFilesPassed = 0;
    int numFilesTestedForSerialization = 0;
    int numFilesSerialized = 0;
    NSString *tempDir =
        [NSTemporaryDirectory() stringByAppendingString:@"temp-scn-assets/"];
    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:tempDir
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error])
    {
        NSLog(@" FAILED TO CREATE TMP SCN ASSETS DIR: %@ with error: %@",
              tempDir, error.description);
    }
    NSArray *modelFiles = [self getModelFiles];
    for (ModelFile *modelFile in modelFiles)
    {
        NSLog(@"=== TESTING %@ file ===", modelFile.path);
        ModelLog *testLog = [[ModelLog alloc] init];
        [self checkModel:modelFile.path testLog:testLog];
        ++numFilesTested;
        if ([testLog testPassed])
        {
            ++numFilesTestedForSerialization;
            ++numFilesPassed;
            NSString *scnAsset =
                [tempDir stringByAppendingString:[modelFile getScnAssetFile]];
            NSLog(@"=== File %@ ==> SCN: %@ ===", modelFile.file, scnAsset);
            NSString *scnAssetDir =
                [scnAsset stringByDeletingLastPathComponent];
            if (![[NSFileManager defaultManager]
                          createDirectoryAtPath:scnAssetDir
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error])
            {
                NSLog(@" FAILED TO CREATE TMP SCN ASSET SUB DIR: %@ with "
                      @"error: %@",
                      scnAssetDir, error.description);
            }

            NSString *fileSchemeScnAsset =
                [@"file://" stringByAppendingString:scnAsset];

            SCNAssimpScene *assimpScene = [SCNAssimpScene
                assimpSceneWithURL:[NSURL URLWithString:modelFile.path]
                  postProcessFlags:AssimpKit_Process_FlipUVs |
                                   AssimpKit_Process_Triangulate];
            if ([assimpScene.modelScene
                         writeToURL:[NSURL URLWithString:fileSchemeScnAsset]
                            options:nil
                           delegate:nil
                    progressHandler:nil])
            {
                ++numFilesSerialized;
                NSLog(@" Serialization success");
            }
            else
            {
                NSLog(@" Serialization failed");
            }

            for (NSString *animKey in assimpScene.animationScenes.allKeys)
            {
                SCNScene *animScene =
                    [assimpScene.animationScenes valueForKey:animKey];
                NSString *animScnAsset = [tempDir
                    stringByAppendingString:[modelFile
                                                getAnimScnAssetFile:animKey]];
                NSLog(@"=== File %@ ==> ANIM SCN: %@ ===", modelFile.file,
                      animScnAsset);
                NSString *fileSchemeAnimScnAsset =
                    [@"file://" stringByAppendingString:animScnAsset];
                ++numFilesTestedForSerialization;
                if ([animScene writeToURL:
                                   [NSURL URLWithString:fileSchemeAnimScnAsset]
                                  options:nil
                                 delegate:nil
                          progressHandler:nil])
                {
                    ++numFilesSerialized;
                    NSLog(@" Anim Serialization success");
                }
                else
                {
                    NSLog(@" Anim Serialization failed");
                }
            }
        }
        else
        {
            NSLog(@" The model testing failed with "
                  @"errors: %@",
                  [testLog getErrors]);
        }
    }
    if (![[NSFileManager defaultManager] removeItemAtPath:tempDir error:&error])
    {
        NSLog(@" FAILED TO REMOVE TEMP DIR: %@ with error: %@", tempDir,
              error.description);
    }
    float passPercent = numFilesPassed * 100.0 / numFilesTested;
    float serlPercent =
        numFilesSerialized * 100.0 / numFilesTestedForSerialization;
    NSLog(@" NUM OF FILES TESTED                   : %d", numFilesTested);
    NSLog(@" NUM OF FILES PASSED VERIFICATION      : %d", numFilesPassed);
    NSLog(@" PASS PERCENT VERFICIATION             : %f", passPercent);
    NSLog(@" NUM OF FILES TESTED FOR SERIALIZATION : %d",
          numFilesTestedForSerialization);
    NSLog(@" NUM OF FILES SERIALIZED               : %d", numFilesSerialized);
    NSLog(@" SERL PERCENT VERFICIATION             : %f", serlPercent);
    XCTAssertGreaterThan(passPercent, 90,
                         @"The 3D file model test verification is %f "
                         @"instead of the expected > 90 percent",
                         passPercent);
    XCTAssertGreaterThan(serlPercent, 99,
                         @"The 3D file serializaton test verification is %f "
                         @"instead of the expected > 99 percent",
                         serlPercent);
}

@end
