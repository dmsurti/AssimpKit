//
//  SCNScene+AssimpImport.m
//  AssimpKit
//
//  Created by Deepak Surti on 10/24/16.
//
//

#import "SCNScene+AssimpImport.h"
#include "assimp/cimport.h"  // Plain-C interface
#include "assimp/material.h"
#include "assimp/postprocess.h"  // Post processing flags
#include "assimp/scene.h"        // Output data structure

@implementation SCNScene (AssimpImport)

#pragma mark - Loading a Scene

+ (instancetype)assimpSceneNamed:(NSString*)name {
  NSString* file = [[NSBundle mainBundle] pathForResource:name ofType:nil];
  return [self importScene:file];
}

+ (instancetype)assimpSceneWithURL:(NSURL*)url {
  return [self importScene:url.path];
}

#pragma mark - Import with Assimp

+ (instancetype)importScene:(NSString*)filePath {
  // Start the import on the given file with some example postprocessing
  // Usually - if speed is not the most important aspect for you - you'll t
  // probably to request more postprocessing than we do in this example.
  const char* pFile = [filePath UTF8String];
  const struct aiScene* aiScene = aiImportFile(pFile, aiProcess_FlipUVs);
  // If the import failed, report it
  if (!aiScene) {
    NSLog(@" Scene importing failed for filePath %@", filePath);
    return nil;
  }
  // Now we can access the file's contents
  SCNScene* scene = [self makeSCNSceneFromAssimpScene:aiScene atPath:filePath];
  // We're done. Release all resources associated with this import
  aiReleaseImport(aiScene);
  return scene;
}

#pragma mark - Make SCN Scene

+ (instancetype)makeSCNSceneFromAssimpScene:(const struct aiScene*)aiScene
                                     atPath:(NSString*)path {
  NSLog(@" Make an SCNScene");
  const struct aiNode* aiRootNode = aiScene->mRootNode;
  SCNScene* scene = [[[self class] alloc] init];
  SCNNode* scnRootNode =
      [self makeSCNNodeFromAssimpNode:aiRootNode inScene:aiScene atPath:path];
  [scene.rootNode addChildNode:scnRootNode];
  return scene;
}

#pragma mark - Make SCN Node

+ (SCNNode*)makeSCNNodeFromAssimpNode:(const struct aiNode*)aiNode
                              inScene:(const struct aiScene*)aiScene
                               atPath:(NSString*)path {
  SCNNode* node = [[SCNNode alloc] init];
  const struct aiString* aiNodeName = &aiNode->mName;
  node.name = [NSString stringWithUTF8String:aiNodeName->data];
  NSLog(@" Creating node %@ with %d meshes", node.name, aiNode->mNumMeshes);
  node.geometry =
      [self makeSCNGeometryFromAssimpNode:aiNode inScene:aiScene atPath:path];

  // ---------
  // TRANSFORM
  // ---------
  const struct aiMatrix4x4 aiNodeMatrix = aiNode->mTransformation;
  // May be I should not ignore scale, rotation components and use
  // full matrix
  //  GLKMatrix4 glkNodeMatrix = GLKMatrix4Make(
  //      aiNodeMatrix.a1, aiNodeMatrix.b1, aiNodeMatrix.c1, aiNodeMatrix.d1,
  //      aiNodeMatrix.a2, aiNodeMatrix.b2, aiNodeMatrix.c2, aiNodeMatrix.d2,
  //      aiNodeMatrix.a3, aiNodeMatrix.b3, aiNodeMatrix.c3, aiNodeMatrix.d3,
  //      aiNodeMatrix.a4, aiNodeMatrix.b4, aiNodeMatrix.c4, aiNodeMatrix.d4);

  GLKMatrix4 glkNodeMatrix =
      GLKMatrix4Make(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, aiNodeMatrix.a4,
                     aiNodeMatrix.b4, aiNodeMatrix.c4, aiNodeMatrix.d4);
  SCNMatrix4 scnMatrix = SCNMatrix4FromGLKMatrix4(glkNodeMatrix);
  node.transform = scnMatrix;

  for (int i = 0; i < aiNode->mNumChildren; i++) {
    const struct aiNode* aiChildNode = aiNode->mChildren[i];
    SCNNode* childNode = [self makeSCNNodeFromAssimpNode:aiChildNode
                                                 inScene:aiScene
                                                  atPath:path];
    [node addChildNode:childNode];
  }
  return node;
}

#pragma mark - Number of vertices, faces and indices

+ (int)findNumVerticesInNode:(const struct aiNode*)aiNode
                     inScene:(const struct aiScene*)aiScene {
  int nVertices = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    nVertices += aiMesh->mNumVertices;
  }
  return nVertices;
}

+ (int)findNumFacesInNode:(const struct aiNode*)aiNode
                  inScene:(const struct aiScene*)aiScene {
  int nFaces = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    nFaces += aiMesh->mNumFaces;
  }
  return nFaces;
}

+ (int)findNumIndicesInMesh:(int)aiMeshIndex
                    inScene:(const struct aiScene*)aiScene {
  int nIndices = 0;
  const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
  for (int j = 0; j < aiMesh->mNumFaces; j++) {
    const struct aiFace* aiFace = &aiMesh->mFaces[j];
    nIndices += aiFace->mNumIndices;
  }
  return nIndices;
}

#pragma mark - Make SCN Geometry sources

+ (SCNGeometrySource*)
makeVertexGeometrySourceForNode:(const struct aiNode*)aiNode
                        inScene:(const struct aiScene*)aiScene
                  withNVertices:(int)nVertices {
  float scnVertices[nVertices * 3];
  int verticesCounter = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    // create SCNGeometry source for aiMesh vertices, normals, texture
    // coordinates
    for (int j = 0; j < aiMesh->mNumVertices; j++) {
      const struct aiVector3D* aiVector3D = &aiMesh->mVertices[j];
      scnVertices[verticesCounter++] = aiVector3D->x;
      scnVertices[verticesCounter++] = aiVector3D->y;
      scnVertices[verticesCounter++] = aiVector3D->z;
    }
  }
  SCNGeometrySource* vertexSource = [SCNGeometrySource
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
  return vertexSource;
}

+ (SCNGeometrySource*)
makeNormalGeometrySourceForNode:(const struct aiNode*)aiNode
                        inScene:(const struct aiScene*)aiScene
                  withNVertices:(int)nVertices {
  float scnNormals[nVertices * 3];
  int verticesCounter = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    if (aiMesh->mNormals != NULL) {
      for (int j = 0; j < aiMesh->mNumVertices; j++) {
        const struct aiVector3D* aiVector3D = &aiMesh->mNormals[j];
        scnNormals[verticesCounter++] = aiVector3D->x;
        scnNormals[verticesCounter++] = aiVector3D->y;
        scnNormals[verticesCounter++] = aiVector3D->z;
      }
    }
  }
  SCNGeometrySource* normalSource = [SCNGeometrySource
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
  return normalSource;
}

+ (SCNGeometrySource*)
makeTextureGeometrySourceForNode:(const struct aiNode*)aiNode
                         inScene:(const struct aiScene*)aiScene
                   withNVertices:(int)nVertices {
  float scnTextures[nVertices * 2];
  int verticesCounter = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    if (aiMesh->mTextureCoords != NULL) {
      NSLog(@" Getting texture coordinates");
      for (int j = 0; j < aiMesh->mNumVertices; j++) {
        float x = aiMesh->mTextureCoords[0][j].x;
        float y = aiMesh->mTextureCoords[0][j].y;
        scnTextures[verticesCounter++] = x;
        scnTextures[verticesCounter++] = y;
      }
    }
  }
  SCNGeometrySource* textureSource = [SCNGeometrySource
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
  return textureSource;
}

+ (NSArray*)makeGeometrySourcesForNode:(const struct aiNode*)aiNode
                               inScene:(const struct aiScene*)aiScene {
  NSMutableArray* scnGeometrySources = [[NSMutableArray alloc] init];
  int nVertices = [self findNumVerticesInNode:aiNode inScene:aiScene];
  [scnGeometrySources
      addObject:[self makeVertexGeometrySourceForNode:aiNode
                                              inScene:aiScene
                                        withNVertices:nVertices]];
  [scnGeometrySources
      addObject:[self makeNormalGeometrySourceForNode:aiNode
                                              inScene:aiScene
                                        withNVertices:nVertices]];
  [scnGeometrySources
      addObject:[self makeTextureGeometrySourceForNode:aiNode
                                               inScene:aiScene
                                         withNVertices:nVertices]];
  return scnGeometrySources;
}

#pragma mark - Make SCN Geometry elements

+ (SCNGeometryElement*)
makeIndicesGeometryElementForMeshIndex:(int)aiMeshIndex
                                inNode:(const struct aiNode*)aiNode
                               inScene:(const struct aiScene*)aiScene
                       withIndexOffset:(int)indexOffset
                                nFaces:(int)nFaces {
  int indicesCounter = 0;
  int nIndices = [self findNumIndicesInMesh:aiMeshIndex inScene:aiScene];
  int scnIndices[nIndices];
  const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
  for (int i = 0; i < aiMesh->mNumFaces; i++) {
    const struct aiFace* aiFace = &aiMesh->mFaces[i];
    for (int j = 0; j < aiFace->mNumIndices; j++) {
      scnIndices[indicesCounter++] = indexOffset + aiFace->mIndices[j];
    }
  }
  indexOffset += aiMesh->mNumVertices;
  NSData* indicesData =
      [NSData dataWithBytes:scnIndices length:sizeof(scnIndices)];
  SCNGeometryElement* indices = [SCNGeometryElement
      geometryElementWithData:indicesData
                primitiveType:SCNGeometryPrimitiveTypeTriangles
               primitiveCount:nFaces
                bytesPerIndex:sizeof(int)];
  return indices;
}

+ (NSArray*)makeGeometryElementsforNode:(const struct aiNode*)aiNode
                                inScene:(const struct aiScene*)aiScene {
  NSMutableArray* scnGeometryElements = [[NSMutableArray alloc] init];
  int nFaces = [self findNumFacesInNode:aiNode inScene:aiScene];
  int indexOffset = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    SCNGeometryElement* indices =
        [self makeIndicesGeometryElementForMeshIndex:aiMeshIndex
                                              inNode:aiNode
                                             inScene:aiScene
                                     withIndexOffset:indexOffset
                                              nFaces:nFaces];
    [scnGeometryElements addObject:indices];
    indexOffset += aiMesh->mNumVertices;
  }

  return scnGeometryElements;
}

#pragma mark - Make Materials

+ (void)makeMaterialPropertyForMaterial:(const struct aiMaterial*)aiMaterial
                        withTextureType:(enum aiTextureType)aiTextureType
                        withSCNMaterial:(SCNMaterial*)material
                                 atPath:(NSString*)path {
  int nTextures = aiGetMaterialTextureCount(aiMaterial, aiTextureType);
  if (nTextures > 0) {
    NSLog(@" has %d textures", nTextures);
    struct aiString aiPath;
    aiGetMaterialTexture(aiMaterial, aiTextureType, 0, &aiPath, NULL, NULL,
                         NULL, NULL, NULL, NULL);
    NSString* texFileName = [NSString stringWithUTF8String:&aiPath.data];
    NSString* sceneDir =
        [[path stringByDeletingLastPathComponent] stringByAppendingString:@"/"];
    NSString* texPath = [sceneDir
        stringByAppendingString:[NSString stringWithUTF8String:&aiPath.data]];

    NSString* channel = @".mappingChannel";
    NSString* wrapS = @".wrapS";
    NSString* wrapT = @".wrapS";
    NSString* intensity = @".intensity";
    NSString* minFilter = @".minificationFilter";
    NSString* magFilter = @".magnificationFilter";

    NSString* keyPrefix = @"";
    if (aiTextureType == aiTextureType_DIFFUSE) {
      material.diffuse.contents = texPath;
      keyPrefix = @"diffuse";
    } else if (aiTextureType == aiTextureType_SPECULAR) {
      material.specular.contents = texPath;
      keyPrefix = @"specular";
    } else if (aiTextureType == aiTextureType_AMBIENT) {
      material.specular.contents = texPath;
      keyPrefix = @"ambient";
    } else if (aiTextureType == aiTextureType_REFLECTION) {
      material.specular.contents = texPath;
      keyPrefix = @"reflective";
    } else if (aiTextureType == aiTextureType_EMISSIVE) {
      material.specular.contents = texPath;
      keyPrefix = @"emissive";
    } else if (aiTextureType == aiTextureType_OPACITY) {
      material.specular.contents = texPath;
      keyPrefix = @"transparent";
    } else if (aiTextureType == aiTextureType_NORMALS) {
      material.specular.contents = texPath;
      keyPrefix = @"normal";
    }

    // Update the keys
    channel = [keyPrefix stringByAppendingString:channel];
    wrapS = [keyPrefix stringByAppendingString:wrapS];
    wrapT = [keyPrefix stringByAppendingString:wrapT];
    intensity = [keyPrefix stringByAppendingString:intensity];
    minFilter = [keyPrefix stringByAppendingString:minFilter];
    magFilter = [keyPrefix stringByAppendingString:magFilter];

    [material setValue:0 forKey:channel];
    [material setValue:[NSNumber numberWithInt:SCNWrapModeRepeat] forKey:wrapS];
    [material setValue:[NSNumber numberWithInt:SCNWrapModeRepeat] forKey:wrapT];
    [material setValue:[NSNumber numberWithInt:1] forKey:intensity];
    [material setValue:[NSNumber numberWithInt:SCNFilterModeLinear]
                forKey:minFilter];
    [material setValue:[NSNumber numberWithInt:SCNFilterModeLinear]
                forKey:magFilter];
    material.blendMode = SCNBlendModeAlpha;
  } else {
    NSLog(@" has color");
    struct aiColor4D color;
    color.r = 0.0f;
    color.g = 0.0f;
    color.b = 0.0f;
    int matColor = -100;
    NSString* key = @"";
    if (aiTextureType == aiTextureType_DIFFUSE) {
      matColor =
          aiGetMaterialColor(aiMaterial, AI_MATKEY_COLOR_DIFFUSE, &color);
      key = @"diffuse.contents";
    } else if (aiTextureType == aiTextureType_SPECULAR) {
      matColor =
          aiGetMaterialColor(aiMaterial, AI_MATKEY_COLOR_SPECULAR, &color);
      key = @"specular.contents";
    } else if (aiTextureType == aiTextureType_AMBIENT) {
      matColor =
          aiGetMaterialColor(aiMaterial, AI_MATKEY_COLOR_AMBIENT, &color);
      key = @"ambient.contents";
    } else if (aiTextureType == aiTextureType_REFLECTION) {
      matColor =
          aiGetMaterialColor(aiMaterial, AI_MATKEY_COLOR_REFLECTIVE, &color);
      key = @"reflective.contents";
    } else if (aiTextureType == aiTextureType_EMISSIVE) {
      matColor =
          aiGetMaterialColor(aiMaterial, AI_MATKEY_COLOR_EMISSIVE, &color);
      key = @"emissive.contents";
    } else if (aiTextureType == aiTextureType_OPACITY) {
      matColor =
          aiGetMaterialColor(aiMaterial, AI_MATKEY_COLOR_TRANSPARENT, &color);
      key = @"transparent.contents";
    }
    if (AI_SUCCESS == matColor) {
#if TARGET_OS_IPHONE
      [material setValue:[UIColor colorWithRed:color.r
                                         green:color.g
                                          blue:color.b
                                         alpha:color.a]
                  forKey:key];
#else
      [material setValue:[NSColor colorWithRed:color.r
                                         green:color.g
                                          blue:color.b
                                         alpha:color.a]
                  forKey:key];

#endif
    }
  }
}

+ (void)applyMultiplyPropertyForMaterial:(const struct aiMaterial*)aiMaterial
                         withSCNMaterial:(SCNMaterial*)material
                                  atPath:(NSString*)path {
  struct aiColor4D color;
  color.r = 0.0f;
  color.g = 0.0f;
  color.b = 0.0f;
  int matColor = -100;
  matColor =
      aiGetMaterialColor(aiMaterial, AI_MATKEY_COLOR_TRANSPARENT, &color);
  NSString* key = @"multiply.contents";
  if (AI_SUCCESS == matColor) {
#if TARGET_OS_IPHONE
    [material setValue:[UIColor colorWithRed:color.r
                                       green:color.g
                                        blue:color.b
                                       alpha:color.a]
                forKey:key];
#else
    [material setValue:[NSColor colorWithRed:color.r
                                       green:color.g
                                        blue:color.b
                                       alpha:color.a]
                forKey:key];

#endif
  }
}

+ (NSMutableArray*)makeMaterialsForNode:(const struct aiNode*)aiNode
                                inScene:(const struct aiScene*)aiScene
                                 atPath:(NSString*)path {
  NSMutableArray* scnMaterials = [[NSMutableArray alloc] init];
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    const struct aiMaterial* aiMaterial =
        aiScene->mMaterials[aiMesh->mMaterialIndex];
    struct aiString name;
    aiGetMaterialString(aiMaterial, AI_MATKEY_NAME, &name);
    NSLog(@" Material name is %@", [NSString stringWithUTF8String:&name.data]);
    SCNMaterial* material = [SCNMaterial material];
    NSLog(@"+++ Loading diffuse");
    [self makeMaterialPropertyForMaterial:aiMaterial
                          withTextureType:aiTextureType_DIFFUSE
                          withSCNMaterial:material
                                   atPath:path];
    NSLog(@"+++ Loading specular");
    [self makeMaterialPropertyForMaterial:aiMaterial
                          withTextureType:aiTextureType_SPECULAR
                          withSCNMaterial:material
                                   atPath:path];
    NSLog(@"+++ Loading ambient");
    [self makeMaterialPropertyForMaterial:aiMaterial
                          withTextureType:aiTextureType_AMBIENT
                          withSCNMaterial:material
                                   atPath:path];
    NSLog(@"+++ Loading reflective");
    [self makeMaterialPropertyForMaterial:aiMaterial
                          withTextureType:aiTextureType_REFLECTION
                          withSCNMaterial:material
                                   atPath:path];
    NSLog(@"+++ Loading emissive");
    [self makeMaterialPropertyForMaterial:aiMaterial
                          withTextureType:aiTextureType_EMISSIVE
                          withSCNMaterial:material
                                   atPath:path];
    NSLog(@"+++ Loading transparent");
    [self makeMaterialPropertyForMaterial:aiMaterial
                          withTextureType:aiTextureType_OPACITY
                          withSCNMaterial:material
                                   atPath:path];
    NSLog(@"+++ Loading ambient occlusion");
    [self makeMaterialPropertyForMaterial:aiMaterial
                          withTextureType:aiTextureType_LIGHTMAP
                          withSCNMaterial:material
                                   atPath:path];
    NSLog(@"+++ Loading multiply color");
    [self applyMultiplyPropertyForMaterial:aiMaterial
                           withSCNMaterial:material
                                    atPath:path];
    [scnMaterials addObject:material];
  }
  return scnMaterials;
}

+ (SCNGeometry*)makeSCNGeometryFromAssimpNode:(const struct aiNode*)aiNode
                                      inScene:(const struct aiScene*)aiScene
                                       atPath:(NSString*)path {
  // make SCNGeometry with sources, elements and materials
  NSArray* scnGeometrySources =
      [self makeGeometrySourcesForNode:aiNode inScene:aiScene];
  if (scnGeometrySources.count > 0) {
    NSArray* scnGeometryElements =
        [self makeGeometryElementsforNode:aiNode inScene:aiScene];
    SCNGeometry* scnGeometry =
        [SCNGeometry geometryWithSources:scnGeometrySources
                                elements:scnGeometryElements];
    NSArray* scnMaterials =
        [self makeMaterialsForNode:aiNode inScene:aiScene atPath:path];
    if (scnMaterials.count > 0) {
      scnGeometry.materials = scnMaterials;
      scnGeometry.firstMaterial = [scnMaterials objectAtIndex:0];
    }
    return scnGeometry;
  }
  return nil;
}

@end
