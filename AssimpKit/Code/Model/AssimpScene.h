//
//  AssimpScene.h
//  AssimpKit
//
//  Created by Deepak Surti on 10/24/16.
//
//

#import <Foundation/Foundation.h>
#include <GLKit/GLKit.h>
#include <SceneKit/SceneKit.h>

@interface AssimpScene : NSObject

- (SCNScene*)importScene:(NSString*)filePath;

@end
