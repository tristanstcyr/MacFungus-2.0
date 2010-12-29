#import <GameController.h>

@interface LocalGameController : GameController {
	BOOL isTableViewButtonsViewVisible;
}
- (void)saveGameSettings;
- (void)showPlayersTableViewButtons;
- (void)hidePlayersTableViewButtons;
- (void)evaluateAddRemovePlayerButtons;

@end
