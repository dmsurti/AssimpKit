//
//  AssimpImporter.m
//  AssimpKit
//
//  Created by Deepak Surti on 10/27/16.
//
//

#import "AssimpImporter.h"
#import "SCNAssimpAnimNode.h"
#import "SCNAssimpScene.h"
#include "assimp/cimport.h"      // Plain-C interface
#include "assimp/light.h"        // Lights
#include "assimp/material.h"     // Materials
#include "assimp/postprocess.h"  // Post processing flags
#include "assimp/scene.h"        // Output data structure

@interface AssimpImporter ()

@property(readwrite, nonatomic) NSMutableArray* boneNames;
@property(readwrite, nonatomic) NSArray* uniqueBoneNames;
@property(readwrite, nonatomic) NSArray* uniqueBoneNodes;
@property(readwrite, nonatomic) NSMutableDictionary* boneTransforms;
@property(readwrite, nonatomic) NSArray* uniqueBoneTransforms;
@property(readwrite, nonatomic) SCNNode* skelton;

@end

@implementation AssimpImporter

- (id)init {
  self = [super init];
  if (self) {
    self.boneNames = [[NSMutableArray alloc] init];
    self.boneTransforms = [[NSMutableDictionary alloc] init];
    return self;
  }
  return nil;
}

#pragma mark - Import with Assimp

- (SCNScene*)importScene:(NSString*)filePath {
  // Start the import on the given file with some example postprocessing
  // Usually - if speed is not the most important aspect for you - you'll t
  // probably to request more postprocessing than we do in this example.
  const char* pFile = [filePath UTF8String];
  const struct aiScene* aiScene = aiImportFile(
      pFile, aiProcess_FlipUVs | aiProcessPreset_TargetRealtime_MaxQuality);
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

- (SCNScene*)makeSCNSceneFromAssimpScene:(const struct aiScene*)aiScene
                                  atPath:(NSString*)path {
  NSLog(@" Make an SCNScene");
  const struct aiNode* aiRootNode = aiScene->mRootNode;
  SCNAssimpScene* scene = [[SCNAssimpScene alloc] init];
  /*
   -------------------------------------------------------------------
   Assign geometry, materials, lights and cameras to the node
   ---------------------------------------------------------------------
   */
  SCNNode* scnRootNode =
      [self makeSCNNodeFromAssimpNode:aiRootNode inScene:aiScene atPath:path];
  [scene.rootNode addChildNode:scnRootNode];
  /*
   ---------------------------------------------------------------------
   Animations and skinning
   ---------------------------------------------------------------------
   */
  [self buildSkeletonDatabaseForScene:scene];
  [self makeSkinnerForAssimpNode:aiRootNode inScene:aiScene scnScene:scene];
  [self loadAnimationsFromScene:aiScene];

  return scene;
}

#pragma mark - Make SCN Node

- (SCNNode*)makeSCNNodeFromAssimpNode:(const struct aiNode*)aiNode
                              inScene:(const struct aiScene*)aiScene
                               atPath:(NSString*)path {
  SCNNode* node = [[SCNNode alloc] init];
  const struct aiString* aiNodeName = &aiNode->mName;
  node.name = [NSString stringWithUTF8String:aiNodeName->data];
  NSLog(@" Creating node %@ with %d meshes", node.name, aiNode->mNumMeshes);
  int nVertices = [self findNumVerticesInNode:aiNode inScene:aiScene];
  node.geometry = [self makeSCNGeometryFromAssimpNode:aiNode
                                              inScene:aiScene
                                         withVertices:nVertices
                                               atPath:path];
  node.light = [self makeSCNLightFromAssimpNode:aiNode inScene:aiScene];
  node.camera = [self makeSCNCameraFromAssimpNode:aiNode inScene:aiScene];
  [self.boneNames addObjectsFromArray:[self getBoneNamesForAssimpNode:aiNode
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
  NSLog(@" Node %@ position %f %f %f", node.name, aiNodeMatrix.a4,
        aiNodeMatrix.b4, aiNodeMatrix.c4);

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

- (int)findNumVerticesInNode:(const struct aiNode*)aiNode
                     inScene:(const struct aiScene*)aiScene {
  int nVertices = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    nVertices += aiMesh->mNumVertices;
  }
  return nVertices;
}

- (int)findNumFacesInNode:(const struct aiNode*)aiNode
                  inScene:(const struct aiScene*)aiScene {
  int nFaces = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    nFaces += aiMesh->mNumFaces;
  }
  return nFaces;
}

- (int)findNumIndicesInMesh:(int)aiMeshIndex
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

- (SCNGeometrySource*)
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

- (SCNGeometrySource*)
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

- (SCNGeometrySource*)
makeTextureGeometrySourceForNode:(const struct aiNode*)aiNode
                         inScene:(const struct aiScene*)aiScene
                   withNVertices:(int)nVertices {
  float scnTextures[nVertices * 2];
  int verticesCounter = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    if (aiMesh->mTextureCoords[0] != NULL) {
      NSLog(@"  Getting texture coordinates");
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

- (NSArray*)makeGeometrySourcesForNode:(const struct aiNode*)aiNode
                               inScene:(const struct aiScene*)aiScene
                          withVertices:(int)nVertices {
  NSMutableArray* scnGeometrySources = [[NSMutableArray alloc] init];
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

- (SCNGeometryElement*)
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

- (NSArray*)makeGeometryElementsforNode:(const struct aiNode*)aiNode
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

- (void)makeMaterialPropertyForMaterial:(const struct aiMaterial*)aiMaterial
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
    NSLog(@"  tex path is %@", texPath);

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
    } else if (aiTextureType == aiTextureType_LIGHTMAP) {
      material.specular.contents = texPath;
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
    [material setValue:[NSNumber numberWithInt:SCNWrapModeRepeat] forKey:wrapS];
    [material setValue:[NSNumber numberWithInt:SCNWrapModeRepeat] forKey:wrapT];
    [material setValue:[NSNumber numberWithInt:1] forKey:intensity];
    [material setValue:[NSNumber numberWithInt:SCNFilterModeLinear]
                forKey:minFilter];
    [material setValue:[NSNumber numberWithInt:SCNFilterModeLinear]
                forKey:magFilter];
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
      CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
      CGFloat components[4] = {color.r, color.g, color.b, color.a};
      CGColorRef color = CGColorCreate(space, components);
      [material setValue:(__bridge id _Nullable)color forKey:key];
      CGColorSpaceRelease(space);
      CGColorRelease(color);
    }
  }
}

- (void)applyMultiplyPropertyForMaterial:(const struct aiMaterial*)aiMaterial
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
    if (color.r != 0 && color.g != 0 && color.b != 0) {
      CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
      CGFloat components[4] = {color.r, color.g, color.b, color.a};
      CGColorRef color = CGColorCreate(space, components);
      material.multiply.contents = (__bridge id _Nullable)(color);
      CGColorSpaceRelease(space);
      CGColorRelease(color);
    }
  }
}

- (NSMutableArray*)makeMaterialsForNode:(const struct aiNode*)aiNode
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
    NSLog(@"+++ Loading blend mode");
    int blendMode = 0;
    int* max;
    aiGetMaterialIntegerArray(aiMaterial, AI_MATKEY_BLEND_FUNC,
                              (int*)&blendMode, max);
    if (blendMode == aiBlendMode_Default) {
      NSLog(@" Using alpha blend mode");
      material.blendMode = SCNBlendModeAlpha;
    } else if (blendMode == aiBlendMode_Additive) {
      NSLog(@" Using add blend mode");
      material.blendMode = SCNBlendModeAdd;
    }
    NSLog(@"+++ Loading cull/double sided mode");
    /**
     FIXME: The cull mode works only on iOS. Not on OSX.
     Hence has been defaulted to Cull Back.
     USE AI_MATKEY_TWOSIDED to get the cull mode.
     */
    material.cullMode = SCNCullBack;
    NSLog(@"+++ Loading shininess");
    float shininess = 0.0;
    aiGetMaterialIntegerArray(aiMaterial, AI_MATKEY_BLEND_FUNC,
                              (float*)&shininess, max);
    NSLog(@"   shininess: %f", shininess);
    material.shininess = shininess;
    NSLog(@"+++ Loading shading model");
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

- (SCNGeometry*)makeSCNGeometryFromAssimpNode:(const struct aiNode*)aiNode
                                      inScene:(const struct aiScene*)aiScene
                                 withVertices:(int)nVertices
                                       atPath:(NSString*)path {
  // make SCNGeometry with sources, elements and materials
  NSArray* scnGeometrySources = [self makeGeometrySourcesForNode:aiNode
                                                         inScene:aiScene
                                                    withVertices:nVertices];
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

#pragma mark - Make Lights

- (SCNLight*)makeSCNLightTypeDirectionalForAssimpLight:
    (const struct aiLight*)aiLight {
  SCNLight* light = [SCNLight light];
  light.type = SCNLightTypeDirectional;
  const struct aiColor3D aiColor = aiLight->mColorSpecular;
  if (aiColor.r != 0 && aiColor.g != 0 && aiColor.b != 0) {
    NSLog(@" Setting color: %f %f %f", aiColor.r, aiColor.g, aiColor.b);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGFloat components[4] = {aiColor.r, aiColor.g, aiColor.b, 1.0};
    CGColorRef cgGolor = CGColorCreate(space, components);
    light.color = (__bridge id _Nullable)(cgGolor);
    CGColorSpaceRelease(space);
    CGColorRelease(cgGolor);
  }
  return light;
}

- (SCNLight*)makeSCNLightTypePointForAssimpLight:
    (const struct aiLight*)aiLight {
  SCNLight* light = [SCNLight light];
  light.type = SCNLightTypeOmni;
  const struct aiColor3D aiColor = aiLight->mColorSpecular;
  if (aiColor.r != 0 && aiColor.g != 0 && aiColor.b != 0) {
    NSLog(@" Setting color: %f %f %f", aiColor.r, aiColor.g, aiColor.b);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGFloat components[4] = {aiColor.r, aiColor.g, aiColor.b, 1.0};
    CGColorRef cgGolor = CGColorCreate(space, components);
    light.color = (__bridge id _Nullable)(cgGolor);
    CGColorSpaceRelease(space);
    CGColorRelease(cgGolor);
  }
  if (aiLight->mAttenuationQuadratic != 0) {
    light.attenuationFalloffExponent = 2.0;
  } else if (aiLight->mAttenuationLinear != 0) {
    light.attenuationFalloffExponent = 1.0;
  }
  return light;
}

- (SCNLight*)makeSCNLightTypeSpotForAssimpLight:(const struct aiLight*)aiLight {
  SCNLight* light = [SCNLight light];
  light.type = SCNLightTypeOmni;
  const struct aiColor3D aiColor = aiLight->mColorSpecular;
  if (aiColor.r != 0 && aiColor.g != 0 && aiColor.b != 0) {
    NSLog(@" Setting color: %f %f %f", aiColor.r, aiColor.g, aiColor.b);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGFloat components[4] = {aiColor.r, aiColor.g, aiColor.b, 1.0};
    CGColorRef cgGolor = CGColorCreate(space, components);
    light.color = (__bridge id _Nullable)(cgGolor);
    CGColorSpaceRelease(space);
    CGColorRelease(cgGolor);
  }
  if (aiLight->mAttenuationQuadratic != 0) {
    light.attenuationFalloffExponent = 2.0;
  } else if (aiLight->mAttenuationLinear != 0) {
    light.attenuationFalloffExponent = 1.0;
  }
  light.attenuationStartDistance = 0;
  light.attenuationEndDistance = 0;
  light.spotInnerAngle = aiLight->mAngleInnerCone;
  light.spotOuterAngle = aiLight->mAngleOuterCone;
  return light;
}

- (SCNLight*)makeSCNLightFromAssimpNode:(const struct aiNode*)aiNode
                                inScene:(const struct aiScene*)aiScene {
  const struct aiString aiNodeName = aiNode->mName;
  NSString* nodeName = [NSString stringWithUTF8String:&aiNodeName.data];
  for (int i = 0; i < aiScene->mNumLights; i++) {
    const struct aiLight* aiLight = aiScene->mLights[i];
    const struct aiString aiLightNodeName = aiLight->mName;
    NSString* lightNodeName =
        [NSString stringWithUTF8String:&aiLightNodeName.data];
    if ([nodeName isEqualToString:lightNodeName]) {
      NSLog(@"### Creating light for node %@", nodeName);
      NSLog(@"    ambient     %f %f %f ", aiLight->mColorAmbient.r,
            aiLight->mColorAmbient.g, aiLight->mColorAmbient.b);
      NSLog(@"    diffuse     %f %f %f ", aiLight->mColorDiffuse.r,
            aiLight->mColorDiffuse.g, aiLight->mColorDiffuse.b);
      NSLog(@"    specular    %f %f %f ", aiLight->mColorSpecular.r,
            aiLight->mColorSpecular.g, aiLight->mColorSpecular.b);
      NSLog(@"    inner angle %f", aiLight->mAngleInnerCone);
      NSLog(@"    outer angle %f", aiLight->mAngleOuterCone);
      NSLog(@"    att const   %f", aiLight->mAttenuationConstant);
      NSLog(@"    att linear  %f", aiLight->mAttenuationLinear);
      NSLog(@"    att quad    %f", aiLight->mAttenuationQuadratic);
      NSLog(@"    position    %f %f %f", aiLight->mPosition.x,
            aiLight->mPosition.y, aiLight->mPosition.z);
      if (aiLight->mType == aiLightSource_DIRECTIONAL) {
        NSLog(@"    type        Directional");
        return [self makeSCNLightTypeDirectionalForAssimpLight:aiLight];
      } else if (aiLight->mType == aiLightSource_POINT) {
        NSLog(@"    type        Omni");
        return [self makeSCNLightTypePointForAssimpLight:aiLight];
      } else if (aiLight->mType == aiLightSource_SPOT) {
        NSLog(@"    type        Spot");
        return [self makeSCNLightTypeSpotForAssimpLight:aiLight];
      }
    }
  }
  return nil;
}

#pragma mark - Make Cameras
- (SCNCamera*)makeSCNCameraFromAssimpNode:(const struct aiNode*)aiNode
                                  inScene:(const struct aiScene*)aiScene {
  const struct aiString aiNodeName = aiNode->mName;
  NSString* nodeName = [NSString stringWithUTF8String:&aiNodeName.data];
  for (int i = 0; i < aiScene->mNumCameras; i++) {
    const struct aiCamera* aiCamera = aiScene->mCameras[i];
    const struct aiString aiCameraName = aiCamera->mName;
    NSString* cameraNodeName =
        [NSString stringWithUTF8String:&aiCameraName.data];
    if ([nodeName isEqualToString:cameraNodeName]) {
      SCNCamera* camera = [SCNCamera camera];
      camera.xFov = aiCamera->mHorizontalFOV;
      camera.zNear = aiCamera->mClipPlaneNear;
      camera.zFar = aiCamera->mClipPlaneFar;
      return camera;
    }
  }
  return nil;
}

#pragma mark - Make Skinner

- (int)findNumBonesInNode:(const struct aiNode*)aiNode
                  inScene:(const struct aiScene*)aiScene {
  int nBones = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    nBones += aiMesh->mNumBones;
  }
  return nBones;
}

- (NSArray*)getBoneNamesForAssimpNode:(const struct aiNode*)aiNode
                              inScene:(const struct aiScene*)aiScene {
  NSMutableArray* boneNames = [[NSMutableArray alloc] init];

  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    for (int j = 0; j < aiMesh->mNumBones; j++) {
      const struct aiBone* aiBone = aiMesh->mBones[j];
      const struct aiString name = aiBone->mName;
      [boneNames addObject:[NSString stringWithUTF8String:&name.data]];
    }
  }

  return boneNames;
}

- (NSDictionary*)getBoneTransformsForAssimpNode:(const struct aiNode*)aiNode
                                        inScene:(const struct aiScene*)aiScene {
  NSMutableDictionary* boneTransforms = [[NSMutableDictionary alloc] init];

  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    for (int j = 0; j < aiMesh->mNumBones; j++) {
      const struct aiBone* aiBone = aiMesh->mBones[j];
      const struct aiString name = aiBone->mName;
      NSString* key = [NSString stringWithUTF8String:&name.data];
      if ([boneTransforms valueForKey:key] == nil) {
        const struct aiMatrix4x4 aiNodeMatrix = aiBone->mOffsetMatrix;
        GLKMatrix4 glkBoneMatrix = GLKMatrix4Make(
            aiNodeMatrix.a1, aiNodeMatrix.b1, aiNodeMatrix.c1, aiNodeMatrix.d1,
            aiNodeMatrix.a2, aiNodeMatrix.b2, aiNodeMatrix.c2, aiNodeMatrix.d2,
            aiNodeMatrix.a3, aiNodeMatrix.b3, aiNodeMatrix.c3, aiNodeMatrix.d3,
            aiNodeMatrix.a4, aiNodeMatrix.b4, aiNodeMatrix.c4, aiNodeMatrix.d4);

        SCNMatrix4 scnMatrix = SCNMatrix4FromGLKMatrix4(glkBoneMatrix);
        [boneTransforms setValue:[NSValue valueWithSCNMatrix4:scnMatrix]
                          forKey:key];
      }
    }
  }

  return boneTransforms;
}

- (NSArray*)getTransformsForBones:(NSArray*)boneNames
                   fromTransforms:(NSDictionary*)boneTransforms {
  NSMutableArray* transforms = [[NSMutableArray alloc] init];
  for (NSString* boneName in boneNames) {
    [transforms addObject:[boneTransforms valueForKey:boneName]];
  }
  return transforms;
}

- (NSArray*)findBoneNodesInScene:(SCNScene*)scene forBones:(NSArray*)boneNames {
  NSMutableArray* boneNodes = [[NSMutableArray alloc] init];
  for (NSString* boneName in boneNames) {
    SCNNode* boneNode =
        [scene.rootNode childNodeWithName:boneName recursively:YES];
    [boneNodes addObject:boneNode];
  }
  return boneNodes;
}

- (SCNNode*)findSkeletonNodeFromBoneNodes:(NSArray*)boneNodes {
  SCNNode* skeletonRootNode;
  int minDepth = -1;
  for (SCNNode* boneNode in boneNodes) {
    int depth = [self findDepthOfNodeFromRoot:boneNode];
    if (minDepth == -1 || (depth < minDepth)) {
      minDepth = depth;
      skeletonRootNode = boneNode;
    }
  }
  return skeletonRootNode.parentNode;
}

- (int)findDepthOfNodeFromRoot:(SCNNode*)node {
  int depth = 0;
  SCNNode* pNode = node;
  while (pNode.parentNode) {
    depth += 1;
    pNode = pNode.parentNode;
  }
  return depth;
}

- (int)findMaxWeightsForNode:(const struct aiNode*)aiNode
                     inScene:(const struct aiScene*)aiScene {
  int maxWeights = 0;

  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    NSMutableDictionary* meshWeights = [[NSMutableDictionary alloc] init];
    for (int j = 0; j < aiMesh->mNumBones; j++) {
      const struct aiBone* aiBone = aiMesh->mBones[j];
      for (int k = 0; k < aiBone->mNumWeights; k++) {
        const struct aiVertexWeight* aiVertexWeight = &aiBone->mWeights[k];
        NSNumber* vertex = [NSNumber numberWithInt:aiVertexWeight->mVertexId];
        if ([meshWeights valueForKey:vertex.stringValue] == nil) {
          [meshWeights setValue:[NSNumber numberWithInt:1]
                         forKey:vertex.stringValue];
        } else {
          NSNumber* weightCounts = [meshWeights valueForKey:vertex.stringValue];
          [meshWeights
              setValue:[NSNumber numberWithInt:(weightCounts.intValue + 1)]
                forKey:vertex.stringValue];
        }
      }
    }

    // Find the vertex with most weights which is our max weights
    for (int j = 0; j < aiMesh->mNumVertices; j++) {
      NSNumber* vertex = [NSNumber numberWithInt:j];
      NSNumber* weightsCount = [meshWeights valueForKey:vertex.stringValue];
      if (weightsCount.intValue > maxWeights) {
        maxWeights = weightsCount.intValue;
      }
    }
  }

  return maxWeights;
}

- (SCNGeometrySource*)
makeBoneWeightsGeometrySourceAtNode:(const struct aiNode*)aiNode
                            inScene:(const struct aiScene*)aiScene
                       withVertices:(int)nVertices
                         maxWeights:(int)maxWeights {
  float nodeGeometryWeights[nVertices * maxWeights];
  int weightCounter = 0;

  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    NSMutableDictionary* meshWeights = [[NSMutableDictionary alloc] init];
    for (int j = 0; j < aiMesh->mNumBones; j++) {
      const struct aiBone* aiBone = aiMesh->mBones[j];
      for (int k = 0; k < aiBone->mNumWeights; k++) {
        const struct aiVertexWeight* aiVertexWeight = &aiBone->mWeights[k];
        NSNumber* vertex = [NSNumber numberWithInt:aiVertexWeight->mVertexId];
        NSNumber* weight = [NSNumber numberWithFloat:aiVertexWeight->mWeight];
        if ([meshWeights valueForKey:vertex.stringValue] == nil) {
          NSMutableArray* weights = [[NSMutableArray alloc] init];
          [weights addObject:weight];
          [meshWeights setValue:weights forKey:vertex.stringValue];
        } else {
          NSMutableArray* weights =
              [meshWeights valueForKey:vertex.stringValue];
          [weights addObject:weight];
        }
      }
    }

    // Add weights to the weights array for the entire node geometry
    for (int j = 0; j < aiMesh->mNumVertices; j++) {
      NSNumber* vertex = [NSNumber numberWithInt:j];
      NSMutableArray* weights = [meshWeights valueForKey:vertex.stringValue];
      int zeroWeights = maxWeights - weights.count;
      for (NSNumber* weight in weights) {
        nodeGeometryWeights[weightCounter++] = [weight floatValue];
        // NSLog(@" adding weight: %f", weight.floatValue);
      }
      for (int k = 0; k < zeroWeights; k++) {
        nodeGeometryWeights[weightCounter++] = 0.0;
      }
    }
  }

  NSLog(@" weight counter %d", weightCounter);
  assert(weightCounter == nVertices * maxWeights);

  SCNGeometrySource* boneWeightsSource = [SCNGeometrySource
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

- (SCNGeometrySource*)
makeBoneIndicesGeometrySourceAtNode:(const struct aiNode*)aiNode
                            inScene:(const struct aiScene*)aiScene
                       withVertices:(int)nVertices
                         maxWeights:(int)maxWeights
                          boneNames:(NSArray*)boneNames {
  NSLog(@" |--| Making bone indices geometry source: %@", boneNames);
  short nodeGeometryBoneIndices[nVertices * maxWeights];
  int indexCounter = 0;

  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    NSMutableDictionary* meshBoneIndices = [[NSMutableDictionary alloc] init];
    for (int j = 0; j < aiMesh->mNumBones; j++) {
      const struct aiBone* aiBone = aiMesh->mBones[j];
      for (int k = 0; k < aiBone->mNumWeights; k++) {
        const struct aiVertexWeight* aiVertexWeight = &aiBone->mWeights[k];
        NSNumber* vertex = [NSNumber numberWithInt:aiVertexWeight->mVertexId];
        const struct aiString name = aiBone->mName;
        NSString* boneName = [NSString stringWithUTF8String:&name.data];
        NSNumber* boneIndex =
            [NSNumber numberWithInteger:[boneNames indexOfObject:boneName]];
        if ([meshBoneIndices valueForKey:vertex.stringValue] == nil) {
          NSMutableArray* boneIndices = [[NSMutableArray alloc] init];
          [boneIndices addObject:boneIndex];
          [meshBoneIndices setValue:boneIndices forKey:vertex.stringValue];
        } else {
          NSMutableArray* boneIndices =
              [meshBoneIndices valueForKey:vertex.stringValue];
          [boneIndices addObject:boneIndex];
        }
      }
    }

    // Add bone indices to the indices array for the entire node geometry
    for (int j = 0; j < aiMesh->mNumVertices; j++) {
      NSNumber* vertex = [NSNumber numberWithInt:j];
      NSMutableArray* boneIndices =
          [meshBoneIndices valueForKey:vertex.stringValue];
      int zeroIndices = maxWeights - boneIndices.count;
      for (NSNumber* boneIndex in boneIndices) {
        nodeGeometryBoneIndices[indexCounter++] = [boneIndex shortValue];
        // NSLog(@"  adding bone index: %d", boneIndex.shortValue);
      }
      for (int k = 0; k < zeroIndices; k++) {
        nodeGeometryBoneIndices[indexCounter++] = 0;
      }
    }
  }

  assert(indexCounter == nVertices * maxWeights);

  SCNGeometrySource* boneIndicesSource = [SCNGeometrySource
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

- (void)buildSkeletonDatabaseForScene:(SCNAssimpScene*)scene {
  // -------------------------------------------------------------------------
  // find skeleton and add it to bones names if mesh nodes did not refer to it
  // -------------------------------------------------------------------------
  NSArray* uniqueBoneNames = [[NSSet setWithArray:self.boneNames] allObjects];
  NSArray* uniqueBoneNodes =
      [self findBoneNodesInScene:scene forBones:uniqueBoneNames];
  self.skelton = [self findSkeletonNodeFromBoneNodes:uniqueBoneNodes];
  if (![self.boneNames containsObject:self.skelton.name]) {
    [self.boneNames insertObject:self.skelton.name atIndex:0];
    [self.boneTransforms
        setValue:[NSValue valueWithSCNMatrix4:SCNMatrix4Identity]
          forKey:self.skelton.name];
  }

  // -------------------------------------------------------
  // create unique bones and corresponding offset transforms
  // -------------------------------------------------------
  self.uniqueBoneNames = [[NSSet setWithArray:self.boneNames] allObjects];
  NSLog(@" |--| bone names %lu: %@", self.boneNames.count, self.boneNames);
  NSLog(@" |--| unique bone names %lu: %@", self.uniqueBoneNames.count,
        self.uniqueBoneNames);
  self.uniqueBoneNodes =
      [self findBoneNodesInScene:scene forBones:self.uniqueBoneNames];
  NSLog(@" |--| unique bone nodes %lu: %@", self.uniqueBoneNodes.count,
        self.uniqueBoneNodes);
  self.uniqueBoneTransforms = [self getTransformsForBones:self.uniqueBoneNames
                                           fromTransforms:self.boneTransforms];
  NSLog(@" |--| unique bone transforms %lu: %@",
        self.uniqueBoneTransforms.count, self.uniqueBoneTransforms);
  NSLog(@" |--| skeleton bone is : %@", self.skelton);

  // ----------------------------------------
  // setup the scene with animation meta data
  // ----------------------------------------
  scene.skeleton = self.skelton;
  scene.boneNames = self.uniqueBoneNames;
  scene.boneTransforms = self.uniqueBoneTransforms;
}

- (void)makeSkinnerForAssimpNode:(const struct aiNode*)aiNode
                         inScene:(const struct aiScene*)aiScene
                        scnScene:(SCNScene*)scene {
  int nBones = [self findNumBonesInNode:aiNode inScene:aiScene];
  const struct aiString* aiNodeName = &aiNode->mName;
  NSString* nodeName = [NSString stringWithUTF8String:aiNodeName->data];
  if (nBones > 0) {
    int nVertices = [self findNumVerticesInNode:aiNode inScene:aiScene];
    int maxWeights = [self findMaxWeightsForNode:aiNode inScene:aiScene];
    NSLog(@" |--| Making Skinner for node: %@ vertices: %d max-weights: %d "
          @"nBones: %d",
          nodeName, nVertices, maxWeights, nBones);

    SCNGeometrySource* boneWeights =
        [self makeBoneWeightsGeometrySourceAtNode:aiNode
                                          inScene:aiScene
                                     withVertices:nVertices
                                       maxWeights:maxWeights];
    SCNGeometrySource* boneIndices =
        [self makeBoneIndicesGeometrySourceAtNode:aiNode
                                          inScene:aiScene
                                     withVertices:nVertices
                                       maxWeights:maxWeights
                                        boneNames:self.uniqueBoneNames];

    SCNNode* node = [scene.rootNode childNodeWithName:nodeName recursively:YES];
    SCNSkinner* skinner =
        [SCNSkinner skinnerWithBaseGeometry:node.geometry
                                      bones:self.uniqueBoneNodes
                  boneInverseBindTransforms:self.uniqueBoneTransforms
                                boneWeights:boneWeights
                                boneIndices:boneIndices];
    // skinner.skeleton = self.skelton;
    // NSLog(@" assigned skinner %@ skeleton: %@", skinner, skinner.skeleton);
    // node.skinner = skinner;
  }

  for (int i = 0; i < aiNode->mNumChildren; i++) {
    const struct aiNode* aiChildNode = aiNode->mChildren[i];
    [self makeSkinnerForAssimpNode:aiChildNode inScene:aiScene scnScene:scene];
  }
}

#pragma mark - Make animations

- (SCNAssimpAnimNode*)
makeAnimatedSkeletonForAnimation:(const struct aiAnimation*)aiAnimation
                    fromSkeleton:(SCNNode*)skeletonNode
                       withBones:(NSArray*)bones
                  boneTransforms:(NSArray*)boneTransforms {
  NSLog(@" Making animated skeleton node: %@", skeletonNode.name);
  SCNAssimpAnimNode* animBoneNode = [[SCNAssimpAnimNode alloc] init];
  animBoneNode.name = skeletonNode.name;
  if ([bones containsObject:skeletonNode.name]) {
    NSUInteger boneIndex = [bones indexOfObject:skeletonNode.name];
    animBoneNode.boneOffsetMat = [boneTransforms objectAtIndex:boneIndex];

    for (SCNNode* childBone in skeletonNode.childNodes) {
      SCNAssimpAnimNode* animChildBoneNode =
          [self makeAnimatedSkeletonForAnimation:aiAnimation
                                    fromSkeleton:childBone
                                       withBones:bones
                                  boneTransforms:boneTransforms];
      [animBoneNode addChildNode:animChildBoneNode];
    }
  }
  return animBoneNode;
}

- (void)loadAnimationsFromScene:(const struct aiScene*)aiScene {
  if (aiScene->mNumAnimations > 0) {
    for (int i = 0; i < aiScene->mNumAnimations; i++) {
      const struct aiAnimation* aiAnimation = aiScene->mAnimations[i];
      NSString* animName =
          [NSString stringWithUTF8String:aiAnimation->mName.data];
      NSLog(@" animation name: %@", animName);
      NSLog(@" animation has %d node channels", aiAnimation->mNumChannels);
      NSLog(@" animation has %d mesh channels", aiAnimation->mNumMeshChannels);
      NSLog(@" animation duration %f ", aiAnimation->mDuration);
      NSLog(@" ticks per second %f", aiAnimation->mTicksPerSecond);

      SCNAssimpAnimNode* animatedSkeletonNode =
          [self makeAnimatedSkeletonForAnimation:aiAnimation
                                    fromSkeleton:self.skelton
                                       withBones:self.uniqueBoneNames
                                  boneTransforms:self.uniqueBoneTransforms];
      SCNScene* animatedScene = [SCNScene scene];
      [animatedScene.rootNode addChildNode:animatedSkeletonNode];
      for (int i = 0; i < aiAnimation->mNumChannels; i++) {
        const struct aiNodeAnim* aiNodeAnim = aiAnimation->mChannels[i];
        NSString* aiNodeAnimName =
            [NSString stringWithUTF8String:aiNodeAnim->mNodeName.data];
        SCNAssimpAnimNode* animNode =
            (SCNAssimpAnimNode*)[animatedScene.rootNode
                childNodeWithName:aiNodeAnimName
                      recursively:YES];
        if (animNode == nil) {
          NSLog(@" WARNING: did not find node named %@ in animated skeleton.",
                aiNodeAnimName);
          continue;
        }
        animNode.nPosKeys = aiNodeAnim->mNumPositionKeys;
        animNode.nRotKeys = aiNodeAnim->mNumRotationKeys;
        animNode.nScaleKeys = aiNodeAnim->mNumScalingKeys;

        // -----------------
        // add position keys
        // -----------------
        NSMutableArray* posKeys = [[NSMutableArray alloc] init];
        NSMutableArray* posKeyTimes = [[NSMutableArray alloc] init];
        for (int j = 0; j < aiNodeAnim->mNumPositionKeys; j++) {
          const struct aiVectorKey key = aiNodeAnim->mPositionKeys[j];
          SCNVector3 pos =
              SCNVector3Make(key.mValue.x, key.mValue.y, key.mValue.z);
          [posKeys addObject:[NSValue valueWithSCNVector3:pos]];
          [posKeyTimes addObject:[NSNumber numberWithFloat:key.mTime]];
        }
        animNode.posKeys = posKeys;
        animNode.posKeyTimes = posKeyTimes;

        // -----------------
        // add rotation keys
        // -----------------
        NSMutableArray* rotKeys = [[NSMutableArray alloc] init];
        NSMutableArray* rotKeyTimes = [[NSMutableArray alloc] init];
        for (int j = 0; j < aiNodeAnim->mNumRotationKeys; j++) {
          const struct aiQuatKey key = aiNodeAnim->mRotationKeys[j];
          SCNVector4 quat = SCNVector4Make(key.mValue.x, key.mValue.y,
                                           key.mValue.z, key.mValue.w);
          [rotKeys addObject:[NSValue valueWithSCNVector4:quat]];
          [rotKeyTimes addObject:[NSNumber numberWithFloat:key.mTime]];
        }
        animNode.rotKeys = rotKeys;
        animNode.rotKeyTimes = rotKeyTimes;

        // ----------------
        // add scaling keys
        // ----------------
        NSMutableArray* scaleKeys = [[NSMutableArray alloc] init];
        NSMutableArray* scaleKeyTimes = [[NSMutableArray alloc] init];
        for (int j = 0; j < aiNodeAnim->mNumScalingKeys; j++) {
          const struct aiVectorKey key = aiNodeAnim->mScalingKeys[j];
          SCNVector3 scale =
              SCNVector3Make(key.mValue.x, key.mValue.y, key.mValue.z);
          [scaleKeys addObject:[NSValue valueWithSCNVector3:scale]];
          [scaleKeyTimes addObject:[NSNumber numberWithFloat:key.mTime]];
        }
        animNode.scaleKeys = scaleKeys;
        animNode.scaleKeyTimes = scaleKeyTimes;
      }
      NSLog(@" Animated skeleton: %@", animatedSkeletonNode);
      NSLog(@" pos keys: %lu", animatedSkeletonNode.posKeys.count);
    }
  } else {
    NSLog(@" INFO: No animations found in file");
  }
}

@end
