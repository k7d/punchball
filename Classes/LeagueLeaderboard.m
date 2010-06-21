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

#import "LeagueLeaderboard.h"
#import "Common.h"


@implementation LeagueLeaderboard


-(id)init:(id<LeagueLeaderboardDelegate>)_delegate league:(TwiztLeague*)_league window:(UIWindow*)_window playerID:(NSString*)_playerID {
	self = [super init];
	
	delegate = _delegate;
	league = _league;
	window = _window;
	
	Sprite *bg = [Sprite spriteWithFile:@"league.png"];
	bg.anchorPoint = cpvzero;	
	[self addChild:bg z:0];			
	
	MenuItemImage *mn = [MenuItemImage itemFromNormalImage:@"b_back.png" selectedImage:@"b_back_s.png" target:self selector:@selector(players:)];	
	Menu *mnm = [Menu menuWithItems: mn, nil];
	mnm.position = cpv(70, 278);
	[self addChild:mnm z:3];	
	
	table = [[UITableView alloc] initWithFrame:CGRectMake(0,0,480.0f,320.0f)];
	table.backgroundColor = [UIColor clearColor];
	table.separatorStyle = UITableViewCellSeparatorStyleNone;	
	table.transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(H_PI), +80, +80);
	table.frame = CGRectMake(12, 490, 228, 460);
	table.rowHeight = 28.0f;
	table.delegate = self;
	table.dataSource = self;
	[window addSubview:table];
	
	isError = false;
	
	opponentGames = [league getPlayerGames:_playerID playerName:nil];
	opponentName = [[opponentGames objectForKey:@"Name"] copy];
	leaderboard = nil;
	
	league.delegate = self;
	[league loadLeaderboard:_playerID];
	
	return self;
}



-(void)dealloc {
	[table removeFromSuperview];	
	[table release];
	
	[leaderboard release];
	[opponentName release];
	
	[super dealloc];
}



-(void)setPosition:(CGPoint)p {
	table.frame = CGRectMake(12, p.x + 10, 228, 460);
	[super setPosition:p];
}



- (void)layerReplaced {
}



-(void)players: (id) sender {
	league.delegate = nil;
	[delegate onLeagueBack];
}



- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	if (leaderboard) {
		int c = [leaderboard count]; 
		if (c > 50) {
			return 50;
		} else {
			return c;
		}
	} else if (isError) {
		return 2;
	} else {
		return 1;
	}
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *ScoreCellID = @"ScoreCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ScoreCellID];
	
	if (cell == nil) {
		// Use the default cell style.
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ScoreCellID] autorelease];
	}

	cell.textLabel.font = [UIFont fontWithName:@"Courier" size:22];
	cell.textLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
	
	if (leaderboard) {
		NSString *playerName;
		int rank = [(NSNumber*)[opponentGames objectForKey:@"Rank"] intValue];
		int score;
		NSString *ind;
		
		if (indexPath.row == 49 && rank > 3) { 
			playerName = @"You";			
			score = [(NSNumber*)[opponentGames objectForKey:@"BestScore"] intValue]; 
			ind = @">";
			
		} else {
			NSDictionary *e = [leaderboard objectAtIndex:indexPath.row];
			rank = indexPath.row + 1;
			score = [(NSNumber*)[e objectForKey:@"score"] intValue];
			NSString *playerID = [e objectForKey:@"playerId"];
			if ([playerID compare:league.playerID] == 0) { // this is me
				ind = @">";
				playerName = @"You";
				[opponentGames setObject:[NSNumber numberWithInt:indexPath.row+1] forKey:@"Rank"];
			} else {
				ind = @" ";
				playerName = [e objectForKey:@"playerName"];
			}			
		}
		
		NSString *p = [NSString stringWithFormat:@"%-2d %@ vs. %@                   ", rank, playerName, opponentName];
		cell.textLabel.text = [NSString stringWithFormat:@"%@%@ %4d", ind, [p substringToIndex:27], score];
	} else {
		if (isError) {
			if (indexPath.row == 0) {
				cell.textLabel.text = @"Leaderboard is currently";
			} else { // 1
				cell.textLabel.text = @"unavailable.";
			}			
		} else {
			cell.textLabel.text = @"Loading...";
		}
	}
	
	return cell;
}



- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

		
- (void)onLoadLeaderboardSuccess:(NSArray*)_leaderboard {
	leaderboard = [_leaderboard retain];
	[table reloadData];
}



- (void)onLeagueNetworkFail {
	isError = true;
	[table reloadData];
}
		

@end
