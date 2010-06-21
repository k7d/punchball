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

#import "GameOver.h"


@implementation GameOver

-(id) initWithDelegate: (id<GameOverDelegate>)_delegate youWin:(bool)youWin score:(int)_score opponentName:(NSString*)opponentName
{
	[super init];
	
	delegate = _delegate;
	isActive = false;
	
	isTouchEnabled = YES;
	
	score = _score;
	
	Sprite *bg;
	
	if (youWin) {
		bg = [Sprite spriteWithFile:@"game_over_s.png"];
	} else {
		bg = [Sprite spriteWithFile:@"game_over_f.png"];
	}
	
	bg.anchorPoint = cpvzero;	
	[self addChild:bg z:1];		
	
	Menu *mr = [Menu menuWithItems: [MenuItemImage itemFromNormalImage:@"b_more.png" selectedImage:@"b_more_s.png" target:self selector:@selector(leaderboard:)], nil];
	mr.position = cpv(420, 120);
	[self addChild:mr z:3];	

	MenuItemImage *rp = [MenuItemImage itemFromNormalImage:@"b_replay.png" selectedImage:@"b_replay_s.png" target:self selector:@selector(replay:)];	
	Menu *rpm = [Menu menuWithItems: rp, nil];
	rpm.position = cpv(415, 270);
	[self addChild:rpm z:3];
	
	MenuItemImage *mn = [MenuItemImage itemFromNormalImage:@"b_menu.png" selectedImage:@"b_menu_s.png" target:self selector:@selector(menu:)];	
	Menu *mnm = [Menu menuWithItems: mn, nil];
	mnm.position = cpv(70, 270);
	[self addChild:mnm z:3];	

	scoreLabel = [Label labelWithString:[NSString stringWithFormat:@"%d", score] fontName:@"Courier" fontSize:22];
	scoreLabel.anchorPoint = cpv(0.0, 0.5);
	scoreLabel.position = cpv(210, 188);
	[self addChild:scoreLabel z:3];
	
	opponentLabel = [Label labelWithString:opponentName fontName:@"Courier" fontSize:22];
	opponentLabel.anchorPoint = cpv(0.0, 0.5);
	opponentLabel.position = cpv(210, 90);
	[self addChild:opponentLabel z:3];	
	
	bestScoreLabel = [Label labelWithString:@"" fontName:@"Courier" fontSize:22];
	bestScoreLabel.anchorPoint = cpv(0.0, 0.5);
	bestScoreLabel.position = cpv(210, 65);
	[self addChild:bestScoreLabel z:3];		
	
	rankLabel = [Label labelWithString:@"?" fontName:@"Courier" fontSize:22];
	rankLabel.anchorPoint = cpv(0.0, 0.5);
	rankLabel.position = cpv(210, 38);
	[self addChild:rankLabel z:3];				
	
	return self;
}



-(void) setBestScore:(int)bestScore {
	[bestScoreLabel setString:[NSString stringWithFormat:@"%d", bestScore]];
}

-(void) setRank:(int)rank {
	if (rank == 0) {
		[rankLabel setString:@"n/a"];
	} else {
		[rankLabel setString:[NSString stringWithFormat:@"%d", rank]];
	}
}



- (void)layerReplaced
{
}
	


-(void) replay: (id) sender
{	
	[delegate onGameOverReplay];
}



-(void) menu: (id) sender
{	
	[delegate onGameOverMenu];
}



-(void) leaderboard: (id) sender
{	
	[delegate leaderboard];
}



- (void)onAddGameSuccess:(int)rank {
	[self setRank:rank];
}



- (void)onLeagueNetworkFail {
	[self setRank:0];
}


@end
