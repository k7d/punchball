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

#import "AppController.h"
#import "ReplaceLayerAction.h"
#import "SinglePlayerGame.h"
#import "MultiPlayerGame.h"
#import "PASoundMgr.h"
#import "Empty.h"
#import "Splash.h"

typedef enum {
	StateNone,
	StateMenu,
	StateControls,
	StateSingleOpponent,
	StateSingle,
	StateMultiPick,
	StateMulti,
	StateSingleOver,
	StateMultiOver,
	StateLeaguePlayers,
} AppState;


@implementation AppController

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	application.idleTimerDisabled = YES; // we don't want the screen to sleep during our game 
	

	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[window setMultipleTouchEnabled:YES];
	
	//[Director useFastDirector]; // causing prblems with GKPeerPicker

	// before creating any layer, set the landscape mode
	[[Director sharedDirector] setDeviceOrientation:CCDeviceOrientationLandscapeLeft];
	
	[[Director sharedDirector] attachInView:window];
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[Texture2D setDefaultAlphaPixelFormat:kTexture2DPixelFormat_RGBA8888];	
	
	
	// add layer
	scene = [Scene node];
	
	Sprite *bg = [Sprite spriteWithFile:@"bg.png"];
	bg.anchorPoint = cpvzero;	
	[scene addChild:bg z:0];		
	
	currentLayer = nil;
	
	[MenuItemFont setFontSize:40];
	
	[PASoundMgr sharedSoundManager];
	
	link = nil;
	
	[window makeKeyAndVisible];
	
	[[Director sharedDirector] runWithScene: scene];
	
	Splash *splash = [Splash node];
	[scene addChild:splash z:1];
	currentLayer = splash;
	
	gameState = StateNone;
	
	state = [[State alloc] init];
	
	league = [[TwiztLeague alloc] initWithAppID:[NSString stringWithCString:APP_ID] secret:[NSString stringWithCString:SECRET]];
	[league setPlayerName:state.name];
	
	[self mainMenu];
}



- (void) dealloc
{
	[opponentID release];
	[opponentName release];
	[league release];
	[state release];
	[link release];
	[window release];
	[super dealloc];
}



// getting a call, pause the game
-(void) applicationWillResignActive:(UIApplication *)application
{
	[[Director sharedDirector] pause];
}



// call got rejected
-(void) applicationDidBecomeActive:(UIApplication *)application
{
	[[Director sharedDirector] resume];
}



// purge memroy
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[TextureMgr sharedTextureMgr] removeAllTextures];
}



// next delta time will be zero
-(void) applicationSignificantTimeChange:(UIApplication *)application
{
	[[Director sharedDirector] setNextDeltaTimeZero:YES];
}



- (void) mainMenu {
	if (gameState != StateMenu) {
		gameState = StateMenu;
		
		MainMenu *menu = [[[MainMenu alloc] init:self] autorelease];	
		ReplaceLayerAction *replaceScreen = [[[ReplaceLayerAction alloc] initWithScene:scene layer:menu replaceLayer:currentLayer] autorelease];
		replaceScreen.reverse = true;
		[scene runAction: replaceScreen];
		currentLayer = menu;
	}
}



- (void) opponentSelected:(int)_opponent {
	opponent = _opponent;
	
	gameState = StateSingle;
	
	SinglePlayerGame *game = [[[SinglePlayerGame alloc] initWithDelegate:self opponent:_opponent] autorelease];	
	if ([league getTotalGames] > 3) game.showHint = false;
	ReplaceLayerAction *replaceScreen = [[[ReplaceLayerAction alloc] initWithScene: scene layer:game replaceLayer:currentLayer] autorelease];
	[scene runAction: replaceScreen];
	currentLayer = game;	
}



- (void) startSinglePlayer {
	gameState = StateSingleOpponent;
	
	Opponent *o = [[[Opponent alloc] init:self] autorelease];
	ReplaceLayerAction *replaceScreen = [[[ReplaceLayerAction alloc] initWithScene: scene layer:o replaceLayer:currentLayer] autorelease];
	[scene runAction: replaceScreen];
	currentLayer = o;	
}



- (void) startMultiPlayer {
	gameState = StateMultiPick;
	
	if (!state.name) {
		[self enterName];
		return;
	}
	
	if (!link) {
		link = [[Link alloc] initWithID:@"Punchball" name:state.name delegate:self];
	}
	
	Empty *l = [[[Empty alloc] init] autorelease];
	ReplaceLayerAction *replaceScreen = [[[ReplaceLayerAction alloc] initWithScene: scene layer:l replaceLayer:currentLayer] autorelease];
	[scene runAction: replaceScreen];
	currentLayer = l;	

	[link startPicker];
}



-(void) linkConnected: (LinkRole) role {

	gameState = StateMulti;
	
	MultiPlayerGame *game;
	if (role == RoleServer) {
		game = [[[MultiPlayerGame alloc] initWithDelegate:self link:link left:true] autorelease];	
	} else {
		game = [[[MultiPlayerGame alloc] initWithDelegate:self link:link left:false] autorelease];	
	}
	if ([league getTotalGames] > 3) game.showHint = false;
	
	ReplaceLayerAction *replaceScreen = [[[ReplaceLayerAction alloc] initWithScene: scene layer:game replaceLayer:currentLayer] autorelease];
	[scene runAction: replaceScreen];
	currentLayer = game;		
}



-(void) linkDisconnected {
	NSLog(@">>> linkDisconnected");
	[self mainMenu];
}



- (void) gameOver: (bool)_youWin score:(int)_score opponentName:(NSString*)_opponentName
{
	youWin = _youWin;
	score = _score;
	opponentName = [_opponentName copy];
	
	if (!state.name) {
		[self enterName];
		return;
	} else {
		[league setPlayerName:state.name];
	}
	
	bool submitBoth;
	if (gameState == StateMulti) {
		opponentID = [[NSString stringWithFormat:@"ID_%d_%@", link.peerUniqueID, opponentName] retain];
		submitBoth = false;
		gameState = StateMultiOver;
		[link reset];
	} else { // if (gameState == StateSingle) {
		opponentID = [[NSString stringWithFormat:@"ID_0_%@", opponentName] retain];
		submitBoth = true;
		gameState = StateSingleOver;
	}
	
	GameOver *go = [[[GameOver alloc] initWithDelegate:self youWin:youWin score:score opponentName:opponentName] autorelease];
	league.delegate = go;
	[go setBestScore: [league addGame:opponentID opponentName:opponentName score:score submitBoth:false]];
		
	ReplaceLayerAction *replaceScreen = [[[ReplaceLayerAction alloc] initWithScene:scene layer:go replaceLayer:currentLayer] autorelease];
	[scene runAction: replaceScreen];
	currentLayer = go;
}



-(void) onGameOverReplay {
	league.delegate = nil;
	
	if (gameState == StateMultiOver) {
		[link resync];
		
	} else if (gameState == StateSingleOver) {
		[self opponentSelected:opponent];
		
	}
}



-(void) onGameOverMenu {
	league.delegate = nil;
	
	if (gameState == StateMultiOver) {
		[link invalidateSession];
	}
	
	[self mainMenu];
}



- (void) leaderboard {
	league.delegate = nil;	
	
	[self onLeaguePlayer:opponentID];
}



- (void) league {
	gameState = StateLeaguePlayers;
	LeaguePlayers *l = [[[LeaguePlayers alloc] init:self league:league window:window] autorelease];	
	ReplaceLayerAction *replaceScreen = [[[ReplaceLayerAction alloc] initWithScene:scene layer:l replaceLayer:currentLayer] autorelease];
	[scene runAction: replaceScreen];
	currentLayer = l;	
}



- (void) enterName {
	EnterName *l = [[[EnterName alloc] initWithDelegate:self window:window] autorelease];	
	ReplaceLayerAction *replaceScreen = [[[ReplaceLayerAction alloc] initWithScene:scene layer:l replaceLayer:currentLayer] autorelease];
	[scene runAction: replaceScreen];
	currentLayer = l;
}



- (void) nameEntered: (NSString*)name {
	state.name = name;
	if (gameState == StateSingle) {
		[self gameOver:youWin score:score opponentName:opponentName];
	} else { // StateMultiPick
		[self startMultiPlayer];
	}	
}



-(void) onLeagueMenu {
	[self mainMenu];
}



-(void) onLeaguePlayer:(NSString*)playerID {
	NSLog(@"onLeaguePlayer=%@", playerID);
	LeagueLeaderboard *l = [[[LeagueLeaderboard alloc] init:self league:league window:window playerID:playerID] autorelease];	
	ReplaceLayerAction *replaceScreen = [[[ReplaceLayerAction alloc] initWithScene:scene layer:l replaceLayer:currentLayer] autorelease];
	[scene runAction: replaceScreen];
	currentLayer = l;	
}



-(void) onLeagueBack {
	if (gameState == StateLeaguePlayers) {
		LeaguePlayers *l = [[[LeaguePlayers alloc] init:self league:league window:window] autorelease];	
		ReplaceLayerAction *replaceScreen = [[[ReplaceLayerAction alloc] initWithScene:scene layer:l replaceLayer:currentLayer] autorelease];
		replaceScreen.reverse = true;
		[scene runAction: replaceScreen];
		currentLayer = l;	
		
	} else {
		GameOver *go = [[[GameOver alloc] initWithDelegate:self youWin:youWin score:score opponentName:opponentName] autorelease];
		[go setBestScore: [league getBestScore:opponentID]];
		[go setRank: [league getRank:opponentID]];
		
		ReplaceLayerAction *replaceScreen = [[[ReplaceLayerAction alloc] initWithScene:scene layer:go replaceLayer:currentLayer] autorelease];
		replaceScreen.reverse = true;
		[scene runAction: replaceScreen];
		currentLayer = go;
		
	}
}

@end
