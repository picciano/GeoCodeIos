//
//  NSString+Escaping.m
//  GeoCode
//
//  Created by Anthony Picciano on 3/12/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "NSString+Escaping.h"

@implementation NSString (Escaping)

- (NSString*)stringWithPercentEscape {
    return (__bridge_transfer NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)[self mutableCopy], NULL, CFSTR("￼=,!$&'()*+;@?\n\"<>#\t :/"),kCFStringEncodingUTF8);
}

@end
