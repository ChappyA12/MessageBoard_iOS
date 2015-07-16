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
#import "TextObject.h"

@interface DataViewController () <UITextFieldDelegate>

@property (nonatomic) MessageBoardPage *page;

@property CGPoint lastTouchLocation;
@property BOOL isTyping;

@end

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataLabel.text = [NSString stringWithFormat:@"Page: %@", self.pageNumber];
    _isTyping = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self messageBoardPageForPageNumber:self.pageNumber completion:^(MessageBoardPage *result, NSError *error) {
        if (!error) {
            if (result != nil) {
                _page = result;
                for (UIView *view in self.canvas.subviews) [view removeFromSuperview];
                [self textObjectsForMessageBoardPage:self.page completion:^(NSArray<TextObject *> *result, NSError *error) {
                    if (!error) {
                        for (TextObject *object in result) [self addUILabelForTextObject:object];
                    }
                    else NSLog(@"%@",error);
                }];
            }
            else {
                _page = [MessageBoardPage object];
                _page.pageNumber = self.pageNumber;
                [_page saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                    if (succeeded) {
                        NSLog(@"OBJECT SUCCESSFULLY CREATED");
                    }
                    else NSLog(@"%@",error);
                }];
            }
        }
        else NSLog(@"%@",error);
    }];
}

#pragma mark - private methods

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

- (void)textObjectsForMessageBoardPage: (MessageBoardPage *) page completion: (void (^)(NSArray<TextObject *> *result, NSError *error)) completion {
    PFQuery *query = [PFQuery queryWithClassName:@"TextObject"];
    [query whereKey:@"parentPageObjectID" equalTo:page.objectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (objects.count == 0) completion(nil, nil);
            else completion(objects, nil);
        }
        else completion(nil, error);
    }];
}


- (void)addTextObjectToPageUsingCurrentContext {
    TextObject *text = [TextObject object];
    text.text = self.textField.text;
    text.font = @"helvetica";
    text.fontSize = [NSNumber numberWithInt:20];
    text.location_x = [NSNumber numberWithInt:(int) _lastTouchLocation.x];
    text.location_y = [NSNumber numberWithInt:(int) _lastTouchLocation.y];
    text.color_r = [NSNumber numberWithInt:0];
    text.color_g = [NSNumber numberWithInt:0];
    text.color_b = [NSNumber numberWithInt:0];
    text.parentPageObjectID = self.page.objectId;
    [text saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) NSLog(@"TEXT OBJECT SUCCESSFULLY CREATED");
        else NSLog(@"%@",error);
    }];
    [self addUILabelForTextObject:text];
}

- (void)addUILabelForTextObject: (TextObject *) textObject {
    UIFont *font = [UIFont fontWithName:textObject.font size:[textObject.fontSize floatValue]];
    CGSize textSize = [textObject.text sizeWithAttributes:@{NSFontAttributeName:font}];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake([textObject.location_x floatValue]-textSize.width/2, [textObject.location_y floatValue], textSize.width, textSize.height)];
    label.text = textObject.text;
    label.font = font;
    label.textColor = [UIColor colorWithRed:[textObject.color_r intValue] / 255.0 green:[textObject.color_g intValue] / 255.0 blue:[textObject.color_b intValue] / 255.0 alpha:1.0];
    label.textAlignment = NSTextAlignmentCenter;
    [self.canvas addSubview:label];
}

#pragma mark - gesture recognition

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _lastTouchLocation = [[touches anyObject] locationInView:self.canvas];
}

- (IBAction)userTappedCanvas:(UITapGestureRecognizer *)sender {
    if (_isTyping) {
        [self.textField resignFirstResponder];
        [self addTextObjectToPageUsingCurrentContext];
        [self.textField removeFromSuperview];
        _isTyping = NO;
    }
    else {
        NSLog(@"ADDING TEXT FIELD");
        self.textField = [[UITextField alloc] initWithFrame:CGRectMake(8, 150, self.canvas.frame.size.width-16, 30)];
        self.textField.text = @"TEST";
        self.textField.textAlignment = NSTextAlignmentCenter;
        self.textField.delegate = self;
        self.textField.returnKeyType = UIReturnKeyDone;
        [self.textField becomeFirstResponder];
        [self.view addSubview:self.textField];
        _isTyping = YES;
    }
}

#pragma mark - text field delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.textField) {
        [textField resignFirstResponder];
        [self addTextObjectToPageUsingCurrentContext];
        [self.textField removeFromSuperview];
        _isTyping = NO;
        return NO;
    }
    return YES;
}

@end
