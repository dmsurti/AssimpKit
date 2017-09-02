
/*
---------------------------------------------------------------------------
Assimp to Scene Kit Library (AssimpKit)
---------------------------------------------------------------------------
 Copyright (c) 2016, Deepak Surti, Ison Apps, AssimpKit team
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

#import "AssimpImporter.h"
#import "SCNAssimpAnimation.h"
#import "SCNTextureInfo.h"
#include "assimp/cimport.h"     // Plain-C interface
#include "assimp/light.h"       // Lights
#include "assimp/material.h"    // Materials
#include "assimp/postprocess.h" // Post processing flags
#include "assimp/scene.h"       // Output data structure

@interface AssimpImporter ()

#pragma mark - Bone data

/**
 @name Bone data
 */

/**
 The array of bone names across all meshes in all nodes.
 */
@property (readwrite, nonatomic) NSMutableArray *boneNames;

/**
 The array of unique bone names across all meshes in all nodes.
 */
@property (readwrite, nonatomic) NSArray *uniqueBoneNames;

/**
 The array of unique bone nodes across all meshes in all nodes.
 */
@property (readwrite, nonatomic) NSArray *uniqueBoneNodes;

/**
 The dictionary of bone inverse bind transforms, where key is the bone name.
 */
@property (readwrite, nonatomic) NSMutableDictionary *boneTransforms;

/**
 The array of unique bone transforms for all unique bone nodes.
 */
@property (readwrite, nonatomic) NSArray *uniqueBoneTransforms;

/**
 The root node of the skeleton in the scene.
 */
@property (readwrite, nonatomic) SCNNode *skeleton;

@end

@implementation AssimpImporter

#pragma mark - Creating an importer

/**
 @name Creating an importer
 */

/**
 Creates an importer to import files supported by AssimpKit.

 @return A new importer.
 */
- (id)init
{
    self = [super init];
    if (self)
    {
        self.boneNames = [[NSMutableArray alloc] init];
        self.boneTransforms = [[NSMutableDictionary alloc] init];

        return self;
    }
    return nil;
}

#pragma mark - Loading a scene

/**
 @name Loading a scene
 */

/**
 Loads a scene from the specified file path.

 @param filePath The path to the scene file to load.
 @param postProcessFlags The flags for all possible post processing steps.
 @return A new scene object, or nil if no scene could be loaded.
 */
- (SCNAssimpScene *)importScene:(NSString *)filePath
               postProcessFlags:(AssimpKitPostProcessSteps)postProcessFlags
{
    // Start the import on the given file with some example postprocessing
    // Usually - if speed is not the most important aspect for you - you'll t
    // probably to request more postprocessing than we do in this example.
    const char *pFile = [filePath UTF8String];
    const struct aiScene *aiScene = aiImportFile(pFile, postProcessFlags);
    // aiProcess_FlipUVs | aiProcess_Triangulate
    // If the import failed, report it
    if (!aiScene)
    {
        NSString *errorString =
            [NSString stringWithUTF8String:aiGetErrorString()];
        ALog(@" Scene importing failed for filePath %@", filePath);
        ALog(@" Scene importing failed with error %@", errorString);
        return nil;
    }
    // Now we can access the file's contents
    SCNAssimpScene *scene =
        [self makeSCNSceneFromAssimpScene:aiScene atPath:filePath];
    // We're done. Release all resources associated with this import
    aiReleaseImport(aiScene);
    return scene;
}

#pragma mark - Make scenekit scene

/**
 @name Make scenekit scene
 */

/**
 Creates a scenekit scene from the scene representing the file at a given path.

 @param aiScene The assimp scene.
 @param path The path to the scene file to load.
 @return A new scene object.
 */
- (SCNAssimpScene *)makeSCNSceneFromAssimpScene:(const struct aiScene *)aiScene
                                         atPath:(NSString *)path
{
    DLog(@" Make an SCNScene");
    const struct aiNode *aiRootNode = aiScene->mRootNode;
    SCNAssimpScene *scene = [[SCNAssimpScene alloc] init];
    /*
   -------------------------------------------------------------------
   Assign geometry, materials, lights and cameras to the node
   ---------------------------------------------------------------------
   */
    SCNNode *scnRootNode =
        [self makeSCNNodeFromAssimpNode:aiRootNode inScene:aiScene atPath:path];
    [scene.rootNode addChildNode:scnRootNode];
    /*
   ---------------------------------------------------------------------
   Animations and skinning
   ---------------------------------------------------------------------
   */
    [self buildSkeletonDatabaseForScene:scene];
    [self makeSkinnerForAssimpNode:aiRootNode inScene:aiScene scnScene:scene];
    [self createAnimationsFromScene:aiScene withScene:scene atPath:path];
    /*
     ---------------------------------------------------------------------
     Make SCNScene for model and animations
     ---------------------------------------------------------------------
     */
    [scene makeModelScene];
    [scene makeAnimationScenes];

    return scene;
}

#pragma mark - Make scenekit node

/**
 @name Make a scenekit node
 */

/**
 Creates a new scenekit node from the assimp scene node

 @param aiNode The assimp scene node.
 @param aiScene The assimp scene.
 @param path The path to the scene file to load.
 @return A new scene node.
 */
- (SCNNode *)makeSCNNodeFromAssimpNode:(const struct aiNode *)aiNode
                               inScene:(const struct aiScene *)aiScene
                                atPath:(NSString *)path
{
    SCNNode *node = [[SCNNode alloc] init];
    const struct aiString *aiNodeName = &aiNode->mName;
    node.name = [NSString stringWithUTF8String:aiNodeName->data];
    DLog(@" Creating node %@ with %d meshes", node.name, aiNode->mNumMeshes);
    int nVertices = [self findNumVerticesInNode:aiNode inScene:aiScene];
    node.geometry = [self makeSCNGeometryFromAssimpNode:aiNode
                                                inScene:aiScene
                                           withVertices:nVertices
                                                 atPath:path];
    // node.light = [self makeSCNLightFromAssimpNode:aiNode inScene:aiScene];
    node.camera = [self makeSCNCameraFromAssimpNode:aiNode inScene:aiScene];
    [self.boneNames
        addObjectsFromArray:[self getBoneNamesForAssimpNode:aiNode
                                                    inScene:aiScene]];
    [self.boneTransforms
        addEntriesFromDictionary:[self getBoneTransformsForAssimpNode:aiNode
                                                              inScene:aiScene]];

    // ---------
    // TRANSFORM
    // ---------
    const struct aiMatrix4x4 aiNodeMatrix = aiNode->mTransformation;
    GLKMatrix4 glkNodeMatrix = GLKMatrix4Make(
        aiNodeMatrix.a1, aiNodeMatrix.b1, aiNodeMatrix.c1, aiNodeMatrix.d1,
        aiNodeMatrix.a2, aiNodeMatrix.b2, aiNodeMatrix.c2, aiNodeMatrix.d2,
        aiNodeMatrix.a3, aiNodeMatrix.b3, aiNodeMatrix.c3, aiNodeMatrix.d3,
        aiNodeMatrix.a4, aiNodeMatrix.b4, aiNodeMatrix.c4, aiNodeMatrix.d4);

    SCNMatrix4 scnMatrix = SCNMatrix4FromGLKMatrix4(glkNodeMatrix);
    node.transform = scnMatrix;
    DLog(@" Node %@ position %f %f %f", node.name, aiNodeMatrix.a4,
         aiNodeMatrix.b4, aiNodeMatrix.c4);

    for (int i = 0; i < aiNode->mNumChildren; i++)
    {
        const struct aiNode *aiChildNode = aiNode->mChildren[i];
        SCNNode *childNode = [self makeSCNNodeFromAssimpNode:aiChildNode
                                                     inScene:aiScene
                                                      atPath:path];
        [node addChildNode:childNode];
    }
    return node;
}

#pragma mark - Find the number of vertices, faces and indices of a geometry

/**
 @name Find the number of vertices, faces and indices of a geometry
 */

/**
 Finds the total number of vertices in the meshes of the specified node.

 @param aiNode The assimp scene node.
 @param aiScene The assimp scene.
 @return The number of vertices.
 */
- (int)findNumVerticesInNode:(const struct aiNode *)aiNode
                     inScene:(const struct aiScene *)aiScene
{
    int nVertices = 0;
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        nVertices += aiMesh->mNumVertices;
    }
    return nVertices;
}

/**
 Finds the total number of faces in the meshes of the specified node.

 @param aiNode The assimp scene node.
 @param aiScene The assimp scene.
 @return The number of faces.
 */
- (int)findNumFacesInNode:(const struct aiNode *)aiNode
                  inScene:(const struct aiScene *)aiScene
{
    int nFaces = 0;
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        nFaces += aiMesh->mNumFaces;
    }
    return nFaces;
}

/**
 Finds the total number of indices in the specified mesh by index.

 @param aiMeshIndex The assimp mesh index.
 @param aiScene The assimp scene.
 @return The total number of indices.
 */
- (int)findNumIndicesInMesh:(int)aiMeshIndex
                    inScene:(const struct aiScene *)aiScene
{
    int nIndices = 0;
    const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
    for (int j = 0; j < aiMesh->mNumFaces; j++)
    {
        const struct aiFace *aiFace = &aiMesh->mFaces[j];
        nIndices += aiFace->mNumIndices;
    }
    return nIndices;
}

#pragma mark - Make scenekit geometry sources

/**
 @name Make scenekit geometry sources
 */

/**
 Creates a scenekit geometry source from the vertices of the specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @param nVertices The total number of vertices in the meshes of the aiNode.
 @return A new geometry source whose semantic property is vertex.
 */
- (SCNGeometrySource *)
makeVertexGeometrySourceForNode:(const struct aiNode *)aiNode
                        inScene:(const struct aiScene *)aiScene
                  withNVertices:(int)nVertices
{
        //float scnVertices[nVertices * 3];
    float* scnVertices = (float*)malloc(nVertices * 3 * sizeof(float));
    int verticesCounter = 0;
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        // create SCNGeometry source for aiMesh vertices, normals, texture
        // coordinates
        for (int j = 0; j < aiMesh->mNumVertices; j++)
        {
            const struct aiVector3D *aiVector3D = &aiMesh->mVertices[j];
            scnVertices[verticesCounter++] = aiVector3D->x;
            scnVertices[verticesCounter++] = aiVector3D->y;
            scnVertices[verticesCounter++] = aiVector3D->z;
        }
    }
    SCNGeometrySource *vertexSource = [SCNGeometrySource
        geometrySourceWithData:[NSData
                                   dataWithBytes:scnVertices
                                          length:nVertices * 3 * sizeof(float)]
                      semantic:SCNGeometrySourceSemanticVertex
                   vectorCount:nVertices
               floatComponents:YES
           componentsPerVector:3
             bytesPerComponent:sizeof(float)
                    dataOffset:0
                    dataStride:3 * sizeof(float)];
    free(scnVertices);
    return vertexSource;
}

/**
 Creates a scenekit geometry source from the normals of the specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @param nVertices The number of vertices in the meshes of the aiNode.
 @return A new geometry source whose semantic property is normal.
 */
- (SCNGeometrySource *)
makeNormalGeometrySourceForNode:(const struct aiNode *)aiNode
                        inScene:(const struct aiScene *)aiScene
                  withNVertices:(int)nVertices
{
    float* scnNormals = (float*)malloc(nVertices * 3 * sizeof(float));
    int verticesCounter = 0;
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        if (aiMesh->mNormals != NULL)
        {
            for (int j = 0; j < aiMesh->mNumVertices; j++)
            {
                const struct aiVector3D *aiVector3D = &aiMesh->mNormals[j];
                scnNormals[verticesCounter++] = aiVector3D->x;
                scnNormals[verticesCounter++] = aiVector3D->y;
                scnNormals[verticesCounter++] = aiVector3D->z;
            }
        }
    }
    SCNGeometrySource *normalSource = [SCNGeometrySource
        geometrySourceWithData:[NSData
                                   dataWithBytes:scnNormals
                                          length:nVertices * 3 * sizeof(float)]
                      semantic:SCNGeometrySourceSemanticNormal
                   vectorCount:nVertices
               floatComponents:YES
           componentsPerVector:3
             bytesPerComponent:sizeof(float)
                    dataOffset:0
                    dataStride:3 * sizeof(float)];
    free(scnNormals);
    return normalSource;
}

/**
 Creates a scenekit geometry source from the tangents of the specified node.

@param aiNode The assimp node.
@param aiScene The assimp scene.
@param nVertices The number of vertices in the meshes of the aiNode.
@return A new geometry source whose semantic property is tangent.
*/
- (SCNGeometrySource *)
makeTangentGeometrySourceForNode:(const struct aiNode *)aiNode
inScene:(const struct aiScene *)aiScene
withNVertices:(int)nVertices
{
    float* scnTangents = (float*)malloc(nVertices * 3 * sizeof(float));
    int verticesCounter = 0;
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        if (aiMesh->mTangents != NULL)
        {
            for (int j = 0; j < aiMesh->mNumVertices; j++)
            {
                const struct aiVector3D *aiVector3D = &aiMesh->mTangents[j];
                scnTangents[verticesCounter++] = aiVector3D->x;
                scnTangents[verticesCounter++] = aiVector3D->y;
                scnTangents[verticesCounter++] = aiVector3D->z;
            }
        }
    }
    SCNGeometrySource *tangentSource = [SCNGeometrySource
        geometrySourceWithData:[NSData
                                   dataWithBytes:scnTangents
                                          length:nVertices * 3 * sizeof(float)]
                      semantic:SCNGeometrySourceSemanticTangent
                   vectorCount:nVertices
               floatComponents:YES
           componentsPerVector:3
             bytesPerComponent:sizeof(float)
                    dataOffset:0
                    dataStride:3 * sizeof(float)];
    free(scnTangents);
    return tangentSource;
}


/**
 Creates a scenekit geometry source from the texture coordinates of the
 specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @param nVertices The number of vertices in the meshes of the node.
 @return A new geometry source whose semantic property is texcoord.
 */
- (SCNGeometrySource *)
makeTextureGeometrySourceForNode:(const struct aiNode *)aiNode
                         inScene:(const struct aiScene *)aiScene
                   withNVertices:(int)nVertices
{
    float* scnTextures = (float*)malloc(nVertices * 3 * sizeof(float));
    int verticesCounter = 0;
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        if (aiMesh->mTextureCoords[0] != NULL)
        {
            DLog(@"  Getting texture coordinates");
            for (int j = 0; j < aiMesh->mNumVertices; j++)
            {
                float x = aiMesh->mTextureCoords[0][j].x;
                float y = aiMesh->mTextureCoords[0][j].y;
                scnTextures[verticesCounter++] = x;
                scnTextures[verticesCounter++] = y;
            }
        }
    }
    SCNGeometrySource *textureSource = [SCNGeometrySource
        geometrySourceWithData:[NSData
                                   dataWithBytes:scnTextures
                                          length:nVertices * 2 * sizeof(float)]
                      semantic:SCNGeometrySourceSemanticTexcoord
                   vectorCount:nVertices
               floatComponents:YES
           componentsPerVector:2
             bytesPerComponent:sizeof(float)
                    dataOffset:0
                    dataStride:2 * sizeof(float)];
    free(scnTextures);
    return textureSource;
}

/**
 Creates an array of geometry sources for the specifed node describing
 the vertices in the geometry and their attributes.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @param nVertices The number of vertices in the meshes of the node.
 @return An array of geometry sources.
 */
- (NSArray *)makeGeometrySourcesForNode:(const struct aiNode *)aiNode
                                inScene:(const struct aiScene *)aiScene
                           withVertices:(int)nVertices
{
    NSMutableArray *scnGeometrySources = [[NSMutableArray alloc] init];
    [scnGeometrySources
        addObject:[self makeVertexGeometrySourceForNode:aiNode
                                                inScene:aiScene
                                          withNVertices:nVertices]];
    [scnGeometrySources
        addObject:[self makeNormalGeometrySourceForNode:aiNode
                                                inScene:aiScene
                                          withNVertices:nVertices]];
    [scnGeometrySources
        addObject:[self makeTangentGeometrySourceForNode:aiNode
                                                 inScene:aiScene
                                           withNVertices:nVertices]];
    [scnGeometrySources
        addObject:[self makeTextureGeometrySourceForNode:aiNode
                                                 inScene:aiScene
                                           withNVertices:nVertices]];
    return scnGeometrySources;
}

#pragma mark - Make scenekit geometry elements

/**
 @name Make scenekit geometry elements
 */

/**
 Creates a scenekit geometry element describing how vertices connect to define
 a three-dimensional object, or geometry for the specified mesh of a node.

 @param aiMeshIndex The assimp mesh index.
 @param aiNode The assimp node of the mesh.
 @param aiScene The assimp scene.
 @param indexOffset The total number of indices for the previous meshes.
 @param nFaces The number of faces in the geometry of the mesh.
 @return A new geometry element object.
 */
- (SCNGeometryElement *)
makeIndicesGeometryElementForMeshIndex:(int)aiMeshIndex
                                inNode:(const struct aiNode *)aiNode
                               inScene:(const struct aiScene *)aiScene
                       withIndexOffset:(short)indexOffset
                                nFaces:(int)nFaces
{
    int indicesCounter = 0;
    int nIndices = [self findNumIndicesInMesh:aiMeshIndex inScene:aiScene];
    short scnIndices[nIndices];
    const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
    for (int i = 0; i < aiMesh->mNumFaces; i++)
    {
        const struct aiFace *aiFace = &aiMesh->mFaces[i];
        // we ignore faces which are not triangulated
        if(aiFace->mNumIndices != 3) {
            return nil;
        }
        for (int j = 0; j < aiFace->mNumIndices; j++)
        {
            scnIndices[indicesCounter++] =
                (short)indexOffset + (short)aiFace->mIndices[j];
        }
    }
    NSData *indicesData =
        [NSData dataWithBytes:scnIndices length:sizeof(scnIndices)];
    SCNGeometryElement *indices = [SCNGeometryElement
        geometryElementWithData:indicesData
                  primitiveType:SCNGeometryPrimitiveTypeTriangles
                 primitiveCount:nFaces
                  bytesPerIndex:sizeof(short)];
    return indices;
}

/**
 Creates an array of scenekit geometry element obejcts describing how to
 connect the geometry's vertices of the specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @return An array of geometry elements.
 */
- (NSArray *)makeGeometryElementsforNode:(const struct aiNode *)aiNode
                                 inScene:(const struct aiScene *)aiScene
{
    NSMutableArray *scnGeometryElements = [[NSMutableArray alloc] init];
    int indexOffset = 0;
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        SCNGeometryElement *indices =
            [self makeIndicesGeometryElementForMeshIndex:aiMeshIndex
                                                  inNode:aiNode
                                                 inScene:aiScene
                                         withIndexOffset:indexOffset
                                                  nFaces:aiMesh->mNumFaces];
        if(indices != nil) {
            [scnGeometryElements addObject:indices];
        }
        indexOffset += aiMesh->mNumVertices;
    }

    return scnGeometryElements;
}

#pragma mark - Make scenekit materials

/**
 @name Make scenekit materials
 */

/**
 Updates a scenekit material property with the texture file path or the color
 if no texture is specifed.

 @param aiMaterial The assimp material.
 @param textureInfo The metadata of the texture.
 @param material The scenekit material.
 @param path The path to the scene file to load.
 */
- (void)makeMaterialPropertyForMaterial:(const struct aiMaterial *)aiMaterial
                        withTextureInfo:(SCNTextureInfo *)textureInfo
                        withSCNMaterial:(SCNMaterial *)material
                                 atPath:(NSString *)path
{
    NSString *channel = @".mappingChannel";
    NSString *wrapS = @".wrapS";
    NSString *wrapT = @".wrapS";
    NSString *intensity = @".intensity";
    NSString *minFilter = @".minificationFilter";
    NSString *magFilter = @".magnificationFilter";

    NSString *keyPrefix = @"";
    if (textureInfo.textureType == aiTextureType_DIFFUSE)
    {
        material.diffuse.contents = [textureInfo getMaterialPropertyContents];
        keyPrefix = @"diffuse";
    }
    else if (textureInfo.textureType == aiTextureType_SPECULAR)
    {
        material.specular.contents = [textureInfo getMaterialPropertyContents];
        keyPrefix = @"specular";
    }
    else if (textureInfo.textureType == aiTextureType_AMBIENT)
    {
        material.ambient.contents = [textureInfo getMaterialPropertyContents];
        keyPrefix = @"ambient";
    }
    else if (textureInfo.textureType == aiTextureType_REFLECTION)
    {
        material.reflective.contents =
            [textureInfo getMaterialPropertyContents];
        keyPrefix = @"reflective";
    }
    else if (textureInfo.textureType == aiTextureType_EMISSIVE)
    {
        material.emission.contents = [textureInfo getMaterialPropertyContents];
        keyPrefix = @"emissive";
    }
    else if (textureInfo.textureType == aiTextureType_OPACITY)
    {
        material.transparent.contents =
        [textureInfo getMaterialPropertyContents];
        keyPrefix = @"transparent";
    }
    else if (textureInfo.textureType == aiTextureType_NORMALS)
    {
        material.normal.contents = [textureInfo getMaterialPropertyContents];
        keyPrefix = @"normal";
    }
    else if (textureInfo.textureType == aiTextureType_HEIGHT)
    {
        material.normal.contents = [textureInfo getMaterialPropertyContents];
        keyPrefix = @"normal";
    }
    else if (textureInfo.textureType == aiTextureType_DISPLACEMENT)
    {
        material.normal.contents = [textureInfo getMaterialPropertyContents];
        keyPrefix = @"normal";
    }
    else if (textureInfo.textureType == aiTextureType_LIGHTMAP)
    {
        material.ambientOcclusion.contents =
            [textureInfo getMaterialPropertyContents];
        keyPrefix = @"ambientOcclusion";
    }

    // Update the keys
    channel = [keyPrefix stringByAppendingString:channel];
    wrapS = [keyPrefix stringByAppendingString:wrapS];
    wrapT = [keyPrefix stringByAppendingString:wrapT];
    intensity = [keyPrefix stringByAppendingString:intensity];
    minFilter = [keyPrefix stringByAppendingString:minFilter];
    magFilter = [keyPrefix stringByAppendingString:magFilter];

    [material setValue:0 forKey:channel];
    [material setValue:[NSNumber numberWithInt:SCNWrapModeRepeat]
                forKey:wrapS];
    [material setValue:[NSNumber numberWithInt:SCNWrapModeRepeat]
                forKey:wrapT];
    [material setValue:[NSNumber numberWithInt:1] forKey:intensity];
    [material setValue:[NSNumber numberWithInt:SCNFilterModeLinear]
                forKey:minFilter];
    [material setValue:[NSNumber numberWithInt:SCNFilterModeLinear]
                forKey:magFilter];
}

/**
 Updates a scenekit material's multiply property

 @param aiMaterial The assimp material
 @param material The scenekit material.
 */
- (void)applyMultiplyPropertyForMaterial:(const struct aiMaterial *)aiMaterial
                         withSCNMaterial:(SCNMaterial *)material
{
    struct aiColor4D color;
    color.r = 0.0f;
    color.g = 0.0f;
    color.b = 0.0f;
    int matColor = -100;
    matColor =
        aiGetMaterialColor(aiMaterial, AI_MATKEY_COLOR_TRANSPARENT, &color);
    if (AI_SUCCESS == matColor)
    {
        if (color.r != 0 && color.g != 0 && color.b != 0)
        {
            CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
            CGFloat components[4] = {color.r, color.g, color.b, color.a};
            CGColorRef color = CGColorCreate(space, components);
            material.multiply.contents = (__bridge id _Nullable)(color);
            CGColorSpaceRelease(space);
            CGColorRelease(color);
        }
    }
}

/**
 Creates an array of scenekit materials one for each mesh of the specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @param path The path to the scene file to load.
 @return An array of scenekit materials.
 */
- (NSMutableArray *)makeMaterialsForNode:(const struct aiNode *)aiNode
                                 inScene:(const struct aiScene *)aiScene
                                  atPath:(NSString *)path
{
    NSMutableArray *scnMaterials = [[NSMutableArray alloc] init];
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        const struct aiMaterial *aiMaterial =
            aiScene->mMaterials[aiMesh->mMaterialIndex];
        struct aiString name;
        aiGetMaterialString(aiMaterial, AI_MATKEY_NAME, &name);
        DLog(
            @" Material name is %@",
            [NSString stringWithUTF8String:(const char *_Nonnull) & name.data]);
        SCNMaterial *material = [SCNMaterial material];
        int kTextureTypes = 10;
        int textureTypes[10] = {
            aiTextureType_DIFFUSE,      aiTextureType_SPECULAR,
            aiTextureType_AMBIENT,      aiTextureType_EMISSIVE,
            aiTextureType_REFLECTION,   aiTextureType_OPACITY,
            aiTextureType_NORMALS,      aiTextureType_HEIGHT,
            aiTextureType_DISPLACEMENT, aiTextureType_SHININESS};
        NSDictionary *textureTypeNames = @{
            @"0" : @"Diffuse",
            @"1" : @"Specular",
            @"2" : @"Ambient",
            @"3" : @"Emissive",
            @"4" : @"Reflection",
            @"5" : @"Opacity",
            @"6" : @"Normals",
            @"7" : @"Height",
            @"8" : @"Displacement",
            @"9" : @"Shininess"
        };

        for(int i = 0; i < kTextureTypes; i++) {
            DLog(@" Loading texture type : %@",
                 [textureTypeNames
                     valueForKey:[NSNumber numberWithInt:i].stringValue]);
            SCNTextureInfo *textureInfo =
                [[SCNTextureInfo alloc] initWithMeshIndex:aiMeshIndex
                                              textureType:textureTypes[i]
                                                  inScene:aiScene
                                                   atPath:path];
            [self makeMaterialPropertyForMaterial:aiMaterial
                                  withTextureInfo:textureInfo
                                  withSCNMaterial:material
                                           atPath:path];
            [textureInfo releaseContents];
        }

        DLog(@"+++ Loading multiply color");
        [self applyMultiplyPropertyForMaterial:aiMaterial
                               withSCNMaterial:material];
        DLog(@"+++ Loading blend mode");
        unsigned int blendMode = 0;
        unsigned int *max;
        aiGetMaterialIntegerArray(aiMaterial, AI_MATKEY_BLEND_FUNC,
                                  (int *)&blendMode, max);
        if (blendMode == aiBlendMode_Default)
        {
            DLog(@" Using alpha blend mode");
            material.blendMode = SCNBlendModeAlpha;
        }
        else if (blendMode == aiBlendMode_Additive)
        {
            DLog(@" Using add blend mode");
            material.blendMode = SCNBlendModeAdd;
        }
        DLog(@"+++ Loading cull/double sided mode");
        /**
     FIXME: The cull mode works only on iOS. Not on OSX.
     Hence has been defaulted to Cull Back.
     USE AI_MATKEY_TWOSIDED to get the cull mode.
     */
        material.cullMode = SCNCullBack;
        DLog(@"+++ Loading shininess");
        int shininess;
        aiGetMaterialIntegerArray(aiMaterial, AI_MATKEY_BLEND_FUNC,
                                  (int *)&shininess, max);
        DLog(@"   shininess: %d", shininess);
            //material.shininess = shininess;
        DLog(@"+++ Loading shading model");
        /**
     FIXME: The shading mode works only on iOS for iPhone.
     Does not work on iOS for iPad and OS X.
     Hence has been defaulted to Blinn.
     USE AI_MATKEY_SHADING_MODEL to get the shading mode.
     */
        material.lightingModelName = SCNLightingModelBlinn;
        [scnMaterials addObject:material];
    }
    return scnMaterials;
}

/**
 Creates a scenekit geometry to attach at the specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @param nVertices The total number of vertices in the meshes of the node.
 @param path The path to the scene file to load.
 @return A new geometry.
 */
- (SCNGeometry *)makeSCNGeometryFromAssimpNode:(const struct aiNode *)aiNode
                                       inScene:(const struct aiScene *)aiScene
                                  withVertices:(int)nVertices
                                        atPath:(NSString *)path
{
    // make SCNGeometry with sources, elements and materials
    NSArray *scnGeometrySources = [self makeGeometrySourcesForNode:aiNode
                                                           inScene:aiScene
                                                      withVertices:nVertices];
    if (scnGeometrySources.count > 0)
    {
        NSArray *scnGeometryElements =
            [self makeGeometryElementsforNode:aiNode inScene:aiScene];
        SCNGeometry *scnGeometry =
            [SCNGeometry geometryWithSources:scnGeometrySources
                                    elements:scnGeometryElements];
        NSArray *scnMaterials =
            [self makeMaterialsForNode:aiNode inScene:aiScene atPath:path];
        if (scnMaterials.count > 0)
        {
            scnGeometry.materials = scnMaterials;
            scnGeometry.firstMaterial = [scnMaterials objectAtIndex:0];
        }
        return scnGeometry;
    }
    return nil;
}

#pragma mark - Make scenekit lights

/**
 @name Make scenekit lights
 */

/**
 Creates a scenekit directional light from an assimp directional light.

 @param aiLight The assimp directional light.
 @return A new scenekit directional light.
 */
- (SCNLight *)makeSCNLightTypeDirectionalForAssimpLight:
    (const struct aiLight *)aiLight
{
    SCNLight *light = [SCNLight light];
    light.type = SCNLightTypeDirectional;
    const struct aiColor3D aiColor = aiLight->mColorSpecular;
    if (aiColor.r != 0 && aiColor.g != 0 && aiColor.b != 0)
    {
        DLog(@" Setting color: %f %f %f", aiColor.r, aiColor.g, aiColor.b);
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGFloat components[4] = {aiColor.r, aiColor.g, aiColor.b, 1.0};
        CGColorRef cgGolor = CGColorCreate(space, components);
        light.color = (__bridge id _Nullable)(cgGolor);
        CGColorSpaceRelease(space);
        CGColorRelease(cgGolor);
    }
    return light;
}

/**
 Creates a scenekit omni light from an assimp omni light.

 @param aiLight The assimp omni light.
 @return A new scenekit omni light.
 */
- (SCNLight *)makeSCNLightTypePointForAssimpLight:
    (const struct aiLight *)aiLight
{
    SCNLight *light = [SCNLight light];
    light.type = SCNLightTypeOmni;
    const struct aiColor3D aiColor = aiLight->mColorSpecular;
    if (aiColor.r != 0 && aiColor.g != 0 && aiColor.b != 0)
    {
        DLog(@" Setting color: %f %f %f", aiColor.r, aiColor.g, aiColor.b);
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGFloat components[4] = {aiColor.r, aiColor.g, aiColor.b, 1.0};
        CGColorRef cgGolor = CGColorCreate(space, components);
        light.color = (__bridge id _Nullable)(cgGolor);
        CGColorSpaceRelease(space);
        CGColorRelease(cgGolor);
    }
    if (aiLight->mAttenuationQuadratic != 0)
    {
        light.attenuationFalloffExponent = 2.0;
    }
    else if (aiLight->mAttenuationLinear != 0)
    {
        light.attenuationFalloffExponent = 1.0;
    }
    return light;
}

/**
 Creates a scenekit spot light from an assimp spot light.

 @param aiLight The assimp spot light.
 @return A new scenekit spot light.
 */
- (SCNLight *)makeSCNLightTypeSpotForAssimpLight:(const struct aiLight *)aiLight
{
    SCNLight *light = [SCNLight light];
    light.type = SCNLightTypeSpot;
    const struct aiColor3D aiColor = aiLight->mColorSpecular;
    if (aiColor.r != 0 && aiColor.g != 0 && aiColor.b != 0)
    {
        DLog(@" Setting color: %f %f %f", aiColor.r, aiColor.g, aiColor.b);
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGFloat components[4] = {aiColor.r, aiColor.g, aiColor.b, 1.0};
        CGColorRef cgGolor = CGColorCreate(space, components);
        light.color = (__bridge id _Nullable)(cgGolor);
        CGColorSpaceRelease(space);
        CGColorRelease(cgGolor);
    }
    if (aiLight->mAttenuationQuadratic != 0)
    {
        light.attenuationFalloffExponent = 2.0;
    }
    else if (aiLight->mAttenuationLinear != 0)
    {
        light.attenuationFalloffExponent = 1.0;
    }
    light.attenuationStartDistance = 0;
    light.attenuationEndDistance = 0;
    light.spotInnerAngle = aiLight->mAngleInnerCone;
    light.spotOuterAngle = aiLight->mAngleOuterCone;
    return light;
}

/**
 Creates a scenekit light to attach at the specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @return A new scenekit light.
 */
- (SCNLight *)makeSCNLightFromAssimpNode:(const struct aiNode *)aiNode
                                 inScene:(const struct aiScene *)aiScene
{
    const struct aiString aiNodeName = aiNode->mName;
    NSString *nodeName = [NSString
        stringWithUTF8String:(const char *_Nonnull) & aiNodeName.data];
    for (int i = 0; i < aiScene->mNumLights; i++)
    {
        const struct aiLight *aiLight = aiScene->mLights[i];
        const struct aiString aiLightNodeName = aiLight->mName;
        NSString *lightNodeName = [NSString
            stringWithUTF8String:(const char *_Nonnull) & aiLightNodeName.data];
        if ([nodeName isEqualToString:lightNodeName])
        {
            DLog(@"### Creating light for node %@", nodeName);
            DLog(@"    ambient     %f %f %f ", aiLight->mColorAmbient.r,
                 aiLight->mColorAmbient.g, aiLight->mColorAmbient.b);
            DLog(@"    diffuse     %f %f %f ", aiLight->mColorDiffuse.r,
                 aiLight->mColorDiffuse.g, aiLight->mColorDiffuse.b);
            DLog(@"    specular    %f %f %f ", aiLight->mColorSpecular.r,
                 aiLight->mColorSpecular.g, aiLight->mColorSpecular.b);
            DLog(@"    inner angle %f", aiLight->mAngleInnerCone);
            DLog(@"    outer angle %f", aiLight->mAngleOuterCone);
            DLog(@"    att const   %f", aiLight->mAttenuationConstant);
            DLog(@"    att linear  %f", aiLight->mAttenuationLinear);
            DLog(@"    att quad    %f", aiLight->mAttenuationQuadratic);
            DLog(@"    position    %f %f %f", aiLight->mPosition.x,
                 aiLight->mPosition.y, aiLight->mPosition.z);
            if (aiLight->mType == aiLightSource_DIRECTIONAL)
            {
                DLog(@"    type        Directional");
                return [self makeSCNLightTypeDirectionalForAssimpLight:aiLight];
            }
            else if (aiLight->mType == aiLightSource_POINT)
            {
                DLog(@"    type        Omni");
                return [self makeSCNLightTypePointForAssimpLight:aiLight];
            }
            else if (aiLight->mType == aiLightSource_SPOT)
            {
                DLog(@"    type        Spot");
                return [self makeSCNLightTypeSpotForAssimpLight:aiLight];
            }
        }
    }
    return nil;
}

#pragma mark - Make scenekit cameras

/**
 @name Make scenekit cameras
 */

/**
 Creates a scenekit camera to attach at the specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @return A new scenekit camera.
 */
- (SCNCamera *)makeSCNCameraFromAssimpNode:(const struct aiNode *)aiNode
                                   inScene:(const struct aiScene *)aiScene
{
    const struct aiString aiNodeName = aiNode->mName;
    NSString *nodeName = [NSString
        stringWithUTF8String:(const char *_Nonnull) & aiNodeName.data];
    for (int i = 0; i < aiScene->mNumCameras; i++)
    {
        const struct aiCamera *aiCamera = aiScene->mCameras[i];
        const struct aiString aiCameraName = aiCamera->mName;
        NSString *cameraNodeName = [NSString
            stringWithUTF8String:(const char *_Nonnull) & aiCameraName.data];
        if ([nodeName isEqualToString:cameraNodeName])
        {
            SCNCamera *camera = [SCNCamera camera];
            camera.xFov = aiCamera->mHorizontalFOV;
            camera.zNear = aiCamera->mClipPlaneNear;
            camera.zFar = aiCamera->mClipPlaneFar;
            return camera;
        }
    }
    return nil;
}

#pragma mark - Make scenekit skinner

/**
 @name Make scenekit skinner
 */

/**
 Finds the number of bones in the meshes of the specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @return The number of bones.
 */
- (int)findNumBonesInNode:(const struct aiNode *)aiNode
                  inScene:(const struct aiScene *)aiScene
{
    int nBones = 0;
    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        nBones += aiMesh->mNumBones;
    }
    return nBones;
}

/**
 Creates an array of bone names in the meshes of the specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @return An array of bone names.
 */
- (NSArray *)getBoneNamesForAssimpNode:(const struct aiNode *)aiNode
                               inScene:(const struct aiScene *)aiScene
{
    NSMutableArray *boneNames = [[NSMutableArray alloc] init];

    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        for (int j = 0; j < aiMesh->mNumBones; j++)
        {
            const struct aiBone *aiBone = aiMesh->mBones[j];
            const struct aiString name = aiBone->mName;
            [boneNames
                addObject:[NSString
                              stringWithUTF8String:(const char *_Nonnull) &
                                                   name.data]];
        }
    }

    return boneNames;
}

/**
 Creates a dictionary of bone transforms where bone name is the key, for the
 meshes of the specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @return A dictionary of bone transforms where bone name is the key.
 */
- (NSDictionary *)getBoneTransformsForAssimpNode:(const struct aiNode *)aiNode
                                         inScene:(const struct aiScene *)aiScene
{
    NSMutableDictionary *boneTransforms = [[NSMutableDictionary alloc] init];

    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        for (int j = 0; j < aiMesh->mNumBones; j++)
        {
            const struct aiBone *aiBone = aiMesh->mBones[j];
            const struct aiString name = aiBone->mName;
            NSString *key = [NSString
                stringWithUTF8String:(const char *_Nonnull) & name.data];
            if ([boneTransforms valueForKey:key] == nil)
            {
                const struct aiMatrix4x4 aiNodeMatrix = aiBone->mOffsetMatrix;
                GLKMatrix4 glkBoneMatrix = GLKMatrix4Make(
                    aiNodeMatrix.a1, aiNodeMatrix.b1, aiNodeMatrix.c1,
                    aiNodeMatrix.d1, aiNodeMatrix.a2, aiNodeMatrix.b2,
                    aiNodeMatrix.c2, aiNodeMatrix.d2, aiNodeMatrix.a3,
                    aiNodeMatrix.b3, aiNodeMatrix.c3, aiNodeMatrix.d3,
                    aiNodeMatrix.a4, aiNodeMatrix.b4, aiNodeMatrix.c4,
                    aiNodeMatrix.d4);

                SCNMatrix4 scnMatrix = SCNMatrix4FromGLKMatrix4(glkBoneMatrix);
                [boneTransforms setValue:[NSValue valueWithSCNMatrix4:scnMatrix]
                                  forKey:key];
            }
        }
    }

    return boneTransforms;
}

/**
 Creates an array of bone transforms from a dictionary of bone transforms where
 bone name is the key.

 @param boneNames The array of bone names.
 @param boneTransforms The dictionary of bone transforms.
 @return An array of bone transforms
 */
- (NSArray *)getTransformsForBones:(NSArray *)boneNames
                    fromTransforms:(NSDictionary *)boneTransforms
{
    NSMutableArray *transforms = [[NSMutableArray alloc] init];
    for (NSString *boneName in boneNames)
    {
        [transforms addObject:[boneTransforms valueForKey:boneName]];
    }
    return transforms;
}

/**
 Creates an array of scenekit bone nodes for the specified bone names.

 @param scene The scenekit scene.
 @param boneNames The array of bone names.
 @return An array of scenekit bone nodes.
 */
- (NSArray *)findBoneNodesInScene:(SCNScene *)scene
                         forBones:(NSArray *)boneNames
{
    NSMutableArray *boneNodes = [[NSMutableArray alloc] init];
    for (NSString *boneName in boneNames)
    {
        SCNNode *boneNode =
            [scene.rootNode childNodeWithName:boneName recursively:YES];
        [boneNodes addObject:boneNode];
    }
    return boneNodes;
}

/**
 Find the root node of the skeleton from the specified bone nodes.

 @param boneNodes The array of bone nodes.
 @return The root node of the skeleton.
 */
- (SCNNode *)findSkeletonNodeFromBoneNodes:(NSArray *)boneNodes
{
    NSMutableDictionary *nodeDepths = [[NSMutableDictionary alloc] init];
    int minDepth = -1;
    for (SCNNode *boneNode in boneNodes)
    {
        int depth = [self findDepthOfNodeFromRoot:boneNode];
        DLog(@" bone with depth is (min depth): %@ -> %d ( %d )", boneNode.name,
             depth, minDepth);
        if (minDepth == -1 || (depth <= minDepth))
        {
            minDepth = depth;
            NSString *key = [NSNumber numberWithInt:minDepth].stringValue;
            NSMutableArray *minDepthNodes = [nodeDepths valueForKey:key];
            if (minDepthNodes == nil)
            {
                minDepthNodes = [[NSMutableArray alloc] init];
                [nodeDepths setValue:minDepthNodes forKey:key];
            }
            [minDepthNodes addObject:boneNode];
        }
    }
    NSString *minDepthKey = [NSNumber numberWithInt:minDepth].stringValue;
    NSArray *minDepthNodes = [nodeDepths valueForKey:minDepthKey];
    DLog(@" min depth nodes are: %@", minDepthNodes);
    SCNNode *skeletonRootNode = [minDepthNodes objectAtIndex:0];
    if (minDepthNodes.count > 1)
    {
        return skeletonRootNode.parentNode;
    }
    else
    {
        return skeletonRootNode;
    }
}

/**
 Finds the depth of the specified node from the scene's root node.

 @param node The scene node.
 @return The depth from the scene's root node.
 */
- (int)findDepthOfNodeFromRoot:(SCNNode *)node
{
    int depth = 0;
    SCNNode *pNode = node;
    while (pNode.parentNode)
    {
        depth += 1;
        pNode = pNode.parentNode;
    }
    return depth;
}

/**
 Finds the maximum number of weights that influence the vertices in the meshes
 of the specified node.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @return The maximum influences or weights.
 */
- (int)findMaxWeightsForNode:(const struct aiNode *)aiNode
                     inScene:(const struct aiScene *)aiScene
{
    int maxWeights = 0;

    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        NSMutableDictionary *meshWeights = [[NSMutableDictionary alloc] init];
        for (int j = 0; j < aiMesh->mNumBones; j++)
        {
            const struct aiBone *aiBone = aiMesh->mBones[j];
            for (int k = 0; k < aiBone->mNumWeights; k++)
            {
                const struct aiVertexWeight *aiVertexWeight =
                    &aiBone->mWeights[k];
                NSNumber *vertex =
                    [NSNumber numberWithInt:aiVertexWeight->mVertexId];
                if ([meshWeights valueForKey:vertex.stringValue] == nil)
                {
                    [meshWeights setValue:[NSNumber numberWithInt:1]
                                   forKey:vertex.stringValue];
                }
                else
                {
                    NSNumber *weightCounts =
                        [meshWeights valueForKey:vertex.stringValue];
                    [meshWeights
                        setValue:[NSNumber
                                     numberWithInt:(weightCounts.intValue + 1)]
                          forKey:vertex.stringValue];
                }
            }
        }

        // Find the vertex with most weights which is our max weights
        for (int j = 0; j < aiMesh->mNumVertices; j++)
        {
            NSNumber *vertex = [NSNumber numberWithInt:j];
            NSNumber *weightsCount =
                [meshWeights valueForKey:vertex.stringValue];
            if (weightsCount.intValue > maxWeights)
            {
                maxWeights = weightsCount.intValue;
            }
        }
    }

    return maxWeights;
}

/**
 Creates a scenekit geometry source defining the influence of each bone on the
 positions of vertices in the geometry

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @param nVertices The number of vertices in the meshes of the node.
 @param maxWeights The maximum number of weights influencing each vertex.
 @return A new geometry source whose semantic property is boneWeights.
 */
- (SCNGeometrySource *)
makeBoneWeightsGeometrySourceAtNode:(const struct aiNode *)aiNode
                            inScene:(const struct aiScene *)aiScene
                       withVertices:(int)nVertices
                         maxWeights:(int)maxWeights
{
    float nodeGeometryWeights[nVertices * maxWeights];
    int weightCounter = 0;

    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        NSMutableDictionary *meshWeights = [[NSMutableDictionary alloc] init];
        for (int j = 0; j < aiMesh->mNumBones; j++)
        {
            const struct aiBone *aiBone = aiMesh->mBones[j];
            for (int k = 0; k < aiBone->mNumWeights; k++)
            {
                const struct aiVertexWeight *aiVertexWeight =
                    &aiBone->mWeights[k];
                NSNumber *vertex =
                    [NSNumber numberWithInt:aiVertexWeight->mVertexId];
                NSNumber *weight =
                    [NSNumber numberWithFloat:aiVertexWeight->mWeight];
                if ([meshWeights valueForKey:vertex.stringValue] == nil)
                {
                    NSMutableArray *weights = [[NSMutableArray alloc] init];
                    [weights addObject:weight];
                    [meshWeights setValue:weights forKey:vertex.stringValue];
                }
                else
                {
                    NSMutableArray *weights =
                        [meshWeights valueForKey:vertex.stringValue];
                    [weights addObject:weight];
                }
            }
        }

        // Add weights to the weights array for the entire node geometry
        for (int j = 0; j < aiMesh->mNumVertices; j++)
        {
            NSNumber *vertex = [NSNumber numberWithInt:j];
            NSMutableArray *weights =
                [meshWeights valueForKey:vertex.stringValue];
            int zeroWeights = maxWeights - (int)weights.count;
            for (NSNumber *weight in weights)
            {
                nodeGeometryWeights[weightCounter++] = [weight floatValue];
                // DLog(@" adding weight: %f", weight.floatValue);
            }
            for (int k = 0; k < zeroWeights; k++)
            {
                nodeGeometryWeights[weightCounter++] = 0.0;
            }
        }
    }

    DLog(@" weight counter %d", weightCounter);
    assert(weightCounter == nVertices * maxWeights);

    SCNGeometrySource *boneWeightsSource = [SCNGeometrySource
        geometrySourceWithData:[NSData dataWithBytes:nodeGeometryWeights
                                              length:nVertices * maxWeights *
                                                     sizeof(float)]
                      semantic:SCNGeometrySourceSemanticBoneWeights
                   vectorCount:nVertices
               floatComponents:YES
           componentsPerVector:maxWeights
             bytesPerComponent:sizeof(float)
                    dataOffset:0
                    dataStride:maxWeights * sizeof(float)];
    return boneWeightsSource;
}

/**
 Creates a scenekit geometry source defining the mapping from bone indices in
 skeleton data to the skinner’s bones array

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @param nVertices The number of vertices in the meshes of the node.
 @param maxWeights The maximum number of weights influencing each vertex.
 @param boneNames The array of unique bone names.
 @return A new geometry source whose semantic property is boneIndices.
 */
- (SCNGeometrySource *)
makeBoneIndicesGeometrySourceAtNode:(const struct aiNode *)aiNode
                            inScene:(const struct aiScene *)aiScene
                       withVertices:(int)nVertices
                         maxWeights:(int)maxWeights
                          boneNames:(NSArray *)boneNames
{
    DLog(@" |--| Making bone indices geometry source: %@", boneNames);
    short nodeGeometryBoneIndices[nVertices * maxWeights];
    int indexCounter = 0;

    for (int i = 0; i < aiNode->mNumMeshes; i++)
    {
        int aiMeshIndex = aiNode->mMeshes[i];
        const struct aiMesh *aiMesh = aiScene->mMeshes[aiMeshIndex];
        NSMutableDictionary *meshBoneIndices =
            [[NSMutableDictionary alloc] init];
        for (int j = 0; j < aiMesh->mNumBones; j++)
        {
            const struct aiBone *aiBone = aiMesh->mBones[j];
            for (int k = 0; k < aiBone->mNumWeights; k++)
            {
                const struct aiVertexWeight *aiVertexWeight =
                    &aiBone->mWeights[k];
                NSNumber *vertex =
                    [NSNumber numberWithInt:aiVertexWeight->mVertexId];
                const struct aiString name = aiBone->mName;
                NSString *boneName = [NSString
                    stringWithUTF8String:(const char *_Nonnull) & name.data];
                NSNumber *boneIndex = [NSNumber
                    numberWithInteger:[boneNames indexOfObject:boneName]];
                if ([meshBoneIndices valueForKey:vertex.stringValue] == nil)
                {
                    NSMutableArray *boneIndices = [[NSMutableArray alloc] init];
                    [boneIndices addObject:boneIndex];
                    [meshBoneIndices setValue:boneIndices
                                       forKey:vertex.stringValue];
                }
                else
                {
                    NSMutableArray *boneIndices =
                        [meshBoneIndices valueForKey:vertex.stringValue];
                    [boneIndices addObject:boneIndex];
                }
            }
        }

        // Add bone indices to the indices array for the entire node geometry
        for (int j = 0; j < aiMesh->mNumVertices; j++)
        {
            NSNumber *vertex = [NSNumber numberWithInt:j];
            NSMutableArray *boneIndices =
                [meshBoneIndices valueForKey:vertex.stringValue];
            int zeroIndices = maxWeights - (int)boneIndices.count;
            for (NSNumber *boneIndex in boneIndices)
            {
                nodeGeometryBoneIndices[indexCounter++] =
                    [boneIndex shortValue];
                // DLog(@"  adding bone index: %d", boneIndex.shortValue);
            }
            for (int k = 0; k < zeroIndices; k++)
            {
                nodeGeometryBoneIndices[indexCounter++] = 0;
            }
        }
    }

    assert(indexCounter == nVertices * maxWeights);

    SCNGeometrySource *boneIndicesSource = [SCNGeometrySource
        geometrySourceWithData:[NSData dataWithBytes:nodeGeometryBoneIndices
                                              length:nVertices * maxWeights *
                                                     sizeof(short)]
                      semantic:SCNGeometrySourceSemanticBoneIndices
                   vectorCount:nVertices
               floatComponents:NO
           componentsPerVector:maxWeights
             bytesPerComponent:sizeof(short)
                    dataOffset:0
                    dataStride:maxWeights * sizeof(short)];
    return boneIndicesSource;
}

/**
 Builds a skeleton database of unique bone names and inverse bind bone
 transforms.

 When the scenekit scene is created from the assimp scene, a list of all bone
 names and a dictionary of bone transforms where each key is the bone name,
 is generated when parsing each node of the assimp scene.

 @param scene The scenekit scene.
 */
- (void)buildSkeletonDatabaseForScene:(SCNAssimpScene *)scene
{
    self.uniqueBoneNames = [[NSSet setWithArray:self.boneNames] allObjects];
    DLog(@" |--| bone names %lu: %@", self.boneNames.count, self.boneNames);
    DLog(@" |--| unique bone names %lu: %@", self.uniqueBoneNames.count,
         self.uniqueBoneNames);
    self.uniqueBoneNodes =
        [self findBoneNodesInScene:scene forBones:self.uniqueBoneNames];
    DLog(@" |--| unique bone nodes %lu: %@", self.uniqueBoneNodes.count,
         self.uniqueBoneNodes);
    self.uniqueBoneTransforms =
        [self getTransformsForBones:self.uniqueBoneNames
                     fromTransforms:self.boneTransforms];
    DLog(@" |--| unique bone transforms %lu: %@",
         self.uniqueBoneTransforms.count, self.uniqueBoneTransforms);
    self.skeleton = [self findSkeletonNodeFromBoneNodes:self.uniqueBoneNodes];
    [scene setSkeletonNode:self.skeleton];
    DLog(@" |--| skeleton bone is : %@", self.skeleton);
}

/**
 Creates a scenekit skinner for the specified node with visible geometry and
 skeleton information.

 @param aiNode The assimp node.
 @param aiScene The assimp scene.
 @param scene The scenekit scene.
 */
- (void)makeSkinnerForAssimpNode:(const struct aiNode *)aiNode
                         inScene:(const struct aiScene *)aiScene
                        scnScene:(SCNScene *)scene
{
    int nBones = [self findNumBonesInNode:aiNode inScene:aiScene];
    const struct aiString *aiNodeName = &aiNode->mName;
    NSString *nodeName = [NSString stringWithUTF8String:aiNodeName->data];
    if (nBones > 0)
    {
        int nVertices = [self findNumVerticesInNode:aiNode inScene:aiScene];
        int maxWeights = [self findMaxWeightsForNode:aiNode inScene:aiScene];
        DLog(@" |--| Making Skinner for node: %@ vertices: %d max-weights: %d "
             @"nBones: %d",
             nodeName, nVertices, maxWeights, nBones);

        SCNGeometrySource *boneWeights =
            [self makeBoneWeightsGeometrySourceAtNode:aiNode
                                              inScene:aiScene
                                         withVertices:nVertices
                                           maxWeights:maxWeights];
        SCNGeometrySource *boneIndices =
            [self makeBoneIndicesGeometrySourceAtNode:aiNode
                                              inScene:aiScene
                                         withVertices:nVertices
                                           maxWeights:maxWeights
                                            boneNames:self.uniqueBoneNames];

        SCNNode *node =
            [scene.rootNode childNodeWithName:nodeName recursively:YES];
        SCNSkinner *skinner =
            [SCNSkinner skinnerWithBaseGeometry:node.geometry
                                          bones:self.uniqueBoneNodes
                      boneInverseBindTransforms:self.uniqueBoneTransforms
                                    boneWeights:boneWeights
                                    boneIndices:boneIndices];
        skinner.skeleton = self.skeleton;
        DLog(@" assigned skinner %@ skeleton: %@", skinner, skinner.skeleton);
        node.skinner = skinner;
    }

    for (int i = 0; i < aiNode->mNumChildren; i++)
    {
        const struct aiNode *aiChildNode = aiNode->mChildren[i];
        [self makeSkinnerForAssimpNode:aiChildNode
                               inScene:aiScene
                              scnScene:scene];
    }
}

#pragma mark - Make scenekit animations

/**
 @name Make scenekit animations
 */

/**
 Creates a dictionary of animations where each animation is a
 SCNAssimpAnimation, from each animation in the assimp scene.

 For each animation's channel which is a bone node, a CAKeyframeAnimation is
 created for each of position, orientation and scale. These animations are
 then stored in an SCNAssimpAnimation object, which holds the animation name and
 the keyframe animations.

 The animation name is generated by appending the file name with an animation
 index. The example of an animation name is walk-1 for the first animation in a
 file named walk.

 @param aiScene The assimp scene.
 @param scene The scenekit scene.
 @param path The path to the scene file to load.
 */
- (void)createAnimationsFromScene:(const struct aiScene *)aiScene
                        withScene:(SCNAssimpScene *)scene
                           atPath:(NSString *)path
{
    DLog(@" ========= Number of animations in scene: %d",
         aiScene->mNumAnimations);
    for (int i = 0; i < aiScene->mNumAnimations; i++)
    {
        DLog(@"--- Animation data for animation at index: %d", i);
        const struct aiAnimation *aiAnimation = aiScene->mAnimations[i];
        NSString *animIndex = [@"-"
            stringByAppendingString:[NSNumber numberWithInt:i + 1].stringValue];
        NSString *animName = [[[path lastPathComponent]
            stringByDeletingPathExtension] stringByAppendingString:animIndex];
        DLog(@" Generated animation name: %@", animName);
        NSMutableDictionary *currentAnimation =
            [[NSMutableDictionary alloc] init];
        DLog(@" This animation %@ has %d channels with duration %f ticks "
             @"per sec: %f",
             animName, aiAnimation->mNumChannels, aiAnimation->mDuration,
             aiAnimation->mTicksPerSecond);
        float duration;
        if (aiAnimation->mTicksPerSecond != 0)
        {
            duration = aiAnimation->mDuration / aiAnimation->mTicksPerSecond;
        }
        else
        {
            duration = aiAnimation->mDuration;
        }
        for (int j = 0; j < aiAnimation->mNumChannels; j++)
        {
            const struct aiNodeAnim *aiNodeAnim = aiAnimation->mChannels[j];
            const struct aiString *aiNodeName = &aiNodeAnim->mNodeName;
            NSString *name = [NSString stringWithUTF8String:aiNodeName->data];
            DLog(@" The channel %@ has data for %d position, %d rotation, "
                 @"%d scale "
                 @"keyframes",
                 name, aiNodeAnim->mNumPositionKeys,
                 aiNodeAnim->mNumRotationKeys, aiNodeAnim->mNumScalingKeys);

            // create a lookup for all animation keys
            NSMutableDictionary *channelKeys =
                [[NSMutableDictionary alloc] init];

            // create translation animation
            NSMutableArray *translationValues = [[NSMutableArray alloc] init];
            NSMutableArray *translationTimes = [[NSMutableArray alloc] init];
            for (int k = 0; k < aiNodeAnim->mNumPositionKeys; k++)
            {
                const struct aiVectorKey *aiTranslationKey =
                    &aiNodeAnim->mPositionKeys[k];
                double keyTime = aiTranslationKey->mTime;
                const struct aiVector3D aiTranslation =
                    aiTranslationKey->mValue;
                [translationTimes addObject:[NSNumber numberWithFloat:keyTime]];
                SCNVector3 pos = SCNVector3Make(
                    aiTranslation.x, aiTranslation.y, aiTranslation.z);
                [translationValues addObject:[NSValue valueWithSCNVector3:pos]];
            }
            CAKeyframeAnimation *translationKeyFrameAnim =
                [CAKeyframeAnimation animationWithKeyPath:@"position"];
            translationKeyFrameAnim.values = translationValues;
            translationKeyFrameAnim.keyTimes = translationTimes;
            translationKeyFrameAnim.duration = duration;
            [channelKeys setValue:translationKeyFrameAnim forKey:@"position"];

            // create rotation animation
            NSMutableArray *rotationValues = [[NSMutableArray alloc] init];
            NSMutableArray *rotationTimes = [[NSMutableArray alloc] init];
            for (int k = 0; k < aiNodeAnim->mNumRotationKeys; k++)
            {
                const struct aiQuatKey *aiQuatKey =
                    &aiNodeAnim->mRotationKeys[k];
                double keyTime = aiQuatKey->mTime;
                const struct aiQuaternion aiQuaternion = aiQuatKey->mValue;
                [rotationTimes addObject:[NSNumber numberWithFloat:keyTime]];
                SCNVector4 quat =
                    SCNVector4Make(aiQuaternion.x, aiQuaternion.y,
                                   aiQuaternion.z, aiQuaternion.w);
                [rotationValues addObject:[NSValue valueWithSCNVector4:quat]];
            }
            CAKeyframeAnimation *rotationKeyFrameAnim =
                [CAKeyframeAnimation animationWithKeyPath:@"orientation"];
            rotationKeyFrameAnim.values = rotationValues;
            rotationKeyFrameAnim.keyTimes = rotationTimes;
            rotationKeyFrameAnim.duration = duration;
            [channelKeys setValue:rotationKeyFrameAnim forKey:@"orientation"];

            // create scale animation
            NSMutableArray *scaleValues = [[NSMutableArray alloc] init];
            NSMutableArray *scaleTimes = [[NSMutableArray alloc] init];
            for (int k = 0; k < aiNodeAnim->mNumScalingKeys; k++)
            {
                const struct aiVectorKey *aiScaleKey =
                    &aiNodeAnim->mScalingKeys[k];
                double keyTime = aiScaleKey->mTime;
                const struct aiVector3D aiScale = aiScaleKey->mValue;
                [scaleTimes addObject:[NSNumber numberWithFloat:keyTime]];
                SCNVector3 scale =
                    SCNVector3Make(aiScale.x, aiScale.y, aiScale.z);
                [scaleValues addObject:[NSValue valueWithSCNVector3:scale]];
            }
            CAKeyframeAnimation *scaleKeyFrameAnim =
                [CAKeyframeAnimation animationWithKeyPath:@"scale"];
            scaleKeyFrameAnim.values = scaleValues;
            scaleKeyFrameAnim.keyTimes = scaleTimes;
            scaleKeyFrameAnim.duration = duration;
            [channelKeys setValue:scaleKeyFrameAnim forKey:@"scale"];

            [currentAnimation setValue:channelKeys forKey:name];
        }

        SCNAssimpAnimation *animation =
            [[SCNAssimpAnimation alloc] initWithKey:animName
                                         frameAnims:currentAnimation];
        [scene.animations setValue:animation forKey:animName];
    }
}

@end
