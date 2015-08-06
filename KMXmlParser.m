//
//  KMXmlParser.m
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


#import "KMXmlParser.h"


@implementation KMXmlParser


//////////////////////////////////////////////////////////////////////////
#pragma mark - init

- (id)init
{
    self = [super init];
    if (self) {
        namespaces = [NSMutableDictionary dictionary];
//        parseAttributesOfTags = [NSMutableSet set];
        excludedFromParsingTags = [[NSMutableDictionary alloc]init];
        
        _discloseArrayTags = @[@"item"];
        _alwaysArrayTags = @[@"item"];
        
        _enableEmptyTags = NO;
        _parseAllAttributes = YES;
        _attributesAsSeparated = NO;
        _doCollections = YES;
        
        mappingKeyValueNames = [NSMutableArray arrayWithArray:@[@"key", @"value"]]; // default key-value
        
        referenceContentDict = [NSMutableDictionary dictionary];
    }
    return self;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - parameters for parsing


-(void)registerNameSpace:(NSString *)nsPrefix uri:(NSString *)uri {
    if (uri.length)
        [namespaces setObject:uri forKey:nsPrefix];
}

-(void)unRegisterNameSpace:(NSString *)nsPrefix {
    [namespaces removeObjectForKey:nsPrefix];
}

-(void)unRegisterAllNameSpaces {
    [namespaces removeAllObjects];
}


-(void)excludeTagFromParsing:(NSString *)tag doDump:(BOOL)doDump {
    [excludedFromParsingTags setObject:[NSNumber numberWithBool:doDump] forKey:tag];
}

-(void)includeTagToParsing:(NSString *)tag {
    [excludedFromParsingTags removeObjectForKey:tag];
}

-(void)includeAllTagsToParsing {
    [excludedFromParsingTags removeAllObjects];
}




// mapping keys
-(void) setMappingKeyName:(NSString*)keyName valueName:(NSString*)valueName {
    [mappingKeyValueNames removeAllObjects];
    
    if (keyName.length && valueName.length) {
        [mappingKeyValueNames addObject:keyName];
        [mappingKeyValueNames addObject:valueName];
    }
}


-(void) clearMappingKeyValueNames {
    [mappingKeyValueNames removeAllObjects];
}






///////////////////////////////////////////////////////////////////////
#pragma mark - parse xmlNodePtr - base code by Matt Gallagher


-(NSDictionary*) dictionaryForNode:(xmlNodePtr) currentNode  parentResult:(NSMutableDictionary*)parentResult
{
    NSMutableDictionary *resultForNode = [NSMutableDictionary dictionary];
    NSString *currentNodeName = nil;
    
    if (currentNode->name)
    {
        currentNodeName = [NSString stringWithCString:(const char *)currentNode->name encoding:NSUTF8StringEncoding];
        [resultForNode setObject:currentNodeName forKey:@"nodeName"];
    }
    
    
    NSNumber *doDump = nil;
    
    
    // exclude this node from parsing? - // konstm
    if (currentNodeName)
        doDump = [excludedFromParsingTags objectForKey:currentNodeName];
    
    if (doDump) {
        bool isDump = [doDump boolValue];
        
        if (isDump) {
            xmlBufferPtr buf = xmlBufferCreate();
            int numbytes = xmlNodeDump(buf, currentNode->doc, currentNode, 2, 1);
            
            if (numbytes) {
                const xmlChar *exclNodeContent = xmlBufferContent(buf);
                NSString *nodeContentStr = [NSString stringWithCString:(const char*)exclNodeContent encoding:NSUTF8StringEncoding];
                
                [resultForNode setObject:nodeContentStr forKey:@"nodeContent"];
                //                xmlFree((void*)exclNodeContent);
            }
            
            xmlBufferFree(buf);
        }
        
        //        xmlUnlinkNode(currentNode);
        //        xmlFreeNode(currentNode);
        
        if (isDump)
            return resultForNode;
        else
            return nil;
        
    }
    
    
    
    if (currentNode->content && currentNode->type != XML_DOCUMENT_TYPE_NODE)
    {
        NSString *currentNodeContent = [NSString stringWithCString:(const char *)currentNode->content encoding:NSUTF8StringEncoding];
        
        if ([currentNodeName isEqual:@"text"] && parentResult)
        {
            currentNodeContent = [currentNodeContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            NSString *existingContent = [parentResult objectForKey:@"nodeContent"];
            NSString *newContent;
            if (existingContent)
            {
                newContent = [existingContent stringByAppendingString:currentNodeContent];
            }
            else
            {
                newContent = currentNodeContent;
            }
            
            if (newContent.length) // konstm
                [parentResult setObject:newContent forKey:@"nodeContent"];
            
            return nil;
        }
        
        
        if (currentNodeContent.length) // konstm
            [resultForNode setObject:currentNodeContent forKey:@"nodeContent"];
        
    }
    
    
    xmlAttr *attribute = currentNode->properties;
    if (attribute)
    {
        NSMutableArray *attributeArray = [NSMutableArray array];
        while (attribute)
        {
            NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
            NSString *attributeName = [NSString stringWithCString:(const char *)attribute->name encoding:NSUTF8StringEncoding];
            if (attributeName)
            {
                [attributeDictionary setObject:attributeName forKey:@"attributeName"];
            }
            
            if (attribute->children)
            {
                NSDictionary *childDictionary = [self dictionaryForNode:attribute->children parentResult:attributeDictionary];
                if (childDictionary)
                {
                    [attributeDictionary setObject:childDictionary forKey:@"attributeContent"];
                }
            }
            
            if ([attributeDictionary count] > 0)
            {
                [attributeArray addObject:attributeDictionary];
            }
            attribute = attribute->next;
        }
        
        if ([attributeArray count] > 0)
        {
            [resultForNode setObject:attributeArray forKey:@"nodeAttributeArray"];
        }
    }
    
    
    
    
    
    xmlNodePtr childNode = currentNode->children;
    if (childNode)
    {
        NSMutableArray *childContentArray = [NSMutableArray array];
        while (childNode)
        {
            NSDictionary *childDictionary = [self dictionaryForNode:childNode parentResult:resultForNode];
            if (childDictionary)
            {
                [childContentArray addObject:childDictionary];
            }
            childNode = childNode->next;
        }
        if ([childContentArray count] > 0)
        {
            [resultForNode setObject:childContentArray forKey:@"nodeChildArray"];
        }
    }
    
    return resultForNode;
}








/////////////////////////////////////////////////////////////////////////////
#pragma mark - get NSArray of nodes from xml - base code by Matt Gallagher


-(NSArray*) nodesFromXMLData:(NSData*)xmlData XPathExpression:(NSString*)xpathExpression
{
    
    NSArray *result = nil;
    
    xmlDocPtr doc;
    xmlXPathContextPtr xpathCtx;
    
    /* Load XML document */
    doc = xmlReadMemory([xmlData bytes], [xmlData length], "", NULL, XML_PARSE_NOERROR); // XML_PARSE_RECOVER
    
    if (doc == NULL)
    {
        //// NSLog(@"Unable to parse.");
        return nil;
    }
    
    
    
    /* Create xpath evaluation context */
    xpathCtx = xmlXPathNewContext(doc);
    if(xpathCtx == NULL)
    {
        //// NSLog(@"Unable to create XPath context.");
        xmlFreeDoc(doc);
        return nil;
    }
    
    
    // check for namespaces - konstm
    for (NSString* nsPrefix in namespaces.allKeys) {
        xmlChar *prefix = BAD_CAST[nsPrefix cStringUsingEncoding:NSUTF8StringEncoding];
        xmlChar *uri = BAD_CAST[[namespaces valueForKey:nsPrefix] cStringUsingEncoding:NSUTF8StringEncoding];
        xmlXPathRegisterNs(xpathCtx, prefix, uri);
        
    }
    
    if (xpathExpression == nil) // no path expression - do parsing from root - konstm
    {
        xmlNodePtr root = xmlDocGetRootElement(doc);
        NSDictionary *nodeDict = [self dictionaryForNode:root parentResult:nil];
        if (nodeDict)
            result = [NSArray arrayWithObject:nodeDict];
    }
    
    else  // query of XMLPath
    {
        xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression((xmlChar *)[xpathExpression cStringUsingEncoding:NSUTF8StringEncoding], xpathCtx);
        if(xpathObj == NULL) {
            //// NSLog(@"Unable to evaluate XPath.");
            xmlXPathFreeContext(xpathCtx);
            xmlFreeDoc(doc);
            return nil;
        }
        
        
        
        xmlNodeSetPtr nodesSet = xpathObj->nodesetval;
        if (!nodesSet)
        {
            //// NSLog(@"Nodes was nil.");
            xmlXPathFreeObject(xpathObj);
            xmlXPathFreeContext(xpathCtx);
            xmlFreeDoc(doc);
            return nil;
        }
        
        
        
        NSMutableArray *nodesArray = [NSMutableArray array];
        for (NSInteger i = 0; i < nodesSet->nodeNr; i++)
        {
            NSDictionary *nodeDictionary =  [self dictionaryForNode:nodesSet->nodeTab[i] parentResult:nil];
            
            if (nodeDictionary)
                [nodesArray addObject:nodeDictionary];
        }
        
        if (nodesArray.count)
            result = nodesArray;
        
        
        /* Cleanup */
        xmlXPathFreeObject(xpathObj);
        
    }
    
    // Cleanup
    xmlXPathFreeContext(xpathCtx);
    xmlFreeDoc(doc);
    
    
    return result;
    
}





////////////////////////////////////////////////////////////////////////
#pragma mark - nodes structures parsing


-(id) parseNodeArray:(NSArray*)nodes
{
    static NSString *kNoNodeName = @"No_NodeName_In_NodeDict";
    
    NSMutableDictionary *contentDict = [NSMutableDictionary dictionary];
    
    for (NSDictionary *nodeDict in nodes)
    {
        NSString *nodeNameKey = [nodeDict valueForKey:@"nodeName"];
        
        if (nodeNameKey == nil) // may be this is an attributes array
            nodeNameKey = [nodeDict valueForKey:@"attributeName"];
        
        if (!nodeNameKey || !nodeNameKey.length)
            nodeNameKey = kNoNodeName; // the case of no nodename in node
        
        
        id content = [self parseNodeDict:nodeDict];
        if (content == nil)
            content = [NSNull null];
        
        
        id existedAlready = [contentDict objectForKey:nodeNameKey];  // was a node with the same name?
        
        if (existedAlready)
        {
            if (![existedAlready isKindOfClass:[NSArray class]]) {  // transform it to an array
                existedAlready = [NSMutableArray arrayWithObject:existedAlready];
                [contentDict setObject:existedAlready forKey:nodeNameKey];
            }
            
            [((NSMutableArray*)existedAlready) addObject:content];  // existedAlready - array of nodes with the identical names
        }
        else
        {
            [contentDict setObject:content forKey:nodeNameKey];
        }
        
    }
    
    
    // check if the item is expected to be an array
    for (NSString *key in contentDict.allKeys) {
        id value = [contentDict objectForKey:key];
        
        if (![value isKindOfClass:[NSArray class]] && [self.alwaysArrayTags containsObject:key])
            [contentDict setObject:[NSMutableArray arrayWithObject:value] forKey:key];
        
    }
    
    
    
    
    // If contentDict consists only of one object then check can we disclose dictionary
    if (contentDict.count == 1)
    {
        
        NSString *oneKey =[[contentDict allKeys] objectAtIndex:0];
        id oneObj = [contentDict objectForKey:oneKey];
        
        if (([oneObj isKindOfClass:[NSArray class]] && [self.discloseArrayTags containsObject:oneKey] ) || oneKey == kNoNodeName)
        {
            
            /*****
             if mapping key/value names are defined then try to transform the data like this:
             
             <item>
                 <key xsi:type="xsd:string">sort</key>
                 <value xsi:type="xsd:string">2769550</value>
             </item>
             <item>
                 <key> ...</key>
                 <value>...</value>
             </item>
             ...
             
             
             to the more convenient dictionary
             *****/
            
            if ([oneObj isKindOfClass:[NSArray class]] && mappingKeyValueNames.count == 2)
            {
                NSArray *innerArray = oneObj;
                
                // if array consists of one-entry dictionaries we'll try to convert it to the compound dictionary
                
                NSMutableSet *keysSet = [NSMutableSet set];
                NSMutableDictionary *compoundDict = [NSMutableDictionary dictionary];
                
                for (int i=0; i<innerArray.count && compoundDict!=nil; i++)
                {
                    id elem = [innerArray objectAtIndex:i];
                    
                    if ([elem isKindOfClass:[NSDictionary class]] && ((NSDictionary*)elem).count == 2)
                    {
                        
                        NSString *keyForKey = [[elem allKeys] objectAtIndex:0];
                        NSString *keyForValue = [[elem allKeys] objectAtIndex:1];
                        
                        if ([keyForKey isEqualToString:[mappingKeyValueNames objectAtIndex:0]] &&
                            [keyForValue isEqualToString:[mappingKeyValueNames objectAtIndex:1]] &&
                            [[elem objectForKey:keyForKey] isKindOfClass:[NSString class]])
                        {
                            NSString *key = [elem objectForKey:keyForKey];
                            
                            if ([keysSet member:key] == nil)
                            {
                                [keysSet addObject:key];
                                
                                id value = [elem objectForKey:keyForValue];
                                [compoundDict setObject:value forKey:key];
                            }
                            else
                            {
                                compoundDict = nil;
                            }
                        }
                        else
                        {
                            compoundDict = nil;
                        }
                    }
                    
                    else
                    {
                        compoundDict = nil;
                    }
                    
                }
                
                if (compoundDict != nil)
                    oneObj = compoundDict;
            }
            
            return oneObj;   // disclose contentDict
        }
    }
    
    return contentDict;
    
}





-(id) parseNodeDict:(NSDictionary*)node
{
    id content = nil;
    int notNilElements = 0; // how many parsed elements are gathered
    
    NSString *nodeName = [node valueForKey:@"nodeName"];
    if (nodeName && nodeName.length == 0)
        nodeName = nil;
    
    
    
    id nativeContent = [node objectForKey:@"nodeContent"];
    
    if ([nativeContent isKindOfClass:[NSString class]] && ((NSString*)nativeContent).length==0)
        nativeContent = nil;
    
    if (nativeContent) {
        content = nativeContent;
        notNilElements++;
    }
    
    
    
    id childContent = [node objectForKey:@"nodeChildArray"];
    
    if ([childContent isKindOfClass:[NSArray class]])
    {
        childContent = [self parseNodeArray:childContent];
    }
    
    if ([childContent isKindOfClass:[NSString class]] && ((NSString*)childContent).length==0)
        childContent = nil;
    
    if (childContent) {
        content = childContent;
        notNilElements++;
    }
    
    id attributesContent = nil;
    
    attributesContent = [node objectForKey:@"nodeAttributeArray"];
    
    if ([attributesContent isKindOfClass:[NSArray class]])
        attributesContent = [self parseNodeArray:attributesContent];
    
    if ([attributesContent isKindOfClass:[NSString class]] && ((NSString*)attributesContent).length==0)
        attributesContent = nil;
    
    
    if ([attributesContent isKindOfClass:[NSDictionary class]]) {
        NSString *ref = [attributesContent valueForKey:@"id"]; //  is it a reference ?
        
        if (ref != nil && [ref isKindOfClass:[NSString class]] && ref.length && childContent != nil) {
            [referenceContentDict setValue:childContent forKey:ref];  // then we save the content  for further using
        }
        else if (childContent == nil) {
            // try to find the reference which looks like  "#refN"
            
            ref = [attributesContent valueForKey:@"href"];
            
            if (ref && [ref isKindOfClass:[NSString class]] && ref.length && [ref characterAtIndex:0] == '#')
                ref = [ref substringFromIndex:1];
            
            if (ref && ref.length) {
                id refContent = [referenceContentDict valueForKey:ref];
                if (refContent) {
                    childContent = refContent;
                    content = childContent;
                    notNilElements++;
                }
            }
        }
    }
    
    if (attributesContent && nodeName && (self.parseAllAttributes || [_parseAttributesOfTags containsObject:nodeName])) // do attribute parsing?
    {
        if (! self.attributesAsSeparated)
        {
            content = attributesContent;
        }
        else
        {
            content = [NSMutableDictionary dictionaryWithObject:attributesContent forKey:@"attributes"];
        }
        
        notNilElements++;
    }
    
    
    
    
    
    if (notNilElements > 1) // if more than one elements are picked up into the dictionary
    {
        NSMutableDictionary *retDict = [NSMutableDictionary dictionary];
        NSMutableSet *keysSet = [NSMutableSet set];
        
        if (nativeContent)
        {
            [keysSet addObject:@"nodeContent"];
            [retDict setObject:nativeContent forKey:@"nodeContent"];
        }
        
        if (childContent)
        {
            NSDictionary *childDictionary = nil;
            
            if (! [childContent isKindOfClass:[NSDictionary class]])
            {
                childDictionary = @{@"child": childContent};
            }
            else
            {
                childDictionary = childContent;
            }
            
            NSMutableArray *childKeys = [NSMutableArray arrayWithArray:childDictionary.allKeys];
            for (NSString *key in childKeys)
            {
                NSString *putkey = [key copy];
                
                // if the key already exists in the result dictionary then change it's name
                for(int i = 1; [keysSet containsObject:putkey]; i++)
                    putkey = [NSString stringWithFormat:@"%@%03d",key, i];
                
                [keysSet addObject:putkey];
                
                [retDict setValue:[childDictionary valueForKey:key] forKey:putkey];
                
            }
            //            [retDict setObject:childContent forKey:@"childs"];
        }
        
        
        
        if (attributesContent && nodeName && (self.parseAllAttributes || [_parseAttributesOfTags containsObject:nodeName]))
        {
            if (! self.attributesAsSeparated)
            {
                NSDictionary *attribsDictionary = nil;
                
                if (! [attributesContent isKindOfClass:[NSDictionary class]])
                {
                    attribsDictionary = @{@"attributeChild": attributesContent};
                }
                else
                {
                    attribsDictionary = attributesContent;
                }
                
                for (NSString *key in attribsDictionary.allKeys)
                {
                    NSString *putkey = [key copy];
                    
                    // if the key already exists in the result dictionary then change it's presentation
                    
                    for(int i = 1; [keysSet containsObject:putkey]; i++)
                        putkey = [NSString stringWithFormat:@"%@%03d",key, i];
                    
                    [keysSet addObject:putkey];
                    
                    [retDict setValue:[attribsDictionary valueForKey:key] forKey:putkey];
                    
                }
            }
            else
            {
                [retDict setObject:attributesContent forKey:@"attributes"];
            }
        }
        
        content = retDict;
    }
    
    return content;
    
}




//////////////////////////////////////////////////////////////////////////////
#pragma mark - removing nulls


-(id) clearArrayFromNulls:(NSMutableArray*)array {
    
    for (int i=0; i < array.count; i++) {
        id elem = [array objectAtIndex:i];
        
        if ([elem isKindOfClass:[NSMutableDictionary class]])
            [array replaceObjectAtIndex:i withObject:[self clearDictionaryFromNulls:elem]];
        
        else if ([elem isKindOfClass:[NSMutableArray class]])
            [array replaceObjectAtIndex:i withObject:[self clearArrayFromNulls:elem]];
    }
    
    [array removeObject:[NSNull null]];
    
    if (array.count == 0)
        return [NSNull null];
    
    return array;
}


-(id)clearDictionaryFromNulls:(NSMutableDictionary*)dict {
    
    NSArray *allkeys = [dict allKeys];
    
    for (id key in allkeys) {
        id elem = [dict objectForKey:key];
        
        if ([elem isKindOfClass:[NSMutableDictionary class]])
            [dict setObject:[self clearDictionaryFromNulls:elem] forKey:key];
        
        else if ([elem isKindOfClass:[NSMutableArray class]])
            [dict setObject:[self clearArrayFromNulls:elem] forKey:key];
    }
    
    NSArray *keysOfNulls = [dict allKeysForObject:[NSNull null]];
    if (keysOfNulls.count)
        [dict removeObjectsForKeys:keysOfNulls];
    
    if (dict.count == 0)
        return [NSNull null];
    
    return dict;
    
}





//////////////////////////////////////////////////////////////////////////////
#pragma mark - functions


-(id) parseXml:(NSData*)xmlData xpathExpression:(NSString *)xpathExpression
{
    
    /////////////////////////  Debug information  ////////////////////////////////
    //    if (xmlData.length < 300000) {
    //        NSString *xmlStr = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
    //        NSLog(@"xml:\n%@", xmlStr);
    //    }
    ///////////////////////////////////////////////////////////////////////////////
    
    id result = nil;
    
    [referenceContentDict removeAllObjects];
    
    NSArray *nodes = [self nodesFromXMLData:xmlData XPathExpression:xpathExpression];
    
    if (nodes)
    {
        if (! self.doCollections)
            return nodes;
        
        result = [self parseNodeArray:nodes];
        
        if (!_enableEmptyTags) {
            
            if ([result isKindOfClass:[NSMutableArray class]])
                result = [self clearArrayFromNulls:result];
            else if ([result isKindOfClass:[NSMutableDictionary class]])
                result = [self clearDictionaryFromNulls:result];
            
            // if it returns nil we consider it as error now. We have later to look xmlError
            
            //            if (result == [NSNull null])
            //                result = nil;
            
            if (result == [NSNull null])
                result = [NSMutableArray array];
        }
    }
    
    if ([result isKindOfClass:[NSDictionary class]] && [result count] == 1) { // disclose dictionary if it consists of one entry
        result = [((NSDictionary*)result) objectForKey:[((NSDictionary*)result) allKeys][0]];
    }
    
    return result;
}



-(id) parseXml:(NSData*)xmlData nodeName:(NSString*)nodeName {
    
    NSString *expression = nodeName && nodeName.length ? [NSString stringWithFormat:@"//%@", nodeName] : nil;
    id result = [self parseXml:xmlData xpathExpression:expression];
    
    return result;
}



-(id) parseXml:(NSData*)xmlData {
    return [self parseXml:xmlData nodeName:nil];
}





/////////////////////////////////////////////////////////////////////////////////
#pragma mark - class methods

+(id) parseXml:(NSData*)xmlData XPathExpression:(NSString*)xpathExpression
{
    KMXmlParser *xparser = [KMXmlParser new];
    
    return [xparser parseXml:xmlData xpathExpression:xpathExpression];
    
}



+(id) parseXml:(NSData*)xmlData nodeName:(NSString*)nodeName {
    KMXmlParser *xparser = [KMXmlParser new];
    
    return [xparser parseXml:xmlData nodeName:nodeName];
    
}


+(id) parseXml:(NSData*)xmlData {
    return [self parseXml:xmlData nodeName:nil];
}




@end
