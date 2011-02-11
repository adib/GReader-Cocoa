//
//  GoogleReaderAPITestAppDelegate.m
//  GoogleReaderAPITest
//
//  Created by Sasmito Adibowo on 30-01-11.
//  Copyright 2011 Basil Salad Software. All rights reserved.
//  http://basil-salad.com

#import "GoogleReaderAPITestAppDelegate.h"
#import "FoundationAdditionsMacros.h"
#import "BSGoogleReaderListSubscriptionsOperation.h"

@implementation GoogleReaderAPITestAppDelegate

@synthesize window;
@synthesize feeds;
@synthesize loginTextField;
@synthesize passwordTextField;
@synthesize operationQueue;

-(void) dealloc {
    [feeds release];
    [super dealloc];
}

#pragma mark Property Access 

/*
-(NSMutableArray*) feeds {
    if (!feeds) {
        feeds = [[NSMutableArray alloc] initWithCapacity:11];
        
        NSMutableDictionary* entry1 = [NSMutableDictionary dictionaryWithCapacity:3];
        [feeds addObject:entry1];
        [entry1 setObject:@"Category 1" forKey:@"title"];

        NSMutableArray* entry1feeds = [NSMutableArray arrayWithCapacity:3];
        [entry1 setObject:entry1feeds forKey:@"children"];

        NSMutableDictionary* entry1feed1 = [NSMutableDictionary dictionaryWithCapacity:3];
        [entry1feed1 setObject:@"Feed 1" forKey:@"title"];
        [entry1feeds addObject:entry1feed1];

        NSMutableDictionary* entry1feed2 = [NSMutableDictionary dictionaryWithCapacity:3];
        [entry1feed2 setObject:@"Feed 2" forKey:@"title"];
        [entry1feeds addObject:entry1feed2];
        
        NSMutableDictionary* entry1feed3 = [NSMutableDictionary dictionaryWithCapacity:3];
        [entry1feed3 setObject:@"Feed 3" forKey:@"title"];
        [entry1feeds addObject:entry1feed3];
        
        NSMutableDictionary* entry2 = [NSMutableDictionary dictionaryWithCapacity:3];
        [feeds addObject:entry2];
        [entry2 setObject:@"Category 2" forKey:@"title"];
        [entry2 setObject:[NSNumber numberWithBool:YES] forKey:@"checked"];

        NSMutableDictionary* entry3 = [NSMutableDictionary dictionaryWithCapacity:3];
        [feeds addObject:entry3];
        [entry3 setObject:@"Category 3" forKey:@"title"];

    }
    return feeds;
    
}*/

-(void) haveGoogleReaderData:(BSGoogleReaderListSubscriptionsOperation*) oper {
    NSError* operationError = oper.operationError;
    if (operationError) {
        NSAlert* alert = [NSAlert alertWithError:operationError];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        return;
    }
    
    // repack result data into a format suitable for the outline view.
    NSArray* feedData = oper.resultFeeds;
    NSUInteger feedDataCount = feedData.count;

    NSMutableArray* result = [NSMutableArray arrayWithCapacity:feedDataCount];
    NSMutableDictionary* categories = [NSMutableDictionary dictionaryWithCapacity:feedDataCount];
    
    for(NSDictionary* feed in feedData) {
        NSArray* feedCategories = [feed objectForKey:BSGoogleReaderCategoriesKey];

        NSMutableDictionary* feedEntry = [NSMutableDictionary dictionaryWithCapacity:feed.count+2];
        [feedEntry addEntriesFromDictionary:feed];
        [feedEntry setObject:[feed objectForKey:BSGoogleReaderTitleKey] forKey:@"title"];
        [feedEntry setObject:[[feed objectForKey:BSGoogleReaderFeedURLKey] absoluteString] forKey:@"url"];
        
        if (feedCategories.count == 0) {
            [result addObject:feedEntry];
            continue;
        } 
        
        for(NSDictionary* feedCategory in feedCategories) {
            NSString* categoryID = [feedCategory objectForKey:BSGoogleReaderItemIDKey];
            NSMutableDictionary* category = [categories objectForKey:categoryID];
            if (!category) {
                category = [NSMutableDictionary dictionaryWithCapacity:2];                
                [category setObject:[NSMutableArray arrayWithCapacity:feedDataCount] forKey:@"children"];
                [category setObject:[feedCategory objectForKey:BSGoogleReaderTitleKey] forKey:@"title"];
                [categories setObject:category forKey:categoryID];
            }
            NSMutableArray* feedAssignments = [category objectForKey:@"children"];
            [feedAssignments addObject:feedEntry];
        }
    }
    
    [result addObjectsFromArray:[categories allValues]];
    self.feeds = result;
    
    
}

-(IBAction) runFetch:(id) sender {
    BSGoogleReaderListSubscriptionsOperation* oper = [[[BSGoogleReaderListSubscriptionsOperation alloc] initWithTarget:self selector:@selector(haveGoogleReaderData:) thread:[NSThread mainThread]] autorelease];
    oper.login = [loginTextField stringValue];
    oper.password = [passwordTextField stringValue];
    [operationQueue addOperation:oper];
    
}

#pragma mark NSApplicationDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}

#pragma mark NSOutlineViewDelegate

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    
    //NSLog(@"item: %@ represented: %@",item, [item representedObject]);
    NSDictionary* data = [item representedObject];

    NSString* identifier = [tableColumn identifier];
    if ([@"main" isEqualToString:identifier]) {
        NSButtonCell* buttonCell = cell;
        [buttonCell setObjectValue:[data objectForKey:@"checked"]];
        [buttonCell setTitle:[data objectForKey:@"title"]];
  
    } else if ([@"url" isEqualToString:identifier]) {
        [cell setTitle:BSNotNilString([data objectForKey:@"url"])];
    } 


}

@end
