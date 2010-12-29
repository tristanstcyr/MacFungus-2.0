//
//  MultiplayerGameController.m
//  MacFungus2.0
//
//  Created by tristan on 15/03/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MultiplayerGameController.h"

@implementation MultiplayerGameController
- (id) init 
{
	if (self = [super init]) 
	{
		playersArray = [[NSMutableArray alloc] init];
	} else return nil;
	
	return self;
}

- (void)joinGameAddress:(NSString*)anAddress {}
- (void)startServerAndJoin {}
@end
