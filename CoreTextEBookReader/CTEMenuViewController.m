//
//  MenuViewController.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEMenuViewController.h"
#import "CTEChapter.h"
#import "CTEConstants.h"

@implementation CTEMenuViewController

@synthesize screenShotImageView;
@synthesize screenShotImage;
@synthesize tapGesture;
@synthesize panGesture;
@synthesize chapterTableView;
@synthesize chapterData;

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create a UITapGestureRecognizer to detect when the screenshot recieves a single tap
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                         action:@selector(singleTapScreenShot:)];
    [screenShotImageView addGestureRecognizer:tapGesture];
    
    // create a UIPanGestureRecognizer to detect when the screenshot is touched and dragged
    panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                         action:@selector(panGestureMoveAround:)];
    [panGesture setMaximumNumberOfTouches:2];
    [panGesture setDelegate:self];
    [screenShotImageView addGestureRecognizer:panGesture];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    // remove the gesture recognizers
    [self.screenShotImageView removeGestureRecognizer:self.tapGesture];
    [self.screenShotImageView removeGestureRecognizer:self.panGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    //always select first row if nothing selected
    if([chapterTableView indexPathForSelectedRow] == nil) {
        NSIndexPath *indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
        [chapterTableView selectRowAtIndexPath:indexPath animated:YES
                                scrollPosition:UITableViewScrollPositionTop];
     }

    CGRect imageFrame = self.view.frame;
    CGSize imageSize = imageFrame.size;
    
    // when the menu view appears, it will create the illusion that the other view has slide to the side
    // what its actually doing is sliding the screenShotImage passed in off to the side
    // to start this, we always want the image to be the entire screen, so set it there
    [screenShotImageView setImage:self.screenShotImage];
    [screenShotImageView setFrame:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    
    // now we'll animate it across to the right over 0.2 seconds with an Ease In and Out curve
    // this uses blocks to do the animation. Inside the block the frame of the UIImageView has its
    // x value changed to where it will end up with the animation is complete.
    // this animation doesn't require any action when completed so the block is left empty
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect newImageFrame = self.view.frame;
                         CGSize newImageSize = newImageFrame.size;
                         [screenShotImageView setFrame:CGRectMake(265, 0, newImageSize.width, newImageSize.height)];
                     }
                     completion:^(BOOL finished){  }];
}


// table view impl
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60; //TODO a constant?
}

// table view impl
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1; //TODO a constant?
}

// table view impl
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [chapterData count];
}

// table view impl
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TOCCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        
        //75 47 29 -- WTR cover brown
        //TODO needs to be adjustable
        UIColor *cellSelectedColor = [UIColor colorWithRed:(75.0f / 255.0f) green:(47.0 / 255.0f) blue:(29.0f / 255.0f) alpha:1.0f];
        cell.selectedBackgroundView.backgroundColor = cellSelectedColor;
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
        cell.detailTextLabel.highlightedTextColor = [UIColor whiteColor];
    }

    id <CTEChapter> chapter = [self.chapterData objectAtIndex:indexPath.row];
    cell.textLabel.text = chapter.title;
    cell.detailTextLabel.text = chapter.subtitle;

    return cell;
}

// table view row selection: selects new chapter
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self slideThenHide];
}

// this animates the screenshot back to the left before telling the app delegate to swap out the MenuViewController
// it tells the app delegate using the completion block of the animation
-(void) slideThenHide {
    NSIndexPath *indexPath = [chapterTableView indexPathForSelectedRow];
    __block id <CTEChapter> chapter = [self.chapterData objectAtIndex:indexPath.row];
    [UIView animateWithDuration:0.15
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [screenShotImageView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished){
                         [[NSNotificationCenter defaultCenter] postNotificationName:HideSideMenu object:chapter];
                     }];
}

//TODO this might change...
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//on a single tap of the screenshot, assume the user is done viewing the menu
//and call slideThenHide
- (void)singleTapScreenShot:(UITapGestureRecognizer *)gestureRecognizer {
    [self slideThenHide];
}


//The following is from http://blog.shoguniphicus.com/2011/06/15/working-with-uigesturerecognizers-uipangesturerecognizer-uipinchgesturerecognizer/

//Pan gesture impl
-(void)panGestureMoveAround:(UIPanGestureRecognizer *)gesture {
    UIView *piece = [gesture view];
    [self adjustAnchorPointForGestureRecognizer:gesture];
    
    if ([gesture state] == UIGestureRecognizerStateBegan || [gesture state] == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture translationInView:[piece superview]];
        
        //image view cannont move vertically
        [piece setCenter:CGPointMake([piece center].x + translation.x, [piece center].y)];
        [gesture setTranslation:CGPointZero inView:[piece superview]];
    }
    else if ([gesture state] == UIGestureRecognizerStateEnded)
        [self slideThenHide];
}

//Pan gesture impl
- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

@end
