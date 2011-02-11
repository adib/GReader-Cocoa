//
//  BSCallbackOperation
//  Basil Salad Commons
//
//  Created by Sasmito Adibowo on 31/07/10.
//  Copyright 2010 Basil Salad Software. All rights reserved.
//  http://basil-salad.com

#import "BSCallbackOperation.h"
#import "FoundationAdditionsMacros.h"
#import "BSErrors.h"


@implementation BSCallbackOperation

-(void) performOperation {
	ErrorLog(@"No default implementation.");
}


-(id) initWithTarget:(id)target selector:(SEL)selector thread:(NSThread*)threadOrNil {
	if (self = [super init]) {
		callbackThread = [threadOrNil retain];
		callbackTarget = [target retain];
		callbackSelector = selector;
	}
	return self;
}

-(void) dealloc {
	[callbackTarget release];
	[callbackThread release];
	[super dealloc];
}


/*!
 Calls the callback object with 'self' as the parameter.  This method blocks
 until the callback returns.  This should be used as the last step of an operation
 to return its result.
 */
-(void) returnSelf {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	@try {
		if (callbackThread) {
			[callbackTarget performSelector:callbackSelector 
								   onThread:callbackThread 
								 withObject:self
							  waitUntilDone:YES];
		} else {
			[callbackTarget performSelectorOnMainThread:callbackSelector withObject:self waitUntilDone:YES];
		}

	}
	@catch (NSException * e) {
		ErrorLog(@"Callback throwed an exception: %@ return addresses: %@",e, [e callStackReturnAddresses]);
	}
	@finally {
		[pool drain];
	}
}



-(void) main {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	@try {
		[self performOperation];
	}
	@catch (NSException* e) {
		ErrorLog(@"Uncaught exception: %@ addresses: %@",e,[e callStackReturnAddresses]);
		
		[self handleException:e];
	}
	@finally {
		[self returnSelf];
		[pool drain];
	}
}


@end
