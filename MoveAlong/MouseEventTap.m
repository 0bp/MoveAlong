#import "MouseEventTap.h"

@implementation MouseEventTap

static CGEventRef myEventTapCallback (CGEventTapProxy proxy, CGEventType type, CGEventRef event, void * refcon) 
{
  CGPoint mouseLocation;
  mouseLocation = CGEventGetLocation(event);
  
  NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSString stringWithFormat:@"%u", (unsigned int)mouseLocation.x], @"x", 
    [NSString stringWithFormat:@"%u", (unsigned int)mouseLocation.y], @"y", 
    nil
  ];
  
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"mousePositionChanged" 
                                                      object:nil 
                                                    userInfo:userInfo];
  
  return event;
} 

- (void)start
{
  if(running) return;
  
  exit = NO;
  running = YES;
  
  dispatch_queue_t queue = dispatch_queue_create("com.example.myqueue", NULL);
  dispatch_async(queue, ^{
    CGEventMask emask;
    CFMachPortRef myEventTap;
    CFRunLoopSourceRef eventTapRLSrc;
                   
    emask = CGEventMaskBit(kCGEventMouseMoved) | 
    CGEventMaskBit(kCGEventLeftMouseDown) | 
    CGEventMaskBit(kCGEventLeftMouseDragged);
                   
    myEventTap = CGEventTapCreate (kCGSessionEventTap,
                                   kCGTailAppendEventTap,
                                   kCGEventTapOptionListenOnly,
                                   emask,
                                   &myEventTapCallback,
                                   NULL);
                   
    eventTapRLSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault,myEventTap,0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(),eventTapRLSrc,kCFRunLoopDefaultMode);
                   
    do
    {
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, true);
    }
    while (!exit);
                   
    CGEventTapEnable(myEventTap, false);
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(),eventTapRLSrc,kCFRunLoopDefaultMode);
    CFRelease(myEventTap);
    CFRelease(eventTapRLSrc);
                   
    running = NO;
    dispatch_release(queue);

  });
}

- (void)stop
{
  exit = YES;
}

@end