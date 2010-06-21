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

#import "TwiztLeague.h"

#import "NSDataExtensions.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>

@implementation TwiztLeague

@synthesize delegate, state, playerID, playerName;



- (id) initWithAppID: (NSString*)_appID secret:(NSString*)_secret;
{
	self = [super init];
	appID = [_appID copy];
	secret = [_secret copy];
	jsonLoader = [[JSONLoader alloc] initWithDelegate:self];
	return self;
}



- (void) dealloc
{
	[playerID release];
	[playerName release];
	[state release];
	[jsonLoader release];
	[secret release];
	[appID release];
	[super dealloc];
}



- (void) setPlayerName:(NSString*)_name {
	if (_name) {
		playerName = [_name copy];
	} else {
		playerName = [@"" retain];
	}
	
	playerID = [[NSString stringWithFormat:@"ID_%d_%@", [[[UIDevice currentDevice] uniqueIdentifier] hash], playerName] retain];
}



- (int) addGame:(NSString*)opponentID opponentName:(NSString*)opponentName score:(int)score submitBoth:(bool)submitBoth {
	NSMutableDictionary *opponentGames = [self getPlayerGames:opponentID playerName:opponentName];
	
	NSNumber *bestScore = [opponentGames objectForKey:@"BestScore"];
	if (!bestScore) {
		bestScore = [NSNumber numberWithInt:0];
	}
	
	NSNumber *games = [opponentGames objectForKey:@"Games"];
	if (!games) {
		games = [NSNumber numberWithInt:0];
	}
	
	[opponentGames setValue:[NSNumber numberWithInt:[games intValue] + 1] forKey:@"Games"];
	
	if (score > [bestScore intValue]) {
		bestScore = [NSNumber numberWithInt:score];
		[opponentGames setValue:bestScore forKey:@"BestScore"];
		[opponentGames setValue:[NSNumber numberWithBool:false] forKey:@"BestScoreSubmited"];
		
		[opponentGames setValue:[NSNumber numberWithFloat:0.0f] forKey:@"LeaderboardRefreshed"];		
	}
	
	NSString *signature = [self makeSignature:secret data:[playerID dataUsingEncoding:NSASCIIStringEncoding]];	
	NSString *url = [NSString stringWithFormat:@"http:/your_leaderboard_url/update?leaderboard=%@_%@&playerId=%@&playerName=%@&score=%d&sig=%@", appID, opponentID, playerID, playerName, [bestScore intValue], signature];
	NSLog(@"url=%@", url);
	[jsonLoader loadAsync:opponentID url:url];		
	
	NSNumber *totalGames = [[self state] objectForKey:@"TotalGames"];
	if (totalGames) {
		totalGames = [NSNumber numberWithInt:[totalGames intValue] + 1];
	} else {
		totalGames = [NSNumber numberWithInt:1];
	}
	[[self state] setValue:totalGames forKey:@"TotalGames"];
	
	[self writeState];
	
	return [bestScore intValue];
}



- (int) getTotalGames {
	NSNumber *totalGames = [[self state] objectForKey:@"TotalGames"];
	if (totalGames) {
		return [totalGames intValue];
	} else {
		return 0;
	}
}



- (NSMutableDictionary*) state {
	if (!state) {
		state = [[NSMutableDictionary alloc] initWithContentsOfFile: [self getStatePath]];
	}
	
	if (!state) {
		state = [[NSMutableDictionary alloc] init];
	}	
	
	return state;
}



- (NSString *) getStatePath {	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
	NSString *documentsDir = [paths objectAtIndex:0];
	return [documentsDir stringByAppendingPathComponent:@"league.plist"];
}



- (NSMutableDictionary*) getGames {
	[self state];
	
	NSMutableDictionary* games = [state objectForKey: @"Games"];
	if (!games) {
		games = [[[NSMutableDictionary alloc] init] autorelease];
		[state setValue:games forKey: @"Games"];
	}
	
	return games;
}



- (NSMutableDictionary*) getPlayerGames: (NSString*)_playerID playerName:(NSString*)_playerName {
	NSMutableDictionary* games = [self getGames];
	
	NSMutableDictionary* playerGames = [games objectForKey: _playerID];
	
	if (!playerGames) {
		playerGames = [[[NSMutableDictionary alloc] init] autorelease];
		[playerGames setValue:_playerName forKey:@"Name"];
		[games setValue:playerGames forKey:_playerID];
	}	
	
	return playerGames;
}



- (void) writeState {
	if (state) {
		[state writeToFile:[self getStatePath] atomically:true];
	}
}



- (void) jsonLoaded:(NSString*)key dict:(NSDictionary*)dict {
	NSMutableDictionary *opponentGames = [self getPlayerGames:key playerName:nil];
	bool dirty = false;
	
	NSArray *lb = [dict objectForKey:@"leaderboard"];
	if (lb) {
		[opponentGames setObject:lb forKey:@"Leaderboard"];
		dirty = true;
	}
	
	NSNumber *r = [dict objectForKey:@"rank"];
	if (r) { // this is update		
		[opponentGames setValue:[NSNumber numberWithBool:true] forKey:@"BestScoreSubmited"];
		[opponentGames setObject:r forKey:@"Rank"];
		dirty = true;
	}
	
	if (dirty) {
		[self writeState];
	}
	
	if (lb) {
		[delegate onLoadLeaderboardSuccess: lb];
	} else if (r) {
		[delegate onAddGameSuccess:[(NSNumber*)[opponentGames objectForKey:@"Rank"] intValue]];
	}
}



- (void) jsonError:(NSString*)key error:(NSString*)error {
	NSLog(@"TwiztLeague.jsonError[%@]=%@", key, error);
	[delegate onLeagueNetworkFail];
}




- (void) loadLeaderboard:(NSString*)opponentID {
	NSMutableDictionary *opponentGames = [self getPlayerGames:opponentID playerName:nil];
		
	float lastUpdated = 0;
	NSNumber *lastUpdatedN = [opponentGames objectForKey:@"LeaderboardRefreshed"];
	if (lastUpdatedN) {
		lastUpdated = [lastUpdatedN floatValue];
	}
	
	float now = time(NULL);
	
	if (now - lastUpdated > 3600) { // 1h
		NSLog(@"Refreshing leaderboard for %2", opponentID);		
		[opponentGames setObject:[NSNumber numberWithFloat:now] forKey:@"LeaderboardRefreshed"];
		[self writeState];
		NSMutableString *url = [NSMutableString stringWithFormat:@"http://lb.twizt.com/?leaderboard=%@_%@&limit=50", appID, opponentID];
		
		NSNumber *bestScore = [opponentGames objectForKey:@"BestScore"];
		if (bestScore) {
			[url appendFormat:@"&score=%d", [bestScore intValue]];
		}
		
		[jsonLoader loadAsync:opponentID url:url];
		
	} else {
		[delegate onLoadLeaderboardSuccess:[opponentGames objectForKey:@"Leaderboard"]];
		 
	}
}



- (int) getRank:(NSString*)opponentID {
	NSMutableDictionary *opponentGames = [self getPlayerGames:opponentID playerName:nil];	
	NSNumber *r = [opponentGames objectForKey:@"Rank"];
	if (!r) {
		return 0;
	} else {
		return [r intValue];
	}
}



- (int) getBestScore:(NSString*)opponentID {
	NSMutableDictionary *opponentGames = [self getPlayerGames:opponentID playerName:nil];	
	NSNumber *bestScore = [opponentGames objectForKey:@"BestScore"];
	if (!bestScore) {
		return 0;
	} else {
		return [bestScore intValue];
	}
}



- (NSString *)makeSignature:(NSString *)salt data:(NSData*) data 
{
	// This will hold our signature
	unsigned char digest[CC_SHA1_DIGEST_LENGTH];	
	
	// Get our secret as a raw string
	const char *saltCString = [salt cStringUsingEncoding:NSASCIIStringEncoding];
	
	// Initialize our HMAC context
	CCHmacContext hctx;
	CCHmacInit(&hctx, kCCHmacAlgSHA1, saltCString, strlen(saltCString));
	
	// Add in our data
	CCHmacUpdate(&hctx, [data bytes], [data length]);
	
	// Create our signature
	CCHmacFinal(&hctx, digest);
	
	// Return a base64 encoded version
	NSData *digestAsString = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
	NSString *encodedString = [digestAsString base64Encoding];
	
	return encodedString;
}



@end
