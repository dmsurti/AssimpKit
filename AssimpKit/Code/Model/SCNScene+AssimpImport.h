//
//  SCNScene+AssimpImport.h
//  AssimpKit
//
//  Created by Deepak Surti on 10/24/16.
//
//

#include <GLKit/GLKit.h>
#import <SceneKit/SceneKit.h>

@interface SCNScene (AssimpImport)

+ (instancetype)assimpSceneNamed:(NSString*)name;

@end
