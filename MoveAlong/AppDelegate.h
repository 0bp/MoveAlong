#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "MouseEventTap.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>
{
  NSMutableArray * windowArray;
  NSStatusItem * statusItem;
  NSMenu * statusMenu;
  MouseEventTap * mouse;
  NSArray * arrayOfRects;
}

@property (unsafe_unretained) IBOutlet NSPanel *aboutPanel;
@property (assign) IBOutlet NSWindow *window;
@property (strong) NSStatusItem *statusItem;
@property (retain) NSMenuItem * selectedItem;
@property (retain) NSDictionary * selectedWindow;
@property (retain) NSArray * windows;

- (IBAction)clickMovieAlong:(id)sender;
- (void)updateWindowArray;
- (NSDictionary *)getWindowById:(NSInteger)windowId;
- (NSSize) screenResolution;
- (NSInteger)segmentForPoint:(NSPoint)point;
- (NSPoint)centerPointFromRect:(NSRect)rect;
- (void)moveWindowRect:(NSRect)rect toSegment:(NSInteger)segment;
- (void)runScript:(NSString *)script;

@end