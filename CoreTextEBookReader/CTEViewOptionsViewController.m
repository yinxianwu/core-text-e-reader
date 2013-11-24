//
//  CTEContentPopoverViewController.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/18/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEViewOptionsViewController.h"
#import "CTEMarkupParser.h"
#import "CTEConstants.h"
#import <QuartzCore/QuartzCore.h>

@interface CTEViewOptionsViewController () {
    NSNumberFormatter *formatter;
}

@end

@implementation CTEViewOptionsViewController

@synthesize pickerView;
@synthesize fonts;
@synthesize fontSizes;
@synthesize columns;
@synthesize selectedFont;
@synthesize selectedFontSize;
@synthesize selectedColumnsInView;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
         selectedFont:(NSString *)fontKey
     selectedFontSize:(NSNumber *)fontSize
selectedColumnsInView:(NSNumber *)columnsInView {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        NSDictionary *bodyFonts = [CTEMarkupParser bodyFontDictionary];
        self.fonts = [[bodyFonts allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        self.selectedFont = fontKey;
        self.selectedFontSize = fontSize;
        self.selectedColumnsInView = columnsInView;
        self.fontSizes = @[@"16", @"18", @"20", @"24", @"28"];
        self.columns = @[@"One Column", @"Two Columns"];

        formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterNoStyle];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //give font buttons a background color
    //[UIColor colorWithRed:14.0f/255 green:104.0f/255 blue: 228.0f/255 alpha:1.0f]]
//    [self.fontSmallerButton setBackgroundImage:[self imageFromColor:[UIColor darkGrayColor]]
//                                      forState:UIControlStateNormal];
//    self.fontSmallerButton.layer.cornerRadius = 8.0;
//    self.fontSmallerButton.layer.masksToBounds = YES;
//    self.fontSmallerButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
//    self.fontSmallerButton.layer.borderWidth = 1;
//    [self.fontLargerButton setBackgroundImage:[self imageFromColor:[UIColor darkGrayColor]]
//                                     forState:UIControlStateNormal];
//    self.fontLargerButton.layer.cornerRadius = 8.0;
//    self.fontLargerButton.layer.masksToBounds = YES;
//    self.fontLargerButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
//    self.fontLargerButton.layer.borderWidth = 1;

    //horizontal line after title
    //http://stackoverflow.com/questions/6254556/how-to-draw-a-line-in-interface-builder-in-xcode-4
    float width = self.view.bounds.size.width;
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 30, width, 1.0f)];
    line.backgroundColor = [UIColor darkGrayColor];//[UIColor colorWithRed:(200.0f/255.0f) green:(200.0f/255.0f) blue:(200.0f/255.0f) alpha:1.0f];
    line.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    line.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    line.layer.shadowRadius = 0.5f;
    line.layer.shadowOpacity = 0.4f;
    line.layer.masksToBounds = NO;
    [self.view addSubview:line];
    
    //set selections in picker
    NSString *fontSizeStr = [formatter stringFromNumber:self.selectedFontSize];

    [self.pickerView setShowsSelectionIndicator:YES];
    int selectedFontIndex = [self.fonts indexOfObject:self.selectedFont];
    int selectedFontSizeIndex = [self.fontSizes indexOfObject:fontSizeStr];
    int selectedColumnsIndex = 1; //TODO mapping//[self.fonts indexOfObject:@"Two Columns"];
    [self.pickerView selectRow:selectedFontIndex inComponent:0 animated:NO];
    [self.pickerView selectRow:selectedFontSizeIndex inComponent:1 animated:NO];
    [self.pickerView selectRow:selectedColumnsIndex inComponent:2 animated:NO];
}

//prevents popover from stretching to max height
-(CGSize)contentSizeForViewInPopover {
    return self.view.bounds.size;
}

//button background
- (UIImage *)imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

#pragma mark - UIPickerView DataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSInteger rows = 0;
    if(component == 0) {
        rows = [fonts count];
    }
    else if(component == 1) {
        rows = [fontSizes count];
    }
    else if(component == 2) {
        rows = [columns count];
    }
    
    return rows;
}

#pragma mark - UIPickerView Delegate

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 30.0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    CGFloat width = 0.0;
    if(component == 0) {
        width = 260.0;
    }
    else if(component == 1) {
        width = 80.0;
    }
    else if(component == 2) {
        width = 200.0;
    }
    
    return width;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title = @"";
    if(component == 0) {
        title = [fonts objectAtIndex:row];
    }
    else if(component == 1) {
        title = [fontSizes objectAtIndex:row];
    }
    else if(component == 2) {
        title = [columns objectAtIndex:row];
    }
    
    return title;
}

//select option and post notification
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(component == 0) {
        self.selectedFont = (NSString *)[fonts objectAtIndex:row];
        [[NSNotificationCenter defaultCenter] postNotificationName:ChangeFont object:self.selectedFont];
    }
    else if(component == 1) {
        NSNumber *fontSizeNb = [formatter numberFromString:(NSString *)[fontSizes objectAtIndex:row]];
        self.selectedFontSize = fontSizeNb;
        [[NSNotificationCenter defaultCenter] postNotificationName:ChangeFontSize object:self.selectedFontSize];
    }
    else if(component == 2) {
        self.selectedColumnsInView = [NSNumber numberWithInt:(row + 1)];
        [[NSNotificationCenter defaultCenter] postNotificationName:ChangeColumnCount object:self.selectedColumnsInView];
    }
}

@end
