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
@property BOOL userKeyboardIsShowing;
@property TextObject *editedTextObject;

@property NSMutableDictionary <NSNumber *, TextObject *> *UILabelToTextObject;
@property NSMutableDictionary <NSNumber *, UILabel *> *TextObjectToUILabel;

@end

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataLabel.text = [NSString stringWithFormat:@"Page: %@", self.pageNumber];
    _userKeyboardIsShowing = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _UILabelToTextObject = [[NSMutableDictionary alloc] init];
    _TextObjectToUILabel = [[NSMutableDictionary alloc] init];
    [self messageBoardPageForPageNumber:self.pageNumber completion:^(MessageBoardPage *result, NSError *error) {
        if (!error) {
            if (result != nil) {
                _page = result;
                for (UIView *view in self.canvas.subviews) [view removeFromSuperview];
                [self textObjectsForMessageBoardPage:self.page completion:^(NSArray<TextObject *> *result, NSError *error) {
                    if (!error) {
                        for (TextObject *object in result) [self addUILabelUsingTextObject:object];
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

#pragma mark - private getter methods

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

#pragma mark - private text editing methods

- (void)beginEditingWithTextObject: (TextObject *) textObject {
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(8, 150, self.canvas.frame.size.width-16, 30)];
    if (textObject) { //copy formatting
        self.textField.text = textObject.text;
        self.textField.font = [UIFont fontWithName:textObject.font size:[textObject.fontSize intValue]];
        self.textField.textColor = [UIColor colorWithRed:[textObject.color_r intValue] / 255.0 green:[textObject.color_g intValue] / 255.0 blue:[textObject.color_b intValue] / 255.0 alpha:1.0];
    }
    else {
        self.textField.text = @"TEST";
        self.textField.font = [UIFont fontWithName:@"helvetica-bold" size:40];
    }
    self.textField.textAlignment = NSTextAlignmentCenter;
    self.textField.delegate = self;
    self.textField.returnKeyType = UIReturnKeyDone;
    [self.textField becomeFirstResponder];
    [self.view addSubview:self.textField];
    _userKeyboardIsShowing = YES;
}

- (void)addTextObjectToPageUsingTextField: (UITextField *) textField {
    TextObject *text = [TextObject object];
    text.text = textField.text;
    text.font = @"helvetica-bold";
    text.fontSize = [NSNumber numberWithInt:40];
    text.scale = [NSNumber numberWithFloat:1.0];
    text.location_x = [NSNumber numberWithFloat: _lastTouchLocation.x];
    text.location_y = [NSNumber numberWithFloat: _lastTouchLocation.y];
    text.rotation = [NSNumber numberWithFloat:0.0];
    text.color_r = [NSNumber numberWithInt:0];
    text.color_g = [NSNumber numberWithInt:0];
    text.color_b = [NSNumber numberWithInt:0];
    text.parentPageObjectID = self.page.objectId;
    [text saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) ; //NSLog(@"TEXT OBJECT SUCCESSFULLY CREATED");
        else NSLog(@"%@",error);
    }];
    [self addUILabelUsingTextObject:text];
}

- (void)addUILabelUsingTextObject: (TextObject *) textObject{
    UIFont *font = [UIFont fontWithName:textObject.font size:[textObject.fontSize floatValue]];
    CGSize textSize = [textObject.text sizeWithAttributes:@{NSFontAttributeName:font}];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake([textObject.location_x floatValue]-textSize.width/2, [textObject.location_y floatValue], textSize.width, textSize.height)];
    label.text = textObject.text;
    label.font = font;
    label.textColor = [UIColor colorWithRed:[textObject.color_r intValue] / 255.0 green:[textObject.color_g intValue] / 255.0 blue:[textObject.color_b intValue] / 255.0 alpha:1.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.userInteractionEnabled = YES;
    label.backgroundColor = [UIColor redColor];
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedUILabel:)];
    [label addGestureRecognizer:tapRecognizer];
    UIPanGestureRecognizer *dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(userDraggedUILabel:)];
    [label addGestureRecognizer:dragRecognizer];
    UIPinchGestureRecognizer *scaleRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(userScaledUILabel:)];
    [label addGestureRecognizer:scaleRecognizer];
    UIRotationGestureRecognizer *rotateRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(userRotatedUILabel:)];
    [label addGestureRecognizer:rotateRecognizer];
    [_UILabelToTextObject setObject:textObject forKey:[NSNumber numberWithUnsignedLong:[label hash]]];
    [_TextObjectToUILabel setObject:label forKey:[NSNumber numberWithUnsignedLong:[textObject hash]]];
    [self.canvas addSubview:label];
}

- (void)endEditing {
    [self.textField resignFirstResponder];
    if (!_editedTextObject) { [self addTextObjectToPageUsingTextField:_textField]; NSLog(@"UILABEL ADDED"); }
    else  { [self updateTextObjectUsingTextField:_textField ]; NSLog(@"UILABEL UPDATED"); }
    [self.textField removeFromSuperview];
    _userKeyboardIsShowing = NO;
    _editedTextObject = nil;
}

- (void)updateTextObjectUsingTextField: (UITextField *) textField {
    _editedTextObject.text = textField.text;
    _editedTextObject.color_r = [NSNumber numberWithInt:0];
    _editedTextObject.color_g = [NSNumber numberWithInt:0];
    _editedTextObject.color_b = [NSNumber numberWithInt:0];
    [_editedTextObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) ; //NSLog(@"TEXT OBJECT SUCCESSFULLY CREATED");
        else NSLog(@"%@",error);
    }];
    [self updateUILabelUsingTextObject:_editedTextObject];
}

- (void)updateUILabelUsingTextObject: (TextObject *) textObject {
    UILabel *label = [_TextObjectToUILabel objectForKey:[NSNumber numberWithUnsignedLong:[textObject hash]]];
    UIFont *font = [UIFont fontWithName:textObject.font size:[textObject.fontSize floatValue]*[textObject.scale floatValue]];
    CGSize textSize = [textObject.text sizeWithAttributes:@{NSFontAttributeName:font}];
    label.text = textObject.text;
    label.font = font;
    label.textColor = [UIColor colorWithRed:[textObject.color_r intValue] / 255.0 green:[textObject.color_g intValue] / 255.0 blue:[textObject.color_b intValue] / 255.0 alpha:1.0];
    label.frame = CGRectMake([textObject.location_x floatValue]-textSize.width/2, [textObject.location_y floatValue], textSize.width, textSize.height);
}

#pragma mark - private text movement / scaling / rotation methods

- (void)updateTextObject: (TextObject *) textObject WithLocation: (CGPoint) location {
    textObject.location_x = [NSNumber numberWithFloat: location.x];
    textObject.location_y = [NSNumber numberWithFloat: location.y];
    [self updateUILabelLocationScaleRotationWithTextObject:textObject];
}

- (void)updateTextObject: (TextObject *) textObject WithScale: (float) scale {
    NSLog(@"SCALE: %f",scale);
    textObject.scale = [NSNumber numberWithFloat:scale];
    [self updateUILabelLocationScaleRotationWithTextObject:textObject];
}

- (void)updateTextObject: (TextObject *) textObject WithRotation: (float) rotation {
    NSLog(@"ROTATE: %f",rotation);
    textObject.rotation = [NSNumber numberWithFloat:rotation];
    [self updateUILabelLocationScaleRotationWithTextObject:textObject];
}

- (void)updateUILabelLocationScaleRotationWithTextObject: (TextObject *) textObject {
    UILabel *label = [_TextObjectToUILabel objectForKey:[NSNumber numberWithUnsignedLong:[textObject hash]]];
    UIFont *font = [UIFont fontWithName:textObject.font size:[textObject.fontSize floatValue]*[textObject.scale floatValue]];
    CGSize textSize = [textObject.text sizeWithAttributes:@{NSFontAttributeName:font}];
    label.center = CGPointMake([textObject.location_x floatValue], [textObject.location_y floatValue]);
    label.font = font;
    label.frame = CGRectMake([textObject.location_x floatValue]-textSize.width/2, [textObject.location_y floatValue], textSize.width, textSize.height);
    label.transform = CGAffineTransformMakeRotation([textObject.rotation floatValue]);
    [textObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * __nullable error) {
        if (succeeded) NSLog(@"SAVED");
        else NSLog(@"%@",error);
    }];
}

#pragma mark - touch recognition

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _lastTouchLocation = [[touches anyObject] locationInView:self.canvas];
}

- (IBAction)userTappedCanvas:(UITapGestureRecognizer *)sender {
    if (_userKeyboardIsShowing) [self endEditing];
    else [self beginEditingWithTextObject:nil];
}

#pragma mark - gesture recognition

- (IBAction)userTappedUILabel:(UITapGestureRecognizer *)sender {
    NSLog(@"TAP");
    TextObject *textEdited = [_UILabelToTextObject objectForKey: [NSNumber numberWithUnsignedLong: [sender.view hash]]];
    _editedTextObject = textEdited;
    [self beginEditingWithTextObject:textEdited];
}

- (IBAction)userDraggedUILabel:(UIPanGestureRecognizer *)sender {
    NSLog(@"DRAG");
    TextObject *textEdited = [_UILabelToTextObject objectForKey: [NSNumber numberWithUnsignedLong: [sender.view hash]]];
    [self updateTextObject:textEdited WithLocation:[sender locationInView:_canvas]];
}

- (IBAction)userScaledUILabel:(UIPinchGestureRecognizer *)sender {
    TextObject *textEdited = [_UILabelToTextObject objectForKey: [NSNumber numberWithUnsignedLong: [sender.view hash]]];
    [self updateTextObject:textEdited WithScale:sender.scale];
}

- (IBAction)userRotatedUILabel:(UIRotationGestureRecognizer *)sender {
    TextObject *textEdited = [_UILabelToTextObject objectForKey: [NSNumber numberWithUnsignedLong: [sender.view hash]]];
    [self updateTextObject:textEdited WithRotation:sender.rotation];
}

#pragma mark - text field delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self endEditing];
    return NO;
}

@end
