
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
 * Neither the name of the assimp team, nor the names of its
 contributors may be used to endorse or promote products
 derived from this software without specific prior
 written permission of the assimp team.
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

#define LOG_LEVEL_DEF ddLogLevel

#import <CocoaLumberjack/CocoaLumberjack.h>
#import <XCTest/XCTest.h>
#import "AssimpImporter.h"
#import "SCNAssimpAnimation.h"
#include "assimp/cimport.h"     // Plain-C interface
#include "assimp/light.h"       // Lights
#include "assimp/material.h"    // Materials
#include "assimp/postprocess.h" // Post processing flags
#include "assimp/scene.h"       // Output data structure

@interface AssimpImporterTests : XCTestCase

@property (strong, nonatomic) NSMutableDictionary *modelLogs;
@property (strong, nonatomic) NSString *testAssetsPath;

@end

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation AssimpImporterTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
    self.modelLogs = [[NSMutableDictionary alloc] init];
    DDLogInfo(@" Asset models path: %@", TEST_ASSETS_PATH);
    self.testAssetsPath = TEST_ASSETS_PATH;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.
    [super tearDown];
}

#pragma mark - Check node geometry

- (void)checkNodeGeometry:(const struct aiNode *)aiNode
                 nodeName:(NSString *)nodeName
            withSceneNode:(SCNNode *)sceneNode
                  aiScene:(const struct aiScene *)aiScene
{
    int nVertices = 0;
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        nVertices += aiMesh->mNumVertices;
    }
    DDLogInfo(@" Checking node geometry vertices");
    SCNGeometrySource *vertexSource =
        [sceneNode.geometry.geometrySources objectAtIndex:0];
    XCTAssertEqual(nVertices, vertexSource.vectorCount,
                   "Scene node %@ geometry does not have expected %d vertices",
                   nodeName, nVertices);
    DDLogInfo(@" Checking node geometry normals");
    SCNGeometrySource *normalSource =
        [sceneNode.geometry.geometrySources objectAtIndex:1];
    XCTAssertEqual(nVertices, normalSource.vectorCount,
                   "Scene node %@ geometry does not have expected %d normals",
                   nodeName, nVertices);
    DDLogInfo(@" Checking node geometry tex coords");
    SCNGeometrySource *texSource =
        [sceneNode.geometry.geometrySources objectAtIndex:2];
    XCTAssertEqual(nVertices, texSource.vectorCount,
                   "Scene node %@ geometry does not have expected %d texCoords",
                   nodeName, nVertices);
}

#pragma mark - Check node materials

- (void)checkNode:(const struct aiNode *)aiNode
         material:(const struct aiMaterial *)aiMaterial
      textureType:(enum aiTextureType)aiTextureType
    withSceneNode:(SCNNode *)sceneNode
      scnMaterial:(SCNMaterial *)scnMaterial
        modelPath:(NSString *)modelPath
{
    int nTextures = aiGetMaterialTextureCount(aiMaterial, aiTextureType);
    if (nTextures > 0)
    {
        DDLogInfo(@" has %d textures", nTextures);
        NSString *texFileName;
        if (aiTextureType == aiTextureType_DIFFUSE)
        {
            texFileName = scnMaterial.diffuse.contents;
        }
        else if (aiTextureType == aiTextureType_SPECULAR)
        {
            texFileName = scnMaterial.specular.contents;
        }
        else if (aiTextureType == aiTextureType_AMBIENT)
        {
            texFileName = scnMaterial.ambient.contents;
        }
        else if (aiTextureType == aiTextureType_REFLECTION)
        {
            texFileName = scnMaterial.reflective.contents;
        }
        else if (aiTextureType == aiTextureType_EMISSIVE)
        {
            texFileName = scnMaterial.emission.contents;
        }
        else if (aiTextureType == aiTextureType_OPACITY)
        {
            texFileName = scnMaterial.transparent.contents;
        }
        else if (aiTextureType == aiTextureType_NORMALS)
        {
            texFileName = scnMaterial.normal.contents;
        }
        else if (aiTextureType == aiTextureType_LIGHTMAP)
        {
            texFileName = scnMaterial.ambientOcclusion.contents;
        }
        DDLogInfo(@" Texture: file name: %@", texFileName);
        XCTAssertEqualObjects(
            [texFileName stringByDeletingLastPathComponent],
            [modelPath stringByDeletingLastPathComponent],
            @"The texture file name is not a file under the model path");
    }
    else
    {
        CGColorRef color;
        if (aiTextureType == aiTextureType_DIFFUSE)
        {
            color = (__bridge CGColorRef)[scnMaterial diffuse].contents;
        }
        else if (aiTextureType == aiTextureType_SPECULAR)
        {
            color = (__bridge CGColorRef)[scnMaterial specular].contents;
        }
        else if (aiTextureType == aiTextureType_AMBIENT)
        {
            color = (__bridge CGColorRef)[scnMaterial ambient].contents;
        }
        else if (aiTextureType == aiTextureType_REFLECTION)
        {
            color = (__bridge CGColorRef)[scnMaterial reflective].contents;
        }
        else if (aiTextureType == aiTextureType_EMISSIVE)
        {
            color = (__bridge CGColorRef)[scnMaterial emission].contents;
        }
        else if (aiTextureType == aiTextureType_OPACITY)
        {
            color = (__bridge CGColorRef)[scnMaterial transparent].contents;
        }
        XCTAssert(color, @"The material color does not exist");
    }
}

- (void)checkNodeMaterials:(const struct aiNode *)aiNode
                  nodeName:(NSString *)nodeName
             withSceneNode:(SCNNode *)sceneNode
                   aiScene:(const struct aiScene *)aiScene
                 modelPath:(NSString *)modelPath
{
    DDLogInfo(@" Checking materials with model path prefix: %@",
              [modelPath stringByDeletingLastPathComponent]);
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        const struct aiMaterial *aiMaterial =
            aiScene->mMaterials[aiMesh->mMaterialIndex];
        SCNMaterial *material = [sceneNode.geometry.materials objectAtIndex:i];
        DDLogInfo(@" Checking diffuse");
        [self checkNode:aiNode
                 material:aiMaterial
              textureType:aiTextureType_DIFFUSE
            withSceneNode:sceneNode
              scnMaterial:material
                modelPath:modelPath];
        DDLogInfo(@" Checking specular");
        [self checkNode:aiNode
                 material:aiMaterial
              textureType:aiTextureType_SPECULAR
            withSceneNode:sceneNode
              scnMaterial:material
                modelPath:modelPath];
        DDLogInfo(@" Checking ambient");
        [self checkNode:aiNode
                 material:aiMaterial
              textureType:aiTextureType_AMBIENT
            withSceneNode:sceneNode
              scnMaterial:material
                modelPath:modelPath];
        DDLogInfo(@" Checking reflective");
        [self checkNode:aiNode
                 material:aiMaterial
              textureType:aiTextureType_REFLECTION
            withSceneNode:sceneNode
              scnMaterial:material
                modelPath:modelPath];
        DDLogInfo(@" Checking emssive");
        [self checkNode:aiNode
                 material:aiMaterial
              textureType:aiTextureType_EMISSIVE
            withSceneNode:sceneNode
              scnMaterial:material
                modelPath:modelPath];
        DDLogInfo(@" Checking opacity");
        [self checkNode:aiNode
                 material:aiMaterial
              textureType:aiTextureType_OPACITY
            withSceneNode:sceneNode
              scnMaterial:material
                modelPath:modelPath];
        DDLogInfo(@" Checking normals");
        [self checkNode:aiNode
                 material:aiMaterial
              textureType:aiTextureType_NORMALS
            withSceneNode:sceneNode
              scnMaterial:material
                modelPath:modelPath];
        DDLogInfo(@" Checking lightmap");
        [self checkNode:aiNode
                 material:aiMaterial
              textureType:aiTextureType_LIGHTMAP
            withSceneNode:sceneNode
              scnMaterial:material
                modelPath:modelPath];
    }
}

#pragma mark - Check lights

- (void)checkLights:(const struct aiScene *)aiScene
          withScene:(SCNAssimpScene *)scene
{
    for (int i = 0; i < aiScene->mNumLights; i++)
    {
        const struct aiLight *aiLight = aiScene->mLights[i];
        const struct aiString aiLightNodeName = aiLight->mName;
        NSString *lightNodeName = [NSString
            stringWithUTF8String:(const char *_Nonnull) & aiLightNodeName.data];
        DDLogInfo(@" Check light node %@", lightNodeName);
        SCNNode *lightNode =
            [scene.rootNode childNodeWithName:lightNodeName recursively:YES];
        XCTAssert(lightNode, @"The light node does not exist");
        SCNLight* light = lightNode.light;
        XCTAssert(light, @"The light node does not have a light");
        if (aiLight->mType == aiLightSource_DIRECTIONAL)
        {
            XCTAssertEqualObjects(light.type, SCNLightTypeDirectional,
            @" The light type is not directional");
        }
        else if (aiLight->mType == aiLightSource_POINT)
        {
            XCTAssertEqualObjects(light.type, SCNLightTypeOmni,
                    @" The light type is not point");
        }
        else if (aiLight->mType == aiLightSource_SPOT)
        {
            XCTAssertEqualObjects(light.type, SCNLightTypeSpot,
                    @" The light type is not directional");
        }

    }
}

#pragma mark - Check node

- (void)checkNode:(const struct aiNode *)aiNode
    withSceneNode:(SCNNode *)sceneNode
          aiScene:(const struct aiScene *)aiScene
        modelPath:(NSString *)modelPath
{
    const struct aiString *aiNodeName = &aiNode->mName;
    NSString *nodeName =
        [NSString stringWithUTF8String:(const char *)&aiNodeName->data];
    DDLogInfo(@"--- Checking node %@", nodeName);
    XCTAssertEqualObjects(nodeName, sceneNode.name,
                          @"aiNode %@ does not match SCNNode %@", nodeName,
                          sceneNode.name);
    if (aiNode->mNumMeshes > 0)
    {
        [self checkNodeGeometry:aiNode
                       nodeName:nodeName
                  withSceneNode:sceneNode
                        aiScene:aiScene];
        [self checkNodeMaterials:aiNode
                        nodeName:nodeName
                   withSceneNode:sceneNode
                         aiScene:aiScene
                       modelPath:modelPath];
    }
    for (int i = 0; i < aiNode->mNumChildren; i++)
    {
        const struct aiNode *aiChildNode = aiNode->mChildren[i];
        SCNNode *sceneChildNode = [sceneNode.childNodes objectAtIndex:i];
        [self checkNode:aiChildNode
            withSceneNode:sceneChildNode
                  aiScene:aiScene
                modelPath:modelPath];
    }
}

#pragma mark - Check model

- (BOOL)checkModel:(NSString *)path
{
    const char *pFile = [path UTF8String];
    const struct aiScene *aiScene = aiImportFile(pFile, aiProcess_FlipUVs);
    // If the import failed, report it
    if (!aiScene)
    {
        NSString *errorString =
            [NSString stringWithUTF8String:aiGetErrorString()];
        DDLogError(@" Scene importing failed for filePath %@", path);
        DDLogError(@" Scene importing failed with error %@", errorString);
        return NO;
    }

    AssimpImporter *importer = [[AssimpImporter alloc] init];
    SCNAssimpScene *scene = [importer importScene:path];

    [self checkNode:aiScene->mRootNode
        withSceneNode:[scene.rootNode.childNodes objectAtIndex:0]
              aiScene:aiScene
            modelPath:path];
    [self checkLights:aiScene withScene:scene];

    return YES;
}

#pragma mark - Test all models

- (void)testAssimpModelFormats
{
    NSString *appleAssets =
        [self.testAssetsPath stringByAppendingString:@"/apple"];
    NSString *ofAssets = [self.testAssetsPath stringByAppendingString:@"/of"];
    NSString *assimpAssets =
        [self.testAssetsPath stringByAppendingString:@"/assimp"];

    NSString *modelPath =
        [appleAssets stringByAppendingString:
                         @"/models-proprietary/Collada/explorer_skinned.dae"];
    DDLogInfo(@" Initial test model: %@", modelPath);
    [self checkModel:modelPath];
}

@end
