#import <Foundation/Foundation.h>

@interface MouseEventTap : NSObject
{
  BOOL exit;
  BOOL running;
}

- (void)stop;
- (void)start;

@end