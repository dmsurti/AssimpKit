//
//  AssimpImporter.m
//  AssimpKit
//
//  Created by Deepak Surti on 10/27/16.
//
//

#import "AssimpImporter.h"
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

- (SCNScene*)makeSCNSceneFromAssimpScene:(const struct aiScene*)aiScene
                                  atPath:(NSString*)path {
  NSLog(@" Make an SCNScene");
  const struct aiNode* aiRootNode = aiScene->mRootNode;
  SCNScene* scene = [[SCNScene alloc] init];
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
  self.uniqueBoneTransforms = [self getTransformsForBones:self.uniqueBoneNames
                                           fromTransforms:self.boneTransforms];
  NSLog(@" |--| unique bone transforms %lu: %@",
        self.uniqueBoneTransforms.count, self.uniqueBoneTransforms);
  self.skelton = [self findSkeletonNodeFromBoneNodes:self.uniqueBoneNodes];
  NSLog(@" |--| skeleton bone is : %@", self.skelton);
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
  node.geometry =
      [self makeSCNGeometryFromAssimpNode:aiNode inScene:aiScene atPath:path];
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
  return skeletonRootNode;
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

@end
