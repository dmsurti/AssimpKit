//
//  ModelFile.m
//  Library
//
//  Created by Deepak Surti on 12/30/16.
//
//

#import "ModelFile.h"

@interface ModelFile ()

@property (readwrite, nonatomic) NSString *subDir;
@property (readwrite, nonatomic) NSString *file;
@property (readwrite, nonatomic) NSString *path;

@end

@implementation ModelFile

- (id)initWithFileName:(NSString *)file
                atPath:(NSString *)path
              inSubDir:(NSString *)subDir
{
    self = [super init];
    if (self)
    {
        self.file = file;
        self.path = path;
        self.subDir = subDir;
    }
    return self;
}

@end
