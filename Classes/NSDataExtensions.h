//
//  NSDataExtensions.h
//  GetSomeSnow
//
//  Created by Eric Lee on 12/14/08.
//  Copyright Oodol 2008. All rights reserved.
//

@interface NSData (MBBase64)

+ (id)dataWithBase64EncodedString:(NSString *)string;     //  Padding '=' characters are optional. Whitespace is ignored.
- (NSString *)base64Encoding;
@end

@interface NSString (URL)

- (NSString *)stringByEscapingHTTPReserved;

@end

