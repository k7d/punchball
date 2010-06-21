/*
 Copyright 2009 Kaspars Dancis
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "cocos2d.h"
#import "chipmunk.h"
#import "ReplaceLayerAction.h"
#import "TwiztLeague.h"

@protocol LeagueLeaderboardDelegate

@optional
-(void) onLeagueBack;

@end



@interface LeagueLeaderboard : Layer <ReplaceLayerActionDelegate, UITableViewDelegate, UITableViewDataSource, TwiztLeagueDelegate> {
	id<LeagueLeaderboardDelegate> delegate;
	UIWindow *window;
	UITableView *table;
	NSString *opponentName;
	NSMutableDictionary *opponentGames;
	NSArray *leaderboard;
	TwiztLeague *league;
	bool isError;
}

-(id)init:(id<LeagueLeaderboardDelegate>)_delegate league:(TwiztLeague*)_league window:(UIWindow*)_window playerID:(NSString*)_playerID;

@end
