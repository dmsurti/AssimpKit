
/*
 ---------------------------------------------------------------------------
 Assimp to Scene Kit Library (AssimpKit)
 ---------------------------------------------------------------------------
 Copyright (c) 2016, AssimpKit team
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

#import <XCTest/XCTest.h>
#import "SCNScene+AssimpImport.h"

/**
 The test class for the file format support.
 
 This class tests the number of file formats and the file formats supported.
 */
@interface SCNSceneTests : XCTestCase

@end

@implementation SCNSceneTests

#pragma mark - Test formats supported

/**
 @name Test formats supported
 */

/**
 Tests the API returns YES for file extensions for supported formats.
 */
- (void)testSupportedFormats
{
    NSArray *validExts =
        [@"3d,3ds,ac,b3d,bvh,cob,dae,dxf,ifc,irr,md2,md5mesh,"
         @"md5anim,m3sd,nff,obj,off,mesh.xml,ply,q3o,q3s,raw,"
         @"smd,stl,wrl,xgl,zgl,fbx,md3" componentsSeparatedByString:@","];
    for (NSString *validExt in validExts)
    {
        XCTAssertTrue([SCNScene canImportFileExtension:validExt],
                      @"Could not import supported extension %@", validExt);
    }
}

/**
 Tests the API returns NO for file extensions for unsupported formats.
 */
- (void)testNotSupportedFormats
{
    NSArray *notSupportedExts =
        [@"ase,csm,lwo,lxo,lws,ter,X,pk3,m3,blend,irrmesh, mdl"
            componentsSeparatedByString:@","];
    for (NSString *notSupportedExt in notSupportedExts)
    {
        XCTAssertFalse([SCNScene canImportFileExtension:notSupportedExt],
                       @"Can import un-supported format %@", notSupportedExt);
    }

    XCTAssertFalse([SCNScene canImportFileExtension:@""],
                   @"Can import format with no extension");
}

- (void)testSupportedFileTypes
{
    NSArray *validExts = [SCNAssimpScene allowedFileExtensions];
    XCTAssertTrue(validExts.count == 29,
                  @"Expected %d formats supported, instead supports %lu", 31,
                  (unsigned long)validExts.count);
}

@end
