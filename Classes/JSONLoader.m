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

#import "JSONLoader.h"
#import "NSDictionary_JSONExtensions.h"

@implementation JSONLoader

-(id) initWithDelegate:(id) _delegate {
	if ([super init]) {
		delegate = _delegate;
		getKeys = [[NSMutableDictionary alloc] init];
		getData = [[NSMutableDictionary alloc] init];		
	}
	
	return self;
}



- (void)dealloc {
	[getData release];
	[getKeys release];
    [super dealloc];
}



- (void) loadAsync:(NSString*)key  url:(NSString*) url {
	
	NSURLRequest *request = [[NSURLRequest alloc] 
							 initWithURL: [NSURL URLWithString: url]
							 cachePolicy: NSURLRequestReloadIgnoringLocalCacheData
							 timeoutInterval: 10
							 ];
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[getKeys setObject:key forKey:[NSValue valueWithNonretainedObject:connection]];
	[connection release];
	[request release];			
}



- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSString *key = [getKeys objectForKey: [NSValue valueWithNonretainedObject:connection]];
	
	if ([(NSHTTPURLResponse*)response statusCode] == 200) {
		NSMutableData *data = [[NSMutableData alloc] init];
		[data setLength: 0];
		[getData setObject: data forKey: key];
		[data release];
	} else {
		[delegate jsonError:key error:[NSString stringWithFormat: @"Loading Error %d", [(NSHTTPURLResponse*)response statusCode]]];
	}
}



- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSString *key = [getKeys objectForKey: [NSValue valueWithNonretainedObject:connection]];
	[[getData objectForKey:key] appendData:data];
}



- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSValue *requestKey = [NSValue valueWithNonretainedObject:connection];
	NSString *key = [getKeys objectForKey: requestKey];
	
	[delegate jsonError:key error:[NSString stringWithFormat: @"Loading Error %@", [error description]]];
	
	[getKeys removeObjectForKey:requestKey];
	[getData removeObjectForKey:key];
}



- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSValue *requestKey = [NSValue valueWithNonretainedObject:connection];
	NSString *key = [getKeys objectForKey: requestKey];
	NSData *data = [getData objectForKey:key];
	NSError *error = nil;
	NSDictionary *dict = [NSDictionary dictionaryWithJSONData:data error:&error];		
	
	if (error) {
		[delegate jsonError:key error:[NSString stringWithFormat: @"Loading Error %@", [error description]]];
	} else {
		[delegate jsonLoaded:key dict:dict];
	}
	
	[getKeys removeObjectForKey:requestKey];
	[getData removeObjectForKey:key];
}


- (NSString *)urlencode:(NSString *)str {
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
	return [result autorelease];
}

@end
