//
//  SCNScene+AssimpImport.h
//  AssimpKit
//
//  Created by Deepak Surti on 10/24/16.
//
//

#import "SCNAssimpScene.h"
#include <GLKit/GLKit.h>
#import <SceneKit/SceneKit.h>

@interface SCNScene (AssimpImport)

+ (SCNAssimpScene *)assimpSceneNamed:(NSString *)name;
+ (SCNAssimpScene *)assimpSceneWithURL:(NSURL *)url;

@end
