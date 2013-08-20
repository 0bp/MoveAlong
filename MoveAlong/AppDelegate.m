#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window, statusItem, selectedItem, selectedWindow, windows, aboutPanel;

- (void) awakeFromNib
{
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength]; 
  
  statusMenu = [[NSMenu alloc] initWithTitle:@"MoveAlongMenulet"];
  statusMenu.delegate = self;
  
  [statusItem setMenu:statusMenu];
  [statusItem setImage:[NSImage imageNamed:@"menuicon_off"]];
  [statusItem setHighlightMode:YES];
  
  mouse = [[MouseEventTap alloc] init];
  [[NSNotificationCenter defaultCenter] addObserver:self 
                                           selector:@selector(mousePositionUpdate:) 
                                               name:@"mousePositionChanged" 
                                             object:nil];

  [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDraggedMask handler:^(NSEvent * event) {
    if(self.selectedWindow == nil)
    {
      return;
    }
    int winId = [[self.selectedWindow objectForKey:@"kCGWindowNumber"] intValue];
    self.selectedWindow = [self getWindowById:winId];
  }];
  
  [self setupScreen];
}

- (void)setupScreen
{
  NSSize screenSize = [self screenResolution];
  
  NSRect r1 = CGRectMake(0, 0, screenSize.width/2, screenSize.height/2);
  NSRect r2 = CGRectMake(screenSize.width/2, 0, screenSize.width/2, screenSize.height/2);
  NSRect r3 = CGRectMake(screenSize.width/2, screenSize.height/2, screenSize.width/2, screenSize.height/2);
  NSRect r4 = CGRectMake(4, screenSize.height/2, screenSize.width/2, screenSize.height/2);
  
  arrayOfRects = [NSArray arrayWithObjects:
    [NSValue valueWithRect:r1],
    [NSValue valueWithRect:r2],
    [NSValue valueWithRect:r3],
    [NSValue valueWithRect:r4],
    nil
  ];
}

- (NSInteger)segmentForPoint:(NSPoint)point
{
  int index = 0;
  for(NSValue * r in arrayOfRects)
  {
    NSRect rect = [r rectValue];
    if(NSPointInRect(point, rect))
    {
      return index;
    }
    index++;
  }
  return -1;
}

- (NSDictionary *)getWindowById:(NSInteger)windowId
{
  CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
  NSArray * wins = (__bridge_transfer NSArray *)windowList;
  for(NSDictionary * win in wins)
  {
    if([[win objectForKey:@"kCGWindowNumber"] intValue] == windowId)
    {
      return win;
    }
  }
  return nil;
}

- (void)updateWindowArray
{
  CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
  self.windows = (__bridge_transfer NSArray *)windowList;
  if(windowArray == nil) {
    windowArray = [[NSMutableArray alloc] init];
  } 
  else 
  {
    [windowArray removeAllObjects];
  }
}

-(void)menuWillOpen:(NSMenu *)menu
{
  if(menu != nil) [statusMenu removeAllItems];

  [self setupScreen];
  [self updateWindowArray];
  
  NSArray * validApplications = [NSArray arrayWithObjects:
    @"VLC",
    @"QuickTime Player",
    @"Plex",
    @"iTunes",
    @"EyeTV",
    @"Safari",
    @"Google Chrome",
    nil
  ];

  NSArray * ignoreWindows = [NSArray arrayWithObjects:
    @"",
    @"iTunes",
    @"Equalizer", 
    nil
  ];

  for(NSDictionary * win in self.windows) {

    if([validApplications containsObject:[win objectForKey:@"kCGWindowOwnerName"]])
    {
      if(![win objectForKey:@"kCGWindowName"] || 
          [ignoreWindows containsObject:[win objectForKey:@"kCGWindowName"]])
      {
        continue;
      } 
      
      [windowArray addObject:win];

      if(menu != nil)
      {
        NSMenuItem * item = [[NSMenuItem alloc] initWithTitle:[win objectForKey:@"kCGWindowName"] 
                                                       action:@selector(clickMenuItem:) 
                                                keyEquivalent:@""];

        item.tag = [[win objectForKey:@"kCGWindowNumber"] intValue];
        
        if(item.tag == self.selectedItem.tag)
        {
          item.state = 1;
        }
        
        NSDictionary * bounds = [win objectForKey:@"kCGWindowBounds"];
        
        int windowWidth = [[bounds objectForKey:@"Width"] intValue];
        int windowHeight = [[bounds objectForKey:@"Height"] intValue];
        
        NSSize screenSize = [self screenResolution];
        
        if(windowWidth * windowHeight > (screenSize.width * screenSize.height)/4)
        {
          [item setEnabled:NO];
          [item setAction:nil];
        }
        
        if(!AXAPIEnabled()) 
        {
          if([[win objectForKey:@"kCGWindowOwnerName"] isEqualToString:@"Plex"] ||
             [[win objectForKey:@"kCGWindowOwnerName"] isEqualToString:@"iTunes"])
          {
            [item setEnabled:YES];
            [item setAction:@selector(enableAXAPI:)];
            [item setImage:[NSImage imageNamed:@"Caution"]];
          }
        }
        
        [statusMenu addItem:item];        
      }
      
      if([[win objectForKey:@"kCGWindowNumber"] intValue] == self.selectedItem.tag)
      {
        self.selectedWindow = win;
      }
    }
  }
  
  if(menu != nil)
  {
    if([windowArray count] == 0)
    {
      NSMenuItem * item = [[NSMenuItem alloc] initWithTitle:@"No Windows Available" 
                                                     action:@selector(test:) 
                                              keyEquivalent:@""];
      [item setEnabled:NO];
      [statusMenu addItem:item];
    }
    
    
    NSMenuItem * About = [[NSMenuItem alloc] initWithTitle:@"About MoveAlong" 
                                                    action:@selector(clickAbout:) 
                                             keyEquivalent:@""];

    NSMenuItem * Quit = [[NSMenuItem alloc] initWithTitle:@"Quit" 
                                                   action:@selector(clickQuit:) 
                                            keyEquivalent:@""];

    [statusMenu addItem:[NSMenuItem separatorItem]];
    [statusMenu addItem:About];
    [statusMenu addItem:Quit];
  }
}

- (void)enableAXAPI:(id)sender
{
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:@"OK"];
  [alert setMessageText:@"Please enable access for assistive devices."];
  [alert setInformativeText:@"To enable MoveAlong to work with iTunes or Plex, you have to enable access to assistive devices in System Preferences, Universion Access."];
  [alert setAlertStyle:NSWarningAlertStyle];
  
  [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction)clickAbout:(id)sender
{
  [NSApp activateIgnoringOtherApps:YES];
  [self.aboutPanel makeKeyAndOrderFront:nil];
}

- (IBAction)clickQuit:(id)sender
{
  [NSApp terminate: nil];
}

- (IBAction)clickMovieAlong:(id)sender 
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://penck.de/movealong/"]];
}

- (NSSize) screenResolution
{
  NSRect screenRect;
  NSArray *screenArray = [NSScreen screens];

  NSScreen *screen = [screenArray objectAtIndex: 0];
  screenRect = [screen visibleFrame];
  
  return screenRect.size;
}

- (void)resetSelection
{
  self.selectedItem = nil;
  self.selectedWindow = nil;
  [statusItem setImage:[NSImage imageNamed:@"menuicon_off"]];
  [mouse stop];  
}

- (void)clickMenuItem:(NSMenuItem *)sender
{
  if(self.selectedItem && self.selectedItem.tag == sender.tag) 
  {
    [self resetSelection];
    return;
  }

  [statusItem setImage:[NSImage imageNamed:@"menuicon_on"]];
  [mouse start];

  self.selectedItem = sender; 
  
  for(NSDictionary * dict in windowArray) 
  {
    NSString * winId = [NSString stringWithFormat:@"%@", [dict objectForKey:@"kCGWindowNumber"]];
    NSString * senderId = [NSString stringWithFormat:@"%ld", sender.tag];
    
    if([winId isEqualToString:senderId])
    {
      self.selectedWindow = dict;
    }
  }
}

- (void)mousePositionUpdate:(NSNotification *)notification
{
  if(self.selectedWindow == nil) return;
  
  int mouseX = [[[notification userInfo] objectForKey:@"x"] intValue];
  int mouseY = [[[notification userInfo] objectForKey:@"y"] intValue];
  
  NSDictionary * bounds = [self.selectedWindow objectForKey:@"kCGWindowBounds"];
  
  int windowX = [[bounds objectForKey:@"X"] intValue];
  int windowY = [[bounds objectForKey:@"Y"] intValue];
  int windowHeight = [[bounds objectForKey:@"Height"] intValue];
  int windowWidth = [[bounds objectForKey:@"Width"] intValue];

  NSPoint mousePoint = CGPointMake(mouseX, mouseY);
  NSRect windowRect = CGRectMake(windowX, windowY, windowWidth, windowHeight);
  
  if(NSPointInRect(mousePoint, windowRect))
  {
    NSInteger segment = [self segmentForPoint:[self centerPointFromRect:windowRect]];
    NSInteger nextSegment;
    
    if(segment < 3) {
      nextSegment = segment+1;
    } else {
      nextSegment = 0;
    }

    NSInteger windowId = [[self.selectedWindow objectForKey:@"kCGWindowNumber"] intValue];

    if([self getWindowById:windowId] == nil)
    {
      [self resetSelection];
      return;
    }
    
    if([[self.selectedWindow objectForKey:@"kCGWindowOwnerName"] isEqualToString:@"Plex"])
    {
      [self movePlexWindowRect:windowRect toSegment:nextSegment];
    } 
    else if([[self.selectedWindow objectForKey:@"kCGWindowOwnerName"] isEqualToString:@"iTunes"]) 
    {
      [self moveITunesWindowRect:windowRect toSegment:nextSegment];
    }
    else if([[self.selectedWindow objectForKey:@"kCGWindowOwnerName"] isEqualToString:@"EyeTV"]) 
    {
      [self moveEyeTVWindowRect:windowRect toSegment:nextSegment];
    }
    else if([[self.selectedWindow objectForKey:@"kCGWindowOwnerName"] isEqualToString:@"Google Chrome"])
    {
      [self moveChromeWindowRect:windowRect toSegment:nextSegment];
    }
    else
    {
      [self moveWindowRect:windowRect toSegment:nextSegment];
    }
    
  }
}

- (NSPoint)centerPointFromRect:(NSRect)rect
{
  return CGPointMake(
    rect.origin.x+(rect.size.width/2), 
    rect.origin.y+(rect.size.height/2)
  );
}

- (NSPoint)targetPointForRect:(NSRect)rect inSegment:(NSInteger)segment
{
  NSRect targetRect = [(NSValue *)[arrayOfRects objectAtIndex:segment] rectValue];
  NSPoint targetPoint;

  if(segment == 0)
  {
    targetPoint = CGPointMake(0, 0);
  }
  else if(segment == 1)
  {
    targetPoint = CGPointMake(
      (targetRect.origin.x + targetRect.size.width) - rect.size.width, 
      0
    );
  }
  else if(segment == 2)
  {
    targetPoint = CGPointMake(
      (targetRect.origin.x + targetRect.size.width) - rect.size.width, 
      (targetRect.origin.y + targetRect.size.height)- rect.size.height
    );
  }
  else if(segment == 3)
  {
    targetPoint = CGPointMake(
      0, 
      (targetRect.origin.y + targetRect.size.height)- rect.size.height
    );
  }
  return targetPoint;
}

#pragma mark -
#pragma mark AppleScripts

- (void)runScript:(NSString *)script
{
  NSAppleScript *run = [[NSAppleScript alloc] initWithSource:script];
  [run executeAndReturnError:nil];
  [self menuWillOpen:nil];  
}

- (void)moveEyeTVWindowRect:(NSRect)rect toSegment:(NSInteger)segment
{
  NSPoint targetPoint = [self targetPointForRect:rect inSegment:segment];
  
  NSString * script = [NSString stringWithFormat:
    @"tell application \"EyeTV\"\n"
    @"  repeat with win in windows\n"
    @"    if name of win is \"%@\" then\n"
    @"      set position of win to {%f, %f}\n"
    @"    end if\n"
    @"  end repeat\n"
    @"end tell\n",
    [self.selectedWindow objectForKey:@"kCGWindowName"],
    targetPoint.x,
    targetPoint.y+38
  ];
  
  [self runScript:script];
}

- (void)moveITunesWindowRect:(NSRect)rect toSegment:(NSInteger)segment
{
  NSPoint targetPoint = [self targetPointForRect:rect inSegment:segment];

  NSString * script = [NSString stringWithFormat:
    @"tell application \"System Events\"\n"
    @"  tell process \"iTunes\"\n"
    @"    repeat with win in windows\n"
    @"      if title of win is not \"iTunes\" then\n"
    @"        if title of win is not \"Equalizer\" then\n"
    @"          set position of win to {%f, %f}\n"
    @"        end if\n"
    @"      end if\n"
    @"    end repeat\n"
    @"  end tell\n"
    @"end tell\n",
    targetPoint.x,
    targetPoint.y+20
  ];

  [self runScript:script];
}

- (void)movePlexWindowRect:(NSRect)rect toSegment:(NSInteger)segment
{
  NSPoint targetPoint = [self targetPointForRect:rect inSegment:segment];
  
  NSString * script = [NSString stringWithFormat:
    @"tell application \"System Events\"\n"
    @"  tell process \"Plex\"\n"
    @"    tell window 1\n"
    @"      set position to {%f, %f}\n"
    @"    end tell\n"
    @"  end tell\n"
    @"end tell\n",
    targetPoint.x,
    targetPoint.y
  ];
  
  [self runScript:script];
}

- (void)moveWindowRect:(NSRect)rect toSegment:(NSInteger)segment
{
  NSPoint targetPoint = [self targetPointForRect:rect inSegment:segment];
  NSInteger windowId = [[self.selectedWindow objectForKey:@"kCGWindowNumber"] intValue];
  
  NSString * script = [NSString stringWithFormat:
    @"tell application \"%@\"\n"
    @" repeat with aWindow in windows\n"
    @"   if id of aWindow is %ld then\n"
    @"     set bounds of aWindow to {%f, %f, %f, %f}\n"
    @"   end if\n"
    @" end repeat\n"
    @"end tell\n", 
    [self.selectedWindow objectForKey:@"kCGWindowOwnerName"],
    windowId,
    targetPoint.x,
    targetPoint.y,
    targetPoint.x+rect.size.width,
    targetPoint.y+rect.size.height
  ];
  
  [self runScript:script];
}

- (void)moveChromeWindowRect:(NSRect)rect toSegment:(NSInteger)segment
{
  NSPoint targetPoint = [self targetPointForRect:rect inSegment:segment];
  
  NSString * script = [NSString stringWithFormat:
    @"tell application \"%@\"\n"
    @" repeat with aWindow in windows\n"
    @"   if name of aWindow is \"%@\" then\n"
    @"     set bounds of aWindow to {%f, %f, %f, %f}\n"
    @"   end if\n"
    @" end repeat\n"
    @"end tell\n"
    @"call method \"setWindowLevel:useLevel:\" of class \"methods\" with parameters {window \"%@\", \"NSFloatingWindowLevel\"}",
    [self.selectedWindow objectForKey:@"kCGWindowOwnerName"],
    [self.selectedWindow objectForKey:@"kCGWindowName"],
    targetPoint.x,
    targetPoint.y,
    targetPoint.x+rect.size.width,
    targetPoint.y+rect.size.height,
    [self.selectedWindow objectForKey:@"kCGWindowName"]
  ];
  
  [self runScript:script];
}

@end
