#import <Cocoa/Cocoa.h>
#import <LocalGameController.h>
#import <MultiplayerGameController.h>

// needed to avoid some name conflicts with boost and objc
#define id _avoid_id_collision
#undef id

@interface AppController : NSObject
{
	LocalGameController *normalGameController;
	MultiplayerGameController *multiplayerGameController;
}
- (IBAction)hostNewGame:(id)sender;
- (IBAction)closeHostedGame:(id)sender;
- (IBAction)openTrackerWindow:(id)sender;
- (IBAction)startNewGame:(id)sender;
@end
