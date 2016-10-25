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
  const struct aiScene* aiScene = aiImportFile(
      pFile, aiProcess_CalcTangentSpace | aiProcess_Triangulate |
                 aiProcess_JoinIdenticalVertices | aiProcess_SortByPType);
  // If the import failed, report it
  if (!aiScene) {
    NSLog(@" Scene importing failed for filePath %@", filePath);
    return nil;
  }
  // Now we can access the file's contents
  SCNScene* scene = [self makeSCNSceneFromAssimpScene:aiScene];
  // We're done. Release all resources associated with this import
  aiReleaseImport(aiScene);
  return scene;
}

#pragma mark - Make SCN Scene

+ (instancetype)makeSCNSceneFromAssimpScene:(const struct aiScene*)aiScene {
  NSLog(@" Make an SCNScene");
  const struct aiNode* aiRootNode = aiScene->mRootNode;
  SCNScene* scene = [[[self class] alloc] init];
  SCNNode* scnRootNode =
      [self makeSCNNodeFromAssimpNode:aiRootNode inScene:aiScene];
  [scene.rootNode addChildNode:scnRootNode];
  return scene;
}

#pragma mark - Make SCN Node

+ (SCNNode*)makeSCNNodeFromAssimpNode:(const struct aiNode*)aiNode
                              inScene:(const struct aiScene*)aiScene {
  SCNNode* node = [[SCNNode alloc] init];
  const struct aiString* aiNodeName = &aiNode->mName;
  node.name = [NSString stringWithUTF8String:aiNodeName->data];
  NSLog(@" Creating node %@ with %d meshes", node.name, aiNode->mNumMeshes);
  node.geometry = [self makeSCNGeometryFromAssimpNode:aiNode inScene:aiScene];

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
    SCNNode* childNode =
        [self makeSCNNodeFromAssimpNode:aiChildNode inScene:aiScene];
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
  SCNVector3 scnVertices[nVertices];
  int verticesCounter = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    // create SCNGeometry source for aiMesh vertices, normals, texture
    // coordinates
    for (int j = 0; j < aiMesh->mNumVertices; j++) {
      const struct aiVector3D* aiVector3D = &aiMesh->mVertices[j];
      SCNVector3 pos =
          SCNVector3Make(aiVector3D->x, aiVector3D->y, aiVector3D->z);
      scnVertices[verticesCounter++] = pos;
    }
  }
  SCNGeometrySource* vertexSource =
      [SCNGeometrySource geometrySourceWithVertices:scnVertices
                                              count:nVertices];
  return vertexSource;
}

+ (SCNGeometrySource*)
makeNormalGeometrySourceForNode:(const struct aiNode*)aiNode
                        inScene:(const struct aiScene*)aiScene
                  withNVertices:(int)nVertices {
  SCNVector3 scnNormals[nVertices];
  int verticesCounter = 0;
  for (int i = 0; i < aiNode->mNumMeshes; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    if (aiMesh->mNormals == NULL) {
      for (int j = 0; j < aiMesh->mNumVertices; j++) {
        const struct aiVector3D* aiVector3D = &aiMesh->mNormals[j];
        SCNVector3 normal =
            SCNVector3Make(aiVector3D->x, aiVector3D->y, aiVector3D->z);
        scnNormals[verticesCounter++] = normal;
      }
    }
  }
  SCNGeometrySource* normalSource =
      [SCNGeometrySource geometrySourceWithVertices:scnNormals count:nVertices];
  return normalSource;
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

+ (SCNGeometry*)makeSCNGeometryFromAssimpNode:(const struct aiNode*)aiNode
                                      inScene:(const struct aiScene*)aiScene {
  // make SCNGeometry with sources, elements and materials
  NSArray* scnGeometrySources =
      [self makeGeometrySourcesForNode:aiNode inScene:aiScene];
  if (scnGeometrySources.count > 0) {
    NSArray* scnGeometryElements =
        [self makeGeometryElementsforNode:aiNode inScene:aiScene];
    SCNGeometry* scnGeometry =
        [SCNGeometry geometryWithSources:scnGeometrySources
                                elements:scnGeometryElements];
    // ---------
    // materials
    // ---------

    for (int i = 0; i < aiNode->mNumMeshes; i++) {
      int aiMeshIndex = aiNode->mMeshes[i];
      const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
      const struct aiMaterial* aiMaterial =
          aiScene->mMaterials[aiMesh->mMaterialIndex];
      struct aiString name;
      aiGetMaterialString(aiMaterial, AI_MATKEY_NAME, &name);
      NSLog(@" Material name is %@",
            [NSString stringWithUTF8String:&name.data]);
      struct aiColor3D color;
      color.r = 0.0f;
      color.g = 0.0f;
      color.b = 0.0f;
      if (AI_SUCCESS ==
          aiGetMaterialColor(aiMaterial, AI_MATKEY_COLOR_DIFFUSE, &color)) {
        NSLog(@" diffuse color defined");
      }
    }
    return scnGeometry;
  }
  return nil;
}

@end
