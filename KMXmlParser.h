//
//  KMXmlParser.h
//  KMXmlParserDemo
//
//  Created by Konstantin Medynsky on 14/06/2015.
//  Copyright (c) 2015 Konstm. All rights reserved.
//
//  Created by Matt Gallagher on 4/08/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//


#import <Foundation/Foundation.h>

#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@interface KMXmlParser : NSObject
{
    NSMutableDictionary *namespaces;
    NSMutableDictionary *excludedFromParsingTags;
    NSMutableArray *mappingKeyValueNames;
    NSMutableDictionary *referenceContentDict;
}


// present empty elements as [NSNull null] or exclude them from the result
@property (nonatomic, assign) BOOL enableEmptyTags;

// set the names of elements that will always be presented as an arrays
@property (strong, nonatomic) NSArray *alwaysArrayTags;

// set the names of elements that will be disclosed from one-entry dictionary if the value's type is an array
@property (strong, nonatomic) NSArray *discloseArrayTags;

// attibute parsing
@property (assign, nonatomic) BOOL parseAllAttributes;

// parse attributes only of these tags
@property (strong, nonatomic) NSArray *parseAttributesOfTags;

// attributes are represented in the separate dictionary
@property (assign, nonatomic) BOOL attributesAsSeparated;


// stop the parsing after first pass and return result as it was made by Matt Gallagher
@property (assign, nonatomic) BOOL doCollections;


// for capture key-value mapping
-(void) setMappingKeyName:(NSString*)keyName valueName:(NSString*)valueName;
-(void) clearMappingKeyValueNames;


// namespaces
-(void) registerNameSpace:(NSString*)nsPrefix uri:(NSString*)uri;
-(void) unRegisterNameSpace:(NSString*)nsPrefix;
-(void) unRegisterAllNameSpaces;


// exclude xml element with tag name from parsing
-(void) excludeTagFromParsing:(NSString*)tag doDump:(BOOL)doDump;
-(void) includeTagToParsing:(NSString*)tag;
-(void) includeAllTagsToParsing;



// execute parsing
-(id) parseXml:(NSData*)xmlData xpathExpression:(NSString *)xpathExpression;
-(id) parseXml:(NSData*)xmlData nodeName:(NSString*)nodeName;
-(id) parseXml:(NSData*)xmlData;




// class methods with default settings of parsing control
+(id) parseXml:(NSData*)xmlData XPathExpression:(NSString*)xpathExpression;
+(id) parseXml:(NSData*)xmlData nodeName:(NSString*)nodeName;
+(id) parseXml:(NSData*)xmlData;


@end
