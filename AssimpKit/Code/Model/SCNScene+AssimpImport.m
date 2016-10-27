//
//  SCNScene+AssimpImport.m
//  AssimpKit
//
//  Created by Deepak Surti on 10/24/16.
//
//

#import "AssimpImporter.h"
#import "SCNScene+AssimpImport.h"

@implementation SCNScene (AssimpImport)

#pragma mark - Loading a Scene

+ (instancetype)assimpSceneNamed:(NSString*)name {
  AssimpImporter* assimpImporter = [[AssimpImporter alloc] init];
  NSString* file = [[NSBundle mainBundle] pathForResource:name ofType:nil];
  return [assimpImporter importScene:file];
}

+ (instancetype)assimpSceneWithURL:(NSURL*)url {
  AssimpImporter* assimpImporter = [[AssimpImporter alloc] init];
  return [assimpImporter importScene:url.path];
}

@end
