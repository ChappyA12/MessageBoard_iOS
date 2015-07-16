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

+ (void)load { [self registerSubclass]; }

+ (NSString *)parseClassName { return @"MessageBoardPage"; }

- (NSString *)description {
    return [NSString stringWithFormat:@"MessageBoardPage: \n{page} %@ \n{textObjects} %@",self.pageNumber,self.textObjects];
}

- (void)addTextObject: (TextObject *) object {
    if (!self.textObjects) self.textObjects = [[NSMutableArray alloc] init];
    self.textObjects[self.textObjects.count] = object;
}

@end
