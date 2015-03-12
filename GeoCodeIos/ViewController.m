//
//  ViewController.m
//  GeoCodeIos
//
//  Created by Anthony Picciano on 3/12/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ViewController.h"
#import "NSString+Escaping.h"

@interface ViewController ()

@property (strong, nonatomic) NSArray *lines;
@property (nonatomic) BOOL skipFirstLine;
@property (strong, nonatomic) NSMutableArray *queryObjects;

@end

@implementation ViewController {
    NSMutableArray *_lines;
    NSMutableArray *_currentLine;
    CHCSVWriter *_writer;
    NSArray *_fields;
    FactualAPI *_api;
    FactualAPIRequest *_activeRequest;
    int _currentRequestIndex;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self begin];
}

- (void)begin {
    
    self.queryObjects = [NSMutableArray array];
    
    NSString *file = @(__FILE__);
    file = [[file stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"geocoding_test_with_coordinate.csv"];
    
    NSLog(@"Beginning...");
    NSStringEncoding encoding = 0;
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:file];
    CHCSVParser * p = [[CHCSVParser alloc] initWithInputStream:stream usedEncoding:&encoding delimiter:','];
    [p setRecognizesBackslashesAsEscapes:YES];
    [p setSanitizesFields:YES];
    
    NSLog(@"encoding: %@", CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(encoding)));
    
    self.skipFirstLine = YES;
    [p setDelegate:self];
    
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    [p parse];
    NSTimeInterval end = [NSDate timeIntervalSinceReferenceDate];
    
    NSLog(@"Elapsed time: %f", (end-start));
}

- (void)parserDidBeginDocument:(CHCSVParser *)parser {
    _lines = [[NSMutableArray alloc] init];
    _fields = @[@"ID", @"QUERY", @"RESULTS", @"LATITUDE", @"LONGITUDE", @"PLACE NAME"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"factual-geocoding-output.csv"];
    
    NSLog(@"OUTPUT PATH: %@", path);
    
    _writer = [[CHCSVWriter alloc] initForWritingToCSVFile:path];
    [_writer writeLineOfFields:_fields];
    _api = [[FactualAPI alloc] initWithAPIKey:@"kFibmf7JB3cMbPn42ebZJX9nCQ5GD8y9okAVqHeW" secret:@"CG02OrDvLmr5rhx76mO541ADGU1wzZJxguOKPxDX"];
    _api.debug = false;
    
}

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber {
    _currentLine = [[NSMutableArray alloc] init];
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex {
    //    NSLog(@"%@", field);
    [_currentLine addObject:field];
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber {
    
    if (_skipFirstLine) {
        _skipFirstLine = NO;
    } else {
        [self processRecord:_currentLine recordNumber:recordNumber];
    }
    
    [_lines addObject:_currentLine];
    _currentLine = nil;
}

- (void)parserDidEndDocument:(CHCSVParser *)parser {
    //    if (!_activeRequest) {
    //        _activeRequest = [_api queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    //    }
    
    _currentRequestIndex = 0;
    [self sendNextRequest];
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error {
    NSLog(@"ERROR: %@", error);
    _lines = nil;
}

- (void)processRecord:(NSArray *)record recordNumber:(NSUInteger)recordNumber {
    
    FactualQuery* queryObject = [FactualQuery query];
    queryObject.limit = 1;
    NSArray *queryTerms = @[record[1], record[2],record[3],record[4]];
    [queryObject addFullTextQueryTerm:[queryTerms componentsJoinedByString:@" "]];
    
    [self.queryObjects addObject:queryObject];
}

- (void)sendNextRequest {
    
    if (_currentRequestIndex >= self.queryObjects.count) {
        return;
    }
    
    FactualQuery* queryObject = self.queryObjects[_currentRequestIndex];
    _activeRequest = [_api queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
}

- (void)requestDidReceiveInitialResponse:(FactualAPIRequest *)request {
//    NSLog(@"requestDidReceiveInitialResponse:");
}

- (void)requestDidReceiveData:(FactualAPIRequest *)request {
//    NSLog(@"requestDidReceiveData:");
}

- (void) requestComplete:(FactualAPIRequest *)request receivedQueryResult:(FactualQueryResult *)queryResultObj {
    FactualRow *row = queryResultObj.rows[0];
    FactualQuery* queryObject = self.queryObjects[_currentRequestIndex];
    
//    NSLog(@"row: %@", row);
    
    NSString *query = queryObject.fullTextTerms[0];
    
    NSString *latitude = @"0";
    NSString *longitude = @"0";
    NSString *placeName = @"Not found.";
    NSNumber *numberOfFeatures = [NSNumber numberWithInt:0];
    
    if (row) {
        placeName = [NSString stringWithFormat:@"%@, %@, %@", [row stringValueForName:@"address"]
                               , [row stringValueForName:@"locality"]
                               , [row stringValueForName:@"region"]];
        numberOfFeatures = [NSNumber numberWithInt:1];
        if ([row stringValueForName:@"latitude"]) {
            latitude = [row stringValueForName:@"latitude"];
            longitude = [row stringValueForName:@"longitude"];
        }
        
    }
    
    NSNumber *idNumber = [NSNumber numberWithUnsignedInteger:_currentRequestIndex + 1];
    NSLog(@"Result: %@, %@, %@, %@, %@, \"%@\"", idNumber, query, numberOfFeatures, latitude, longitude, placeName);
    [_writer writeLineOfFields:@[idNumber, query, numberOfFeatures, latitude, longitude, placeName]];
    
    _currentRequestIndex++;
    [self sendNextRequest];
}

- (void) requestComplete:(FactualAPIRequest *)request failedWithError:(NSError *)error {
    NSLog(@"requestComplete:failedWithError: %@", error);
}

@end
