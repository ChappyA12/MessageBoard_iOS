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
#import "ISColorWheel.h"
#import "MBLabel.h"

@interface DataViewController () <UITextFieldDelegate, MBLabelDelegate, ISColorWheelDelegate>

@property (nonatomic) MessageBoardPage *page;

@property CGPoint lastTouchLocation;
@property BOOL userKeyboardIsShowing;
@property TextObject *editedTextObject;
@property CGPoint dragLocationInsideUILabel;
@property ISColorWheel *colorWheel;

@property NSTimer *updateTimer;

@property NSMutableDictionary <NSString *, MBLabel *> *MBLabelForObjectID;
@property NSMutableDictionary <NSString *, TextObject *> *TextObjectForObjectID;
@property NSMutableArray <NSString *> *objectIDs;

@end

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataLabel.text = [NSString stringWithFormat:@"Page: %@", self.pageNumber];
    _userKeyboardIsShowing = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillAppear:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _MBLabelForObjectID = [[NSMutableDictionary alloc] init];
    _TextObjectForObjectID = [[NSMutableDictionary alloc] init];
    _objectIDs = [[NSMutableArray alloc] init];
    [self messageBoardPageForPageNumber:self.pageNumber completion:^(MessageBoardPage *result, NSError *error) {
        if (!error) {
            if (result != nil) {
                _page = result;
                for (UIView *view in self.canvas.subviews) [view removeFromSuperview];
                [self textObjectsForMessageBoardPage:self.page completion:^(NSArray<TextObject *> *result, NSError *error) {
                    if (!error) {
                        for (TextObject *object in result) {
                            MBLabel *label = [[MBLabel alloc] initWithTextObject:object andCanvas:_canvas];
                            [_MBLabelForObjectID setObject:label forKey:object.objectId];
                            [_TextObjectForObjectID setObject:object forKey:object.objectId];
                            [_canvas addSubview:label];
                        }
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
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updatePage:) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_updateTimer invalidate];
}

- (void)updatePage: (NSTimer *) sender {
    [self messageBoardPageForPageNumber:self.pageNumber completion:^(MessageBoardPage *result, NSError *error) {
        if (!error) {
            if (result != nil) {
                if (![_page.updatedAt isEqualToDate:result.updatedAt]) {
                    NSLog(@"UPDATE NEEDED:");
                    _page = result;
                    [self textObjectsForMessageBoardPage:self.page completion:^(NSArray<TextObject *> *result, NSError *error) {
                        if (!error) {
                            NSMutableArray<TextObject *> *unverifiedObjects = [[NSMutableArray alloc] initWithArray:_TextObjectForObjectID.allValues];
                            for (TextObject *testTextObject in result) {
                                TextObject *existingTextObject = [_TextObjectForObjectID objectForKey:testTextObject.objectId];
                                if (existingTextObject) {
                                    [unverifiedObjects removeObject:existingTextObject];
                                    if (![existingTextObject.updatedAt isEqualToDate:testTextObject.updatedAt]) { //object needs update
                                        NSLog(@"UPDATE");
                                        existingTextObject = testTextObject;
                                        MBLabel *label = [_MBLabelForObjectID objectForKey:existingTextObject.objectId];
                                        [label updateText];
                                        [label updateTranslations];
                                    }
                                    else NSLog(@"SAME");
                                }
                                else { //new object needs to be created
                                    NSLog(@"NEW");
                                    MBLabel *label = [[MBLabel alloc] initWithTextObject:testTextObject andCanvas:_canvas];
                                    [_MBLabelForObjectID setObject:label forKey:testTextObject.objectId];
                                    [_TextObjectForObjectID setObject:testTextObject forKey:testTextObject.objectId];
                                    [_canvas addSubview:label];
                                }
                            }
                            for (TextObject *object in unverifiedObjects) { //objects to delete
                                NSLog(@"DELETED");
                                [self shouldBeginEditingMBLabel:[_MBLabelForObjectID objectForKey:object.objectId]];
                            }
                        }
                        else NSLog(@"%@",error);
                    }];
                }
            }
            else {
                for (UIView *view in _canvas.subviews) [view removeFromSuperview];
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

#pragma mark - private server fetch methods

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

#pragma mark - private point conversion methods

- (CGPoint)locationForTextObjectUsingPoint: (CGPoint) point {
    return CGPointMake(point.x/_canvas.frame.size.width, point.y/_canvas.frame.size.height);
}

#pragma mark - private text editing methods

- (void)shouldBeginEditingMBLabel:(MBLabel *)label {
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(8, 150, self.canvas.frame.size.width-16, 30)];
    if (label) { //copy formatting
        self.textField.text = label.textObject.text;
        if ([label.textObject.fontSize floatValue] > 70.0) self.textField.font = [UIFont fontWithName:label.textObject.font size:70.0];
        else self.textField.font = [UIFont fontWithName:label.textObject.font size:[label.textObject.fontSize intValue]];
        self.textField.textColor = [UIColor colorWithRed:[label.textObject.color_r floatValue] green:[label.textObject.color_g floatValue] blue:[label.textObject.color_b floatValue] alpha:1.0];
    }
    else {
        self.textField.text = @"TEST";
        self.textField.font = [UIFont fontWithName:@"helvetica-bold" size:40];
    }
    self.textField.textAlignment = NSTextAlignmentCenter;
    self.textField.delegate = self;
    self.textField.returnKeyType = UIReturnKeyDone;
    [self.textField becomeFirstResponder];
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.view.frame;
    visualEffectView.tag = 10;
    visualEffectView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing:)];
    [visualEffectView addGestureRecognizer:tapRecognizer];
    [self.view addSubview:visualEffectView];
    _colorWheel = [[ISColorWheel alloc] initWithFrame:CGRectMake(8, 28, 100, 100)];
    [_colorWheel setCurrentColor:self.textField.textColor];
    _colorWheel.delegate = self;
    [visualEffectView addSubview:_colorWheel];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(8, 32+100+8, 100, 20)];
    slider.minimumValue = 0.0;
    slider.maximumValue = 1.0;
    CGFloat brightness = 0.0;
    [self.textField.textColor getHue:nil saturation:nil brightness:&brightness alpha:nil];
    slider.value = brightness;
    slider.minimumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.35];
    slider.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.15];
    slider.thumbTintColor = [UIColor colorWithWhite:1 alpha:1];
    [slider addTarget:self action:@selector(brightnessAdjusted:) forControlEvents:UIControlEventValueChanged];
    [visualEffectView addSubview:slider];
    [self.view addSubview:self.textField];
    _userKeyboardIsShowing = YES;
}

- (void)addTextObjectToPageUsingTextField: (UITextField *) textField {
    TextObject *text = [TextObject object];
    text.text = textField.text;
    text.font = @"helvetica-bold";
    text.fontSize = [NSNumber numberWithInt:40];
    text.scale = [NSNumber numberWithFloat:1.0];
    CGPoint loc = [self locationForTextObjectUsingPoint:_lastTouchLocation];
    text.location_x = [NSNumber numberWithFloat: loc.x];
    text.location_y = [NSNumber numberWithFloat: loc.y];
    text.rotation = [NSNumber numberWithFloat:0.0];
    text.color_r = [NSNumber numberWithInt:0];
    text.color_g = [NSNumber numberWithInt:0];
    text.color_b = [NSNumber numberWithInt:0];
    text.parentPageObjectID = self.page.objectId;
    [text saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [_objectIDs addObject:text.objectId];
            MBLabel *label = [[MBLabel alloc] initWithTextObject:text andCanvas:_canvas];
            label.delegate = self;
            [_canvas addSubview:label];
        }
        else NSLog(@"%@",error);
    }];
    _page.childrenLastUpdated = [NSDate date];
    [_page saveInBackground];
}

- (void)endEditing: (UIView *) sender {
    [self endEditing];
}

- (void)endEditing {
    [self.textField resignFirstResponder];
    if (!_editedTextObject) { [self addTextObjectToPageUsingTextField:_textField]; NSLog(@"UILABEL ADDED"); }
    else  { [self updateTextObjectUsingTextField:_textField ]; NSLog(@"UILABEL UPDATED"); }
    [self.textField removeFromSuperview];
    UIView *view = [self.view viewWithTag:10];
    [UIView animateWithDuration:0.2 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{ view.alpha = 0.0; }
                     completion:^(BOOL finished){ [view removeFromSuperview]; }];
    _userKeyboardIsShowing = NO;
    _editedTextObject = nil;
}

- (void)updateTextObjectUsingTextField: (UITextField *) textField {
    _editedTextObject.text = textField.text;
    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    [NSNumber numberWithInt:[textField.textColor getRed:&red green:&green blue:&blue alpha:nil]];
    _editedTextObject.color_r = [NSNumber numberWithFloat:red];
    _editedTextObject.color_g = [NSNumber numberWithFloat:green];
    _editedTextObject.color_b = [NSNumber numberWithFloat:blue];
    [_editedTextObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) ; //NSLog(@"TEXT OBJECT SUCCESSFULLY CREATED");
        else NSLog(@"%@",error);
    }];
    _page.childrenLastUpdated = [NSDate date];
    [_page saveInBackground];
    MBLabel *label = [_MBLabelForObjectID objectForKey:_editedTextObject.objectId];
    label.delegate = self;
    [label updateText];
}

- (void)shouldRemoveMBLabel:(MBLabel *)label {
    NSString *objectID = label.textObject.objectId;
    [label.textObject deleteInBackground];
    [_MBLabelForObjectID removeObjectForKey:objectID];
    [_TextObjectForObjectID removeObjectForKey:objectID];
    [label removeFromSuperview];
    [_objectIDs removeObject:objectID];
}

#pragma mark - ISColorWheelDelegate methods

- (void)colorWheelDidChangeColor:(ISColorWheel *)colorWheel {
    _textField.textColor = colorWheel.currentColor;
}

- (void)brightnessAdjusted: (UISlider *)sender {
    _colorWheel.brightness = sender.value;
}

#pragma mark - keyboard notifiction

- (void)keyboardWillAppear: (NSNotification *) notification {
    NSDictionary *keyboardInfo = [notification userInfo];
    NSValue *keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    self.textField.frame = CGRectMake(8, self.view.frame.size.height-keyboardFrameBeginRect.size.height-80, self.canvas.frame.size.width-16, 80);
}

#pragma mark - private text movement / scaling / rotation methods

- (void)translationEndedForTextObject:(TextObject *)textObject {
    [textObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * __nullable error) {
        if (succeeded) NSLog(@"SAVED");
        else NSLog(@"%@",error);
    }];
    _page.childrenLastUpdated = [NSDate date];
    [_page saveInBackground];
    textObject.fontSize = [NSNumber numberWithFloat:[textObject.fontSize floatValue]*[textObject.scale floatValue]];
    textObject.scale = [NSNumber numberWithFloat:1.0];
}

#pragma mark - touch recognition

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _lastTouchLocation = [[touches anyObject] locationInView:self.canvas];
}

- (IBAction)userTappedCanvas:(UITapGestureRecognizer *)sender {
    if (_userKeyboardIsShowing) [self endEditing];
    else [self shouldBeginEditingMBLabel:nil];
}

#pragma mark - text field delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self endEditing];
    return NO;
}

@end
