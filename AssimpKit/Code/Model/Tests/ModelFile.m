
/*
 ---------------------------------------------------------------------------
 Assimp to Scene Kit Library (AssimpKit)
 ---------------------------------------------------------------------------
 Copyright (c) 2016, Deepak Surti, Ison Apps, AssimpKit team
 All rights reserved.
 Redistribution and use of this software in source and binary forms,
 with or without modification, are permitted provided that the following
 conditions are met:
 * Redistributions of source code must retain the above
 copyright notice, this list of conditions and the
 following disclaimer.
 * Redistributions in binary form must reproduce the above
 copyright notice, this list of conditions and the
 following disclaimer in the documentation and/or other
 materials provided with the distribution.
 * Neither the name of the AssimpKit team, nor the names of its
 contributors may be used to endorse or promote products
 derived from this software without specific prior
 written permission of the AssimpKit team.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ---------------------------------------------------------------------------
 */

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
