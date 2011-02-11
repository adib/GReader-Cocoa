//
//  GoogleReaderAPITestAppDelegate.h
//  GoogleReaderAPITest
//
//  Created by Sasmito Adibowo on 30-01-11.
//  Copyright 2011 Basil Salad Software. All rights reserved.
//  http://basil-salad.com

#import <Cocoa/Cocoa.h>

@interface GoogleReaderAPITestAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    NSOperationQueue *operationQueue;
    NSMutableArray* feeds;
    NSTextField* loginTextField;
    NSTextField* passwordTextField;
}

@property (assign) IBOutlet NSTextField* loginTextField;
@property (assign) IBOutlet NSTextField* passwordTextField;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSOperationQueue *operationQueue;

@property (nonatomic,retain) NSMutableArray* feeds;

-(IBAction) runFetch:(id) sender;
@end
