//
//  SCNScene+AssimpImport.m
//  AssimpKit
//
//  Created by Deepak Surti on 10/24/16.
//
//

#import "SCNScene+AssimpImport.h"
#include "assimp/cimport.h"      // Plain-C interface
#include "assimp/postprocess.h"  // Post processing flags
#include "assimp/scene.h"        // Output data structure

@implementation SCNScene (AssimpImport)

+ (SCNScene*)assimpSceneNamed:(NSString*)name {
  NSString* file = [[NSBundle mainBundle] pathForResource:name ofType:nil];
  return [self importScene:file];
}

+ (SCNScene*)importScene:(NSString*)filePath {
  // Start the import on the given file with some example postprocessing
  // Usually - if speed is not the most important aspect for you - you'll t
  // probably to request more postprocessing than we do in this example.
  const char* pFile = [filePath UTF8String];
  const struct aiScene* aiScene = aiImportFile(
      pFile, aiProcess_CalcTangentSpace | aiProcess_Triangulate |
                 aiProcess_JoinIdenticalVertices | aiProcess_SortByPType);
  // If the import failed, report it
  if (!aiScene) {
    NSLog(@" Scene importing failed");
  }
  // Now we can access the file's contents
  SCNScene* scene = [self makeSCNSceneFromAssimpScene:aiScene];
  // We're done. Release all resources associated with this import
  aiReleaseImport(aiScene);
  return scene;
}

+ (SCNScene*)makeSCNSceneFromAssimpScene:(const struct aiScene*)aiScene {
  NSLog(@" Make an SCNScene");
  const struct aiNode* aiRootNode = aiScene->mRootNode;
  SCNScene* scene = [[SCNScene alloc] init];
  SCNNode* scnRootNode =
      [self makeSCNNodeFromAssimpNode:aiRootNode inScene:aiScene];
  [scene.rootNode addChildNode:scnRootNode];
  return scene;
}

+ (SCNGeometry*)makeSCNGeometryFromAssimpNode:(const struct aiNode*)aiNode
                                      inScene:(const struct aiScene*)aiScene {
  NSMutableArray* scnGeometrySources = [[NSMutableArray alloc] init];
  NSMutableArray* scnGeometryElements = [[NSMutableArray alloc] init];
  int k = aiNode->mNumMeshes;
  if (k > 0) {
    k = 1;
  }
  for (int i = 0; i < k; i++) {
    int aiMeshIndex = aiNode->mMeshes[i];
    const struct aiMesh* aiMesh = aiScene->mMeshes[aiMeshIndex];
    // create SCNGeometry source for aiMesh vertices, normals, texture
    // coordinates
    // --------
    // vertices
    // --------
    SCNVector3 scnVertices[aiMesh->mNumVertices];
    for (int i = 0; i < aiMesh->mNumVertices; i++) {
      const struct aiVector3D* aiVector3D = &aiMesh->mVertices[i];
      SCNVector3 pos =
          SCNVector3Make(aiVector3D->x, aiVector3D->y, aiVector3D->z);
      scnVertices[i] = pos;
    }
    SCNGeometrySource* vertexSource =
        [SCNGeometrySource geometrySourceWithVertices:scnVertices
                                                count:aiMesh->mNumVertices];
    [scnGeometrySources addObject:vertexSource];
    // -------
    // normals
    // -------
    SCNVector3 scnNormals[aiMesh->mNumVertices];
    SCNGeometrySource* normalSource;
    if (aiMesh->mNormals == NULL) {
      for (int i = 0; i < aiMesh->mNumVertices; i++) {
        const struct aiVector3D* aiVector3D = &aiMesh->mNormals[i];
        SCNVector3 normal =
            SCNVector3Make(aiVector3D->x, aiVector3D->y, aiVector3D->z);
        scnNormals[i] = normal;
      }
      normalSource =
          [SCNGeometrySource geometrySourceWithVertices:scnVertices
                                                  count:aiMesh->mNumVertices];
      [scnGeometrySources addObject:normalSource];
    }

    // create SCNGeometryElement for aiMesh indices
    int scnIndices[aiMesh->mNumFaces * 3];
    int k = 0;
    for (int i = 0; i < aiMesh->mNumFaces; i++) {
      const struct aiFace* aiFace = &aiMesh->mFaces[i];
      for (int j = 0; j < aiFace->mNumIndices; j++) {
        scnIndices[k] = aiFace->mIndices[j];
        ++k;
      }
    }
    NSData* indicesData =
        [NSData dataWithBytes:scnIndices length:sizeof(scnIndices)];
    SCNGeometryElement* indices = [SCNGeometryElement
        geometryElementWithData:indicesData
                  primitiveType:SCNGeometryPrimitiveTypeTriangles
                 primitiveCount:aiMesh->mNumFaces
                  bytesPerIndex:sizeof(int)];
    [scnGeometryElements addObject:indices];

    // create SCNGeometryMaterial for aiMesh material
    //    const struct aiMaterial* aiMaterial = aiScene->mMaterials[0];
    //    struct aiColor3D color;
    //    color.r = 0.0f;
    //    color.g = 0.0f;
    //    color.b = 0.0f;
    //    aiGetMaterialColor(aiMaterial, AI_MATKEY_COLOR_DIFFUSE, &color);
    //    if (color.r == 0.0 && color.g == 0.0 && color.b == 0.0) {
    //      // implies this is possibly a texture
    //    } else {
    //      // implies this is a texture
    //    }
  }

  // make SCNGeometry with sources, elements and materials
  if (scnGeometrySources.count > 0) {
    SCNGeometry* scnGeometry =
        [SCNGeometry geometryWithSources:scnGeometrySources
                                elements:scnGeometryElements];
    return scnGeometry;
  }
  return nil;
}

+ (SCNNode*)makeSCNNodeFromAssimpNode:(const struct aiNode*)aiNode
                              inScene:(const struct aiScene*)aiScene {
  SCNNode* node = [[SCNNode alloc] init];
  const struct aiString* aiNodeName = &aiNode->mName;
  node.name = [NSString stringWithUTF8String:aiNodeName->data];
  NSLog(@" Creating node : %@", node.name);
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

@end
