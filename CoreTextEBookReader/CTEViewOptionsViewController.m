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
    NSString *prevSelectedFont;
    NSNumber *prevSelectedFontSize;
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
@synthesize backgroundHeader;
@synthesize barColor;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
         selectedFont:(NSString *)fontKey
     selectedFontSize:(NSNumber *)fontSize
selectedColumnsInView:(NSNumber *)columnsInView
             barColor:(UIColor *)color {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        NSDictionary *bodyFonts = [CTEMarkupParser bodyFontDictionary];
        self.fonts = [[bodyFonts allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        self.selectedFont = fontKey;
        self.selectedFontSize = fontSize;
        self.selectedColumnsInView = columnsInView;
        
        //cache prev values
        prevSelectedFont = self.selectedFont;
        prevSelectedFontSize = self.selectedFontSize;
        
        self.fontSizes = @[@"16", @"18", @"20", @"24", @"28"];
        self.columns = @[@"One Column", @"Two Columns"];
        self.barColor = color;

        formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterNoStyle];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //horizontal line after title
    //http://stackoverflow.com/questions/6254556/how-to-draw-a-line-in-interface-builder-in-xcode-4
    float width = self.view.bounds.size.width;
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 32, width, 1.0f)];
    line.backgroundColor = [UIColor darkGrayColor];
    line.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    line.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    line.layer.shadowRadius = 0.5f;
    line.layer.shadowOpacity = 0.4f;
    line.layer.masksToBounds = NO;
    [self.view addSubview:line];
    
    //title background color for bars
    backgroundHeader.backgroundColor = self.barColor;
   
    //set selections in picker
    NSString *fontSizeStr = [formatter stringFromNumber:self.selectedFontSize];

    [self.pickerView setShowsSelectionIndicator:YES];
    long selectedFontIndex = [self.fonts indexOfObject:self.selectedFont];
    long selectedFontSizeIndex = [self.fontSizes indexOfObject:fontSizeStr];
    long selectedColumnsIndex = [self.selectedColumnsInView longValue] - 1;
    [self.pickerView selectRow:selectedFontIndex inComponent:0 animated:NO];
    [self.pickerView selectRow:selectedFontSizeIndex inComponent:1 animated:NO];

    //column selection only applicable for iPads
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) {
        [self.pickerView selectRow:selectedColumnsIndex inComponent:2 animated:NO];
    }
}

//Handles format changes for iPhone
//Due to memory and performance considerations, iPhone format changes
//are done "all in one" after user closes this view
- (void)viewDidDisappear:(BOOL)animated {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        NSMutableDictionary *changeDict = [NSMutableDictionary dictionaryWithCapacity:2];
        if(![self.selectedFont isEqualToString:prevSelectedFont]) {
            [changeDict setValue:self.selectedFont forKey:ChangeFont];
        }
        if(![self.selectedFontSize isEqualToNumber:prevSelectedFontSize]) {
            [changeDict setValue:self.selectedFont forKey:ChangeFont];
        }
        
        if([changeDict count] > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ChangeFormat object:changeDict];
        }
    }
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return 2;
    }
    else {
        return 3;
    }
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
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if(component == 0) {
            width = 240.0;
        }
        else if(component == 1) {
            width = 80.0;
        }
    }
    else {
        if(component == 0) {
            width = 260.0;
        }
        else if(component == 1) {
            width = 80.0;
        }
        else if(component == 2) {
            width = 200.0;
        }
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
//on iPhone, only do this when view disappears
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(component == 0) {
        self.selectedFont = (NSString *)[fonts objectAtIndex:row];
        //only fire events on iPad; on iPhone they happen after view is closed
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ChangeFont object:self.selectedFont];
        }
    }
    else if(component == 1) {
        NSNumber *fontSizeNb = [formatter numberFromString:(NSString *)[fontSizes objectAtIndex:row]];
        self.selectedFontSize = fontSizeNb;
        //only fire events on iPad; on iPhone they happen after view is closed
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ChangeFontSize object:self.selectedFontSize];
        }
    }
    //columns can only be set on iPad
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if(component == 2) {
            self.selectedColumnsInView = [NSNumber numberWithInt:(row + 1)];
            [[NSNotificationCenter defaultCenter] postNotificationName:ChangeColumnCount object:self.selectedColumnsInView];
        }
    }
}

@end
