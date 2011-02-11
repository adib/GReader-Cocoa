#import <Foundation/Foundation.h>

#import "CJSONDataSerializer.h"
#import "CJSONDeserializer.h"

int main (int argc, const char * argv[])
{
NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];


NSDictionary *theDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
    @"Hello", @"World",
    NULL];
    
CJSONDataSerializer *theSerializer = [CJSONDataSerializer serializer];
CJSONDeserializer *theDeserializer = [CJSONDeserializer deserializer];

NSData *theData = [theSerializer serializeObject:theDictionary error:NULL];

CFAbsoluteTime theStart = CFAbsoluteTimeGetCurrent();
for (int N = 0; N != 2000000; ++N)
    {
////    [theDeserizl serializeObject:theDictionary error:NULL];
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
    [theDeserializer deserialize:theData error:NULL];
    [thePool release];
    }



CFAbsoluteTime theEnd = CFAbsoluteTimeGetCurrent();

NSLog(@"%g", theEnd - theStart);


[pool drain];
return 0;
}
