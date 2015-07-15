//
//  MessageBoardPage.m
//  MessageBoard
//
//  Created by Chappy Asel on 7/15/15.
//  Copyright © 2015 CD. All rights reserved.
//

#import "MessageBoardPage.h"
#import <Parse/PFObject+Subclass.h>

@implementation MessageBoardPage

@dynamic pageNumber;

+ (void)load { [self registerSubclass]; }

+ (NSString *)parseClassName { return @"MessageBoardPage"; }

- (id) initWithPageNumber: (NSNumber *) number {
    if (self = [super init]) {
        number = self.pageNumber;
    }
    return self;
}

@end
