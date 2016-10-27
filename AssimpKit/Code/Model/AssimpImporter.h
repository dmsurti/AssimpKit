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

@interface AssimpImporter : NSObject

- (SCNScene*)importScene:(NSString*)filePath;

@end
