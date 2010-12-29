#import "AppController.h"

@implementation AppController

- (IBAction)hostNewGame:(id)sender
{
}

- (IBAction)openTrackerWindow:(id)sender
{
	if (!gameTrackerController) {
		gameTrackerController = [GTController new];
	}
	[gameTrackerController showWindow:self];
}

- (IBAction)startNewGame:(id)sender
{
}

@end
