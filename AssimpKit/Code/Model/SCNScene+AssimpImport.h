//
//  SCNScene+AssimpImport.h
//  AssimpKit
//
//  Created by Deepak Surti on 10/24/16.
//
//

#include <GLKit/GLKit.h>
#import <SceneKit/SceneKit.h>
#import "SCNAssimpScene.h"

@interface SCNScene (AssimpImport)

+ (SCNAssimpScene*)assimpSceneNamed:(NSString*)name;
+ (SCNAssimpScene*)assimpSceneWithURL:(NSURL*)url;

@end
