#import "StatusItemController.h"
#import "ScrollInverterAppDelegate.h"
#import "NSObject+ObservePrefs.h"

@implementation StatusItemController

// a bit silly to do things this way, but it builds nicely on 10.9
- (NSInvocation *)appearsDisabledInvocation
{
	static NSInvocation *invocation=nil;
    NSMethodSignature *const signature=[NSClassFromString(@"NSStatusBarButton") instanceMethodSignatureForSelector:@selector(setAppearsDisabled:)];
    if (signature&&!invocation) {
        invocation=[NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:[_statusItem performSelector:@selector(button)]];
        [invocation setSelector:@selector(setAppearsDisabled:)];
	}
	return invocation;
}

+ (NSSize)statusImageSize
{
    return NSMakeSize(14, 17);
}

+ (NSImage *)statusImageWithColor:(NSColor *)color
{
    // make buffer image
    NSImage *const templateImage=[NSImage imageNamed:@"ScrollInverterStatusIcon"];
    
    // create blank image to draw into
    NSImage *const statusImage=[[NSImage alloc] init];
    [statusImage setSize:[self statusImageSize]];
    [statusImage lockFocus];
    
    // draw base black image
    const NSRect dstRect=NSMakeRect(0, 0, [self statusImageSize].width, [self statusImageSize].height);
    [templateImage drawInRect:dstRect
                     fromRect:NSZeroRect
                    operation:NSCompositeSourceOver
                     fraction:1.0];
    
    // fill with color
    [color set];
    NSRectFillUsingOperation(dstRect, NSCompositeSourceIn);
    
    // finished drawing
    [statusImage unlockFocus];
    return statusImage;
}

- (void)updateItems
{
	if ([self appearsDisabledInvocation]) {
		BOOL state=![[NSUserDefaults standardUserDefaults] boolForKey:PrefsReverseScrolling];
		[[self appearsDisabledInvocation] setArgument:&state atIndex:2];
		[[self appearsDisabledInvocation] invoke];
	}
	else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:PrefsReverseScrolling]) {
            if (_menuIsOpen) {
                [_statusItem setImage:[StatusItemController statusImageWithColor:[NSColor whiteColor]]];
            }
            else {
                [_statusItem setImage:[StatusItemController statusImageWithColor:[NSColor blackColor]]];
            }
        }
        else {
            [_statusItem setImage:[StatusItemController statusImageWithColor:[NSColor grayColor]]];
        }
	}
}

- (void)addStatusIcon
{
	if (!_statusItem) {
		_statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        [_statusItem setMenu:_theMenu];
        [_statusItem setHighlightMode:YES];

        if ([self appearsDisabledInvocation]) {
			// on yosemite, set up the template image here
            NSImage *const statusImage=[StatusItemController statusImageWithColor:[NSColor blackColor]];
            [statusImage setTemplate:YES];
            [_statusItem setImage:statusImage];
        }

		[self updateItems];
	}
}

- (void)removeStatusIcon
{
	if (_statusItem) {
		[[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
		_statusItem=nil;
	}
}

- (void)displayStatusIcon
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PrefsHideIcon]) {
		[self removeStatusIcon];
	}
	else {
		[self addStatusIcon];
	}
}

- (id)init
{
	self = [super init];
    
	[self observePrefsKey:PrefsReverseScrolling];
	[self observePrefsKey:PrefsHideIcon];	
	[self displayStatusIcon];
	
	return self;
}

- (void)menuWillOpen:(NSMenu *)menu
{
	_menuIsOpen=YES;
	[self updateItems];
}

- (void)menuDidClose:(NSMenu *)menu
{
	_menuIsOpen=NO;
	[self updateItems];	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self displayStatusIcon];
	[self updateItems];
}

- (void)attachMenu:(NSMenu *)menu
{
    _theMenu=menu;
	[_theMenu setDelegate:self];
    [_statusItem setMenu:_theMenu];
}

@end
