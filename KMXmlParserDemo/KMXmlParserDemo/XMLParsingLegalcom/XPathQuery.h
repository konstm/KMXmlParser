//
//  XPathQuery.h

//  Modified by konstantin on 31/05/12:
//  function PerformXPathQueryInNameSpace  
//
//
//  Created by developer on 26.09.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

NSArray *PerformHTMLXPathQuery(NSData *document, NSString *query);
NSArray *PerformXMLXPathQuery(NSData *document, NSString *query);
NSArray* PerformXMLXPathQueryInNamespace(NSData *document, NSString *query, NSString *ns_prefix, NSString *ns_uri);
NSDictionary *DictionaryForNode(xmlNodePtr currentNode, NSMutableDictionary *parentResult);
NSArray* PerformXPathQueryInNameSpace(xmlDocPtr doc, NSString *query, NSString *ns_prefix, NSString *ns_uri) ;
NSArray *PerformXPathQuery(xmlDocPtr doc, NSString *query);



