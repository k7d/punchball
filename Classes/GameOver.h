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

@protocol GameOverDelegate

-(void) onGameOverReplay;
-(void) onGameOverMenu;
-(void) leaderboard;

@end


@interface GameOver : Layer <ReplaceLayerActionDelegate,TwiztLeagueDelegate> {
	id<GameOverDelegate> delegate;
	bool isActive;
	int score;
	int bonus;

	Label *scoreLabel;
	
	Label *opponentLabel;
	Label *bestScoreLabel;
	Label *rankLabel;
	
	TwiztLeague *league;
}

-(id) initWithDelegate: (id<GameOverDelegate>)_delegate youWin:(bool)youWin score:(int)_score opponentName:(NSString*)opponentName;

-(void) setBestScore:(int)bestScore;
-(void) setRank:(int)rank;

@end
