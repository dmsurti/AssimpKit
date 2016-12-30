//
//  ModelFile.m
//  Library
//
//  Created by Deepak Surti on 12/30/16.
//
//

#import "ModelFile.h"

@interface ModelFile ()

#pragma mark - Model file info
/**
 @name Model file info
 */

/**
 The asset subdirectory of the model file.
 */
@property (readwrite, nonatomic) NSString *subDir;

/**
 The file name (including the file format) directory of the model file.
 */
@property (readwrite, nonatomic) NSString *file;

/**
 The full file path of the model file.
 */
@property (readwrite, nonatomic) NSString *path;

@end

@implementation ModelFile

#pragma mark - Creating a model file
/**
 @name Creating a model file.
 */

/**
 Creates a model file object with file name, subdirectory and path.
 
 @param file The model file name including the file format subdirectory.
 @param path The full file path of the model file.
 @param subDir The asset subdirectory of the model file.
 @return A model file object.
 */
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

#pragma mark - SCN asset filepaths
/**
 @name SCN asset filepaths
 */

/**
 Returns the scn asset including the model file subdirectory and scn extension.
 
 @return The scn asset filename with .scn extension.
 */
- (NSString *)getScnAssetFile
{
    NSString *scnFile = [[self.file stringByDeletingPathExtension]
        stringByAppendingPathExtension:@"scn"];
    return [self.subDir stringByAppendingString:scnFile];
}

/**
 Returns the animation scn asset including file subdirectory and scn extension.
 
 @param animFileName The animation file name, usually the key name.
 @return The scn asset filename with .scn extension.
 */
- (NSString *)getAnimScnAssetFile:(NSString *)animFileName
{
    NSString *fileDir = [[self.file stringByDeletingLastPathComponent]
        stringByAppendingString:@"/"];
    NSString *scnFile = [animFileName stringByAppendingPathExtension:@"scn"];
    return [[self.subDir stringByAppendingString:fileDir]
        stringByAppendingString:scnFile];
}

@end
