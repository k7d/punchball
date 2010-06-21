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

#import "Player.h"
#import "ReplaceLayerAction.h"
#import "Gestures.h"

@protocol GameDelegate

- (void) gameOver: (bool)_youWin score:(int)_score opponentName:(NSString*)opponentName;
- (void) mainMenu;

@end


@interface Game : Layer<ReplaceLayerActionDelegate, GesturesDelegate> {
	id<GameDelegate> delegate;
	
	cpSpace *space;
	
	AtlasSpriteManager *headSM;
	AtlasSpriteManager *gloveSM;
	AtlasSpriteManager *springSM;
	AtlasSpriteManager *headParticleSM;
	AtlasSpriteManager *scoreSM;
	AtlasSpriteManager *bonusSM;
	
	AtlasSprite			*leftScoreBorder;
	AtlasSprite			*leftScore;
	AtlasSprite			*rightScoreBorder;
	AtlasSprite			*rightScore;
	
	NSMutableArray *gameObjects;
	
	Player *leftPlayer;
	Player *rightPlayer;
	Player *localPlayer;

	Label *leftLabel;
	Label *rightLabel;
	Label *scoreLabel;
	
	Gestures *gestures;
	
	bool useAccel;
	bool gameInProgress;
	bool isSliding;
	
	NSString *opponentName;
	
	UIAlertView* pausePopup;
	
	bool showHint;
}

@property (nonatomic, readonly) NSMutableArray *gameObjects;
@property (nonatomic, readonly) Player *rightPlayer;
@property (nonatomic, assign) bool showHint;


-(void) step: (ccTime) dt;
-(void) updateScores;

-(id) initWithDelegate: (id<GameDelegate>)_delegate;

-(void)touchBegan:(CGPoint)pos;
-(void)touchMove:(CGPoint)pos final:(bool)final;


-(void) pause;
-(void) resume;
-(void) menu;

@end


@interface GameHintAction : IntervalAction {
	Layer *layer;
	Label *label;
}

+(id) hintWithText:(NSString*)text layer:(Layer*)_layer;

-(id) initWithText:(NSString*)text layer:(Layer*)_layer;

@end

