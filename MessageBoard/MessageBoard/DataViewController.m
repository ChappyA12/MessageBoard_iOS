//
//  DataViewController.m
//  MessageBoard
//
//  Created by Chappy Asel on 7/15/15.
//  Copyright © 2015 CD. All rights reserved.
//

#import "DataViewController.h"
#import <Parse/Parse.h>
#import "MessageBoardPage.h"

@interface DataViewController ()

@property (nonatomic) MessageBoardPage *page;

@end

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataLabel.text = [NSString stringWithFormat:@"Page: %@", self.pageNumber];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self messageBoardPageForPageNumber:self.pageNumber completion:^(MessageBoardPage *result, NSError *error) {
        if (!error) {
            if (result != nil) _page = result;
            else {
                _page = [MessageBoardPage object];
                _page.pageNumber = self.pageNumber;
                [_page saveInBackgroundWithBlock:^(BOOL succeeded, NSError * __nullable error) {
                    if (succeeded) {
                        NSLog(@"OBJECT SUCCESSFULLY CREATED");
                    }
                    else NSLog(@"%@",error.description);
                }];
            }
        }
        else NSLog(@"%@",error.description);
    }];
}

- (void)messageBoardPageForPageNumber: (NSNumber *) number completion: (void (^)(MessageBoardPage *result, NSError *error)) completion {
    PFQuery *query = [PFQuery queryWithClassName:@"MessageBoardPage"];
    [query whereKey:@"pageNumber" equalTo:number];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (objects.count == 0) completion(nil, nil);
            else {
                MessageBoardPage *ret = objects[0];
                completion(ret, nil);
            }
        }
        else completion(nil, error);
    }];
}

@end
