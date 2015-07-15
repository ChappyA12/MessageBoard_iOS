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
@dynamic textObjects;

+ (void)load { [self registerSubclass]; self.te }

+ (NSString *)parseClassName { return @"MessageBoardPage"; }

- (NSString *)description {
    return [NSString stringWithFormat:@"MessageBoardPage: {page} %@",self.pageNumber];
}

@end
