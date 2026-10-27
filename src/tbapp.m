#import <Cocoa/Cocoa.h>
#import "TBCore.h"

@interface TBViewController : NSViewController
@property (nonatomic, strong) NSSlider *slider;
@property (nonatomic, strong) NSTextField *valueLabel;
@property (nonatomic, strong) NSButton *autoButton;
@property (nonatomic, strong) NSTimer *applyTimer;
@property (nonatomic, assign) BOOL overrideOn;
@property (nonatomic, assign) double targetLux;
@end

@implementation TBViewController

- (void)loadView {
    NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 300, 196)];

    NSTextField *title = [self label:@"Touch Bar 亮度" frame:NSMakeRect(16, 166, 268, 18) bold:YES];
    [root addSubview:title];

    NSSlider *slider = [[NSSlider alloc] initWithFrame:NSMakeRect(14, 136, 272, 24)];
    slider.minValue = 0;
    slider.maxValue = 100;
    slider.continuous = YES;
    slider.target = self;
    slider.action = @selector(sliderChanged:);
    [root addSubview:slider];
    self.slider = slider;

    NSTextField *value = [self label:@"—" frame:NSMakeRect(16, 114, 268, 16) bold:NO];
    value.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
    value.textColor = [NSColor secondaryLabelColor];
    [root addSubview:value];
    self.valueLabel = value;

    NSArray *names = @[@"最暗", @"暗", @"中", @"亮", @"最亮"];
    NSArray *values = @[@0, @25, @50, @75, @100];
    for (NSUInteger i = 0; i < names.count; i++) {
        NSButton *b = [NSButton buttonWithTitle:names[i] target:self action:@selector(presetClicked:)];
        b.frame = NSMakeRect(16 + (CGFloat)i * 54, 76, 50, 26);
        b.bezelStyle = NSBezelStyleRounded;
        b.tag = [values[i] integerValue];
        [root addSubview:b];
    }

    NSButton *autoB = [NSButton buttonWithTitle:@"恢复自动" target:self action:@selector(autoClicked:)];
    autoB.frame = NSMakeRect(16, 34, 110, 28);
    autoB.bezelStyle = NSBezelStyleRounded;
    [root addSubview:autoB];
    self.autoButton = autoB;

    NSButton *quit = [NSButton buttonWithTitle:@"退出" target:self action:@selector(quitClicked:)];
    quit.frame = NSMakeRect(134, 34, 70, 28);
    quit.bezelStyle = NSBezelStyleRounded;
    [root addSubview:quit];

    NSTextField *hint = [self label:@"退出或点“恢复自动”会交还真实传感器" frame:NSMakeRect(16, 10, 268, 16) bold:NO];
    hint.font = [NSFont systemFontOfSize:10];
    hint.textColor = [NSColor tertiaryLabelColor];
    [root addSubview:hint];

    self.view = root;
}

- (NSTextField *)label:(NSString *)text frame:(NSRect)frame bold:(BOOL)bold {
    NSTextField *f = [[NSTextField alloc] initWithFrame:frame];
    f.stringValue = text;
    f.bezeled = NO;
    f.drawsBackground = NO;
    f.editable = NO;
    f.selectable = NO;
    f.font = bold ? [NSFont boldSystemFontOfSize:13] : [NSFont systemFontOfSize:11];
    f.textColor = bold ? [NSColor labelColor] : [NSColor secondaryLabelColor];
    return f;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshFromCore];
    self.applyTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(applyTick:)
                                                     userInfo:nil
                                                      repeats:YES];
    self.applyTimer.tolerance = 0.2;
}

- (void)refreshFromCore {
    TBCore *core = [TBCore shared];
    double injected = core.overrideLux;
    double lux = injected >= 0 ? injected : core.currentLux;
    if (lux < 0) {
        self.valueLabel.stringValue = @"不可用";
        return;
    }
    self.overrideOn = (injected >= 0);
    self.targetLux = lux;
    self.slider.doubleValue = [core percentForLux:lux];
    [self updateLabel];
}

- (void)updateLabel {
    TBCore *core = [TBCore shared];
    double pct = self.slider.doubleValue;
    double shown = self.overrideOn ? self.targetLux : core.currentLux;
    if (shown < 0) shown = 0;
    self.valueLabel.stringValue = [NSString stringWithFormat:@"%.0f%%   %.0f lux   %@",
                                   pct, shown,
                                   self.overrideOn ? @"注入中" : @"真实传感器"];
}

- (void)sliderChanged:(NSSlider *)sender {
    TBCore *core = [TBCore shared];
    double pct = sender.doubleValue;
    double lux = [core luxForPercent:pct];
    self.overrideOn = YES;
    self.targetLux = lux;
    [core setLux:lux];
    [self updateLabel];
}

- (void)presetClicked:(NSButton *)sender {
    double pct = (double)sender.tag;
    self.slider.doubleValue = pct;
    [self sliderChanged:self.slider];
}

- (void)autoClicked:(id)sender {
    TBCore *core = [TBCore shared];
    [core clearOverride];
    self.overrideOn = NO;
    [self updateLabel];
}

// The override lives in corebrightnessd, so it persists on its own. This tick
// only mirrors external changes (e.g. `tbright lux ...`) into the UI; it never
// rewrites the value, so the CLI and the app never fight each other.
- (void)applyTick:(NSTimer *)timer {
    TBCore *core = [TBCore shared];
    double current = core.overrideLux;
    if (current >= 0) {
        self.overrideOn = YES;
        self.targetLux = current;
        double pct = [core percentForLux:current];
        if (fabs(self.slider.doubleValue - pct) > 0.5) self.slider.doubleValue = pct;
    } else {
        self.overrideOn = NO;
    }
    [self updateLabel];
}

- (void)quitClicked:(id)sender {
    // Deliberately does not clear the override: the setting (and its
    // remembered value) is meant to outlive the menu bar app.
    [NSApp terminate:nil];
}

- (void)dealloc {
    [self.applyTimer invalidate];
}

@end

@interface TBAppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSPopover *popover;
@property (nonatomic, strong) TBViewController *controller;
@end

@implementation TBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSStatusBarButton *button = self.statusItem.button;
    NSImage *image = [NSImage imageWithSystemSymbolName:@"sun.max.fill"
                               accessibilityDescription:@"Touch Bar 亮度"];
    image.template = YES;
    button.image = image;
    button.toolTip = @"Touch Bar 亮度";
    button.target = self;
    button.action = @selector(togglePopover:);

    self.controller = [[TBViewController alloc] init];
    self.popover = [[NSPopover alloc] init];
    self.popover.behavior = NSPopoverBehaviorTransient;
    self.popover.contentViewController = self.controller;
    self.popover.contentSize = self.controller.view.frame.size;
}

- (void)togglePopover:(id)sender {
    if (self.popover.shown) {
        [self.popover performClose:nil];
        return;
    }
    [self.controller refreshFromCore];
    NSStatusBarButton *button = self.statusItem.button;
    [self.popover showRelativeToRect:button.bounds ofView:button preferredEdge:NSRectEdgeMinY];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        TBAppDelegate *delegate = [[TBAppDelegate alloc] init];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
