//
//  ModelFile.h
//  Library
//
//  Created by Deepak Surti on 12/30/16.
//
//

#import <Foundation/Foundation.h>

@interface ModelFile : NSObject

@property (readonly, nonatomic) NSString *subDir;
@property (readonly, nonatomic) NSString *fileName;
@property (readonly, nonatomic) NSString *path;

- (id)initWithFileName:(NSString *)file
                atPath:(NSString *)path
              inSubDir:(NSString *)subDir;

@end
