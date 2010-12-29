#import "AppController.h"
#import "MFGame.h"
#include <boost/bind.hpp>

@implementation AppController

- (void)awakeFromNib
{
	
}

- (IBAction)hostNewGame:(id)sender 
{

}

- (IBAction)closeHostedGame:(id)sender
{
}

- (IBAction)openTrackerWindow:(id)sender 
{ 

}

- (IBAction)startNewGame:(id)sender
{
	if (!normalGameController)	
		normalGameController = [[LocalGameController alloc] init];
	if (![normalGameController gameWindowVisible])
		[normalGameController openGameWindow];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[normalGameController saveGameSettings];
}
@end
