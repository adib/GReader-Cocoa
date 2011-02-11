//
//  FoundationAdditionsMacros.h
//  Basil Salad Commons
//
//  Created by Sasmito Adibowo on 27-12-10.
//  Copyright 2010 Basil Salad Software. All rights reserved.
//  http://basil-salad.com

#import <Cocoa/Cocoa.h>
/*
 Macros and inline functions of FoundationAdditions
 */


/**
 The number of elements in a C static array.
 (this macro should be a C standard. not sure why).
 */
#define ARRAY_COUNT(x)		(sizeof(x)/sizeof(x[0]))

/***************  Logging Macros  *******************/

/*
 - DebugLog		-- only compiled in whenever NDEBUG is not defined.
 - InfoLog		-- only executed when the global variable NSDebugEnabled is true or NDEBUG is not defined
 -- ErrorLog	-- always executed.
 */

#ifndef NDEBUG
#define DebugLog(string,...)  NSLog(@"[DEBUG]\t%s:%d %s\t" string,__FILE__,__LINE__,__FUNCTION__,##__VA_ARGS__)
#else
#define DebugLog(string,...)  ((void)0)
#endif

#ifndef NDEBUG
#define InfoLog(string,...)	NSLog(@"[INFO]\t%s\t" string,__FUNCTION__,##__VA_ARGS__)
#else
#define InfoLog(string,...)	if(NSDebugEnabled) { NSLog(@"[INFO]\t%s\t" string,__FUNCTION__,##__VA_ARGS__); }
#endif


#define ErrorLog(string,...)  NSLog(@"[ERROR]\t%s\t" string,__FUNCTION__,##__VA_ARGS__)




#ifndef NDEBUG
#if TARGET_IPHONE_SIMULATOR
#define PRIMITIVE_Break() \
__asm { int 3 };
#elif TARGET_OS_IPHONE
#define PRIMITIVE_Break() \
asm {trap};
#endif
#else
// define as null-op
#define PRIMITIVE_Break() 
#endif


#define NSBOOL(_X_) ((_X_) ? (id)kCFBooleanTrue : (id)kCFBooleanFalse)

inline static NSString* BSNotNilString(NSString* str) {
	return str ? str : @"";
}

inline static id BSNotNilObject(id obj) {
	return obj ? obj : [NSNull null];
}

