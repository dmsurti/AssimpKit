
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

#import "ModelLog.h"

@interface ModelLog ()

@property (readwrite, nonatomic) NSMutableArray *errors;

@end

@implementation ModelLog

#pragma mark - Creating a model test log
/**
 @name Creating a model test log
 */

/**
 Creates a new model test log object.

 @return A new model test log object.
 */
- (id)init
{
    self = [super init];
    if (self)
    {
        self.errors = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - Add, fetch error logs

/**
 @name Add, fetch error logs
 */

/**
 Add an error log for a test assertion in AssimpImporterTests checks.
 
 @param errorLog The string error log.
 */
- (void)addErrorLog:(NSString *)errorLog
{
    [self.errors addObject:errorLog];
}

- (NSArray *)getErrors
{
    return self.errors;
}

#pragma mark - Pass or Fail

/**
 @name Pass or Fail
 */

/**
 Returns the model test as passed verification if there were no errors during
 testing.
 
 @return Whether the test passed or failed.
 */
- (BOOL)testPassed
{
    return self.errors.count == 0;
}

@end
