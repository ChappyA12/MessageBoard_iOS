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

@interface DataViewController () <UITextFieldDelegate, ISColorWheelDelegate>

@property (nonatomic) MessageBoardPage *page;

@property CGPoint lastTouchLocation;
@property BOOL userKeyboardIsShowing;
@property TextObject *editedTextObject;
@property TextObject *translatedTextObject;
@property CGPoint dragLocationInsideUILabel;
@property ISColorWheel *colorWheel;

@property NSMutableDictionary <NSNumber *, TextObject *> *UILabelToTextObject;
@property NSMutableDictionary <NSNumber *, UILabel *> *TextObjectToUILabel;

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
        if ([textObject.fontSize floatValue] > 70.0) self.textField.font = [UIFont fontWithName:textObject.font size:70.0];
        else self.textField.font = [UIFont fontWithName:textObject.font size:[textObject.fontSize intValue]];
        self.textField.textColor = [UIColor colorWithRed:[textObject.color_r floatValue] green:[textObject.color_g floatValue] blue:[textObject.color_b floatValue] alpha:1.0];
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
    label.textColor = [UIColor colorWithRed:[textObject.color_r floatValue] green:[textObject.color_g floatValue] blue:[textObject.color_b floatValue] alpha:1.0];
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
    [self updateUILabelUsingTextObject:textObject];
    [self updateUILabelLocationScaleRotationWithTextObject:textObject];
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
    [self updateUILabelUsingTextObject:_editedTextObject];
}

- (void)updateUILabelUsingTextObject: (TextObject *) textObject {
    UILabel *label = [_TextObjectToUILabel objectForKey:[NSNumber numberWithUnsignedLong:[textObject hash]]];
    UIFont *font = [UIFont fontWithName:textObject.font size:[textObject.fontSize floatValue]*[textObject.scale floatValue]];
    CGSize textSize = [textObject.text sizeWithAttributes:@{NSFontAttributeName:font}];
    label.text = textObject.text;
    label.font = font;
    label.textColor = [UIColor colorWithRed:[textObject.color_r floatValue] green:[textObject.color_g floatValue] blue:[textObject.color_b floatValue] alpha:1.0];
    label.frame = CGRectMake([textObject.location_x floatValue]-textSize.width/2, [textObject.location_y floatValue], textSize.width, textSize.height);
}

#pragma mark - ISColorWheelDelegate methods

- (void)colorWheelDidChangeColor:(ISColorWheel *)colorWheel {
    _textField.textColor = colorWheel.currentColor;
}

#pragma mark - UISlider methods

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

- (void)updateTextObject: (TextObject *) textObject withLocation: (CGPoint) location {
    textObject.location_x = [NSNumber numberWithFloat: location.x - _dragLocationInsideUILabel.x];
    textObject.location_y = [NSNumber numberWithFloat: location.y - _dragLocationInsideUILabel.y];
    [self updateUILabelLocationScaleRotationWithTextObject:textObject];
}

- (void)updateTextObject: (TextObject *) textObject WithScale: (float) scale {
    textObject.scale = [NSNumber numberWithFloat:scale];
    [self updateUILabelLocationScaleRotationWithTextObject:textObject];
}

- (void)updateTextObject: (TextObject *) textObject WithRotation: (float) rotation {
    textObject.rotation = [NSNumber numberWithFloat:rotation];
    [self updateUILabelLocationScaleRotationWithTextObject:textObject];
}

- (void)updateUILabelLocationScaleRotationWithTextObject: (TextObject *) textObject {
    UILabel *label = [_TextObjectToUILabel objectForKey:[NSNumber numberWithUnsignedLong:[textObject hash]]];
    UIFont *font = [UIFont fontWithName:textObject.font size:[textObject.fontSize floatValue]*[textObject.scale floatValue]];
    CGSize textSize = [textObject.text sizeWithAttributes:@{NSFontAttributeName:font}];
    label.font = font;
    label.frame = CGRectMake([textObject.location_x floatValue], [textObject.location_y floatValue], textSize.width, textSize.height);
    //label.bounds = CGRectMake([textObject.location_x floatValue], [textObject.location_y floatValue], textSize.width, textSize.height);
    //label.center = CGPointMake(label.bounds.origin.x+label.bounds.size.width/2, label.bounds.origin.y+label.bounds.size.height/2);
    label.transform = CGAffineTransformMakeRotation([textObject.rotation floatValue]);
    _translatedTextObject = textObject;
}

- (void)endTranslation {
    [_translatedTextObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * __nullable error) {
        if (succeeded) NSLog(@"SAVED");
        else NSLog(@"%@",error);
    }];
    _translatedTextObject.fontSize = [NSNumber numberWithFloat:[_translatedTextObject.fontSize floatValue]*[_translatedTextObject.scale floatValue]];
    _translatedTextObject.scale = [NSNumber numberWithFloat:1.0];
    _translatedTextObject = nil;
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
    TextObject *textEdited = [_UILabelToTextObject objectForKey: [NSNumber numberWithUnsignedLong: [sender.view hash]]];
    _editedTextObject = textEdited;
    [self beginEditingWithTextObject:textEdited];
}

- (IBAction)userDraggedUILabel:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) _dragLocationInsideUILabel = [sender locationInView:sender.view];
    TextObject *textEdited = [_UILabelToTextObject objectForKey: [NSNumber numberWithUnsignedLong: [sender.view hash]]];
    [self updateTextObject:textEdited withLocation:[sender locationInView:_canvas]];
    if (sender.state == UIGestureRecognizerStateEnded) [self endTranslation];
}

- (IBAction)userScaledUILabel:(UIPinchGestureRecognizer *)sender {
    TextObject *textEdited = [_UILabelToTextObject objectForKey: [NSNumber numberWithUnsignedLong: [sender.view hash]]];
    [self updateTextObject:textEdited WithScale:sender.scale];
    //[self updateTextObject:textEdited withLocation:[sender locationInView:_canvas]];
    if (sender.state == UIGestureRecognizerStateEnded) [self endTranslation];
}

- (IBAction)userRotatedUILabel:(UIRotationGestureRecognizer *)sender {
    TextObject *textEdited = [_UILabelToTextObject objectForKey: [NSNumber numberWithUnsignedLong: [sender.view hash]]];
    [self updateTextObject:textEdited WithRotation:sender.rotation];
    //[self updateTextObject:textEdited withLocation:[sender locationInView:_canvas]];
    if (sender.state == UIGestureRecognizerStateEnded) [self endTranslation];
}

#pragma mark - text field delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self endEditing];
    return NO;
}

@end
