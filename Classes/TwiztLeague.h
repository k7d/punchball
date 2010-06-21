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

#import <Foundation/Foundation.h>
#import "JSONLoader.h"

@protocol TwiztLeagueDelegate

@optional
- (void)onAddGameSuccess:(int)rank;
- (void)onLoadLeaderboardSuccess:(NSArray*)leaderboard;

- (void)onLeagueNetworkFail;

@end



@interface TwiztLeague : NSObject <JSONLoaderDelegate> {
	id<TwiztLeagueDelegate> delegate;
	NSString *appID;
	int points;
	int rank;
	NSString *playerName;
	NSString *playerID;
	JSONLoader *jsonLoader;
	NSMutableDictionary *state;
	NSString *secret;
}



@property(nonatomic,retain) id<TwiztLeagueDelegate> delegate;
@property(nonatomic,retain) NSMutableDictionary *state;
@property(nonatomic,copy) NSString *playerName;
@property(nonatomic,copy) NSString *playerID;

- (id) initWithAppID: (NSString*)_appID secret:(NSString*)_secret;;

- (void) setPlayerName:(NSString*)_name;

- (int) addGame:(NSString*)opponentID opponentName:(NSString*)opponentName score:(int)score submitBoth:(bool)submitBoth;

- (int) getRank:(NSString*)opponentID;
- (int) getBestScore:(NSString*)opponentID;

- (void) loadLeaderboard:(NSString*)opponentID;

- (NSString *) getStatePath;

- (NSMutableDictionary*) getGames;

- (NSMutableDictionary*) getPlayerGames: (NSString*)_playerID playerName:(NSString*)playerName;

- (void) writeState;

- (int) getTotalGames;

- (NSString *)makeSignature:(NSString *)salt data:(NSData*) data;

@end
