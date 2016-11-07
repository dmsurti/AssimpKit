//
//  AssimpImporter.h
//  AssimpKit
//
//  Created by Deepak Surti on 10/27/16.
//
//

#import <Foundation/Foundation.h>
#include <GLKit/GLKit.h>
#import <SceneKit/SceneKit.h>
#import "SCNAssimpScene.h"

@interface AssimpImporter : NSObject

- (SCNAssimpScene*)importScene:(NSString*)filePath;

@end
