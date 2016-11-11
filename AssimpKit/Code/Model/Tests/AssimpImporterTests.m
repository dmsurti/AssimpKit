
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

- (void)checkNode:(const struct aiNode *)aiNode
    withSceneNode:(SCNNode *)sceneNode
          aiScene:(const struct aiScene *)aiScene
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
        XCTAssertEqual(
            nVertices, vertexSource.vectorCount,
            "Scene node %@ geometry does not have expected %d vertices",
            nodeName, nVertices);
        DDLogInfo(@" Checking node geometry normals");
        SCNGeometrySource *normalSource =
            [sceneNode.geometry.geometrySources objectAtIndex:1];
        XCTAssertEqual(
            nVertices, normalSource.vectorCount,
            "Scene node %@ geometry does not have expected %d normals",
            nodeName, nVertices);
        DDLogInfo(@" Checking node geometry tex coords");
        SCNGeometrySource *texSource =
            [sceneNode.geometry.geometrySources objectAtIndex:2];
        XCTAssertEqual(
            nVertices, texSource.vectorCount,
            "Scene node %@ geometry does not have expected %d texCoords",
            nodeName, nVertices);
    }
    for (int i = 0; i < aiNode->mNumChildren; i++)
    {
        const struct aiNode *aiChildNode = aiNode->mChildren[i];
        SCNNode *sceneChildNode = [sceneNode.childNodes objectAtIndex:i];
        [self checkNode:aiChildNode
            withSceneNode:sceneChildNode
                  aiScene:aiScene];
    }
}

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
              aiScene:aiScene];

    return YES;
}

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
