#import <GameController.h>


@interface MultiplayerGameController : GameController {
	int localPlayerIndex;
}

- (void)joinGameAddress:(NSString*)anAddress;
@end
