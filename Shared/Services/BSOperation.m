//
//  BSOperation.m
//  Basil Salad Commons
//
//  Created by Sasmito Adibowo on 31/07/10.
//  Copyright 2010 Basil Salad Software. All rights reserved.
//  http://basil-salad.com

#import "BSOperation.h"
#import "BSErrors.h"
#import "FoundationAdditionsMacros.h"

@implementation BSOperation

@synthesize userInfo;
@synthesize operationError;

-(void) dealloc {
	self.userInfo = nil;
	self.operationError = nil;
	[super dealloc];
}


-(void) handleException:(NSException*) e {
	if ([e respondsToSelector:@selector(callStackSymbols)]) {
		NSArray* symbols = [(id)e callStackSymbols];
		ErrorLog(@"Unhandled exception %@ symbols: %@",e,symbols);
	}
	NSMutableDictionary* errorInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	[errorInfo setObject:[NSString localizedStringWithFormat:@"Unhandled exception caught in %s: %@",__FUNCTION__,e] forKey:NSLocalizedDescriptionKey];
	NSError* existingError = self.operationError;
	if (existingError) {
		[errorInfo setObject:existingError forKey:NSUnderlyingErrorKey];
	}
	[errorInfo setObject:e forKey:BSUnderlyingExceptionErrorKey];
	
	self.operationError = [NSError errorWithDomain:BSCommonsErrorDomain code:BSUnhandledExceptionError userInfo:errorInfo];	
}

@end
