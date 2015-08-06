//
//  XMLParser.m
//  W1Client
//
//  Created by Oleg Lutsenko on 12/1/09.
//  Copyright 2009 KaTeT-Software. All rights reserved.
//

#import "XMLParser.h"
#import "Constants.h"
#import "XPathQuery.h"
#import <mach/mach.h>
#import <mach/mach_host.h>



static NSDictionary* getDictionaryFromArray(NSArray * arr) {
    NSMutableDictionary * result = [NSMutableDictionary dictionary];
    for (NSDictionary * nodeChild in arr ) {
        if ([nodeChild valueForKey:@"nodeContent"] && [nodeChild valueForKey:@"nodeName"]) {
            NSDictionary * pair = [NSDictionary dictionaryWithObject:[nodeChild valueForKey:@"nodeContent"] 
                                                          forKey:[nodeChild valueForKey:@"nodeName"]];
            [result addEntriesFromDictionary:pair];
        }
        
    }
    return result;
}

static NSDictionary * getMessageAndState(NSArray * array) {
    NSMutableDictionary * result = [NSMutableDictionary dictionaryWithCapacity:2];
    NSDictionary * mes = getDictionaryFromArray([[array objectAtIndex:0] objectForKey:@"nodeChildArray"]);
    NSDictionary * state = getDictionaryFromArray([[array objectAtIndex:1] objectForKey:@"nodeChildArray"]);
    if (mes.count) 
        [result setObject:mes forKey:@"message"];
    [result setObject:state forKey:@"state"];
    return result;
}

static NSArray * getArrayFromArray(NSArray * arr) {
    NSMutableArray * result = [NSMutableArray arrayWithCapacity:[arr count]];
    for (NSDictionary * nodeChild in arr ) {
        NSDictionary * object = getDictionaryFromArray([nodeChild objectForKey:@"nodeChildArray"]);
        [result addObject:object];
    }
    return result;
}

NSDictionary* getNearestLawyerDictionaryComponent(NSArray* arr) {
    NSMutableDictionary * result = [NSMutableDictionary dictionary];
    for (NSDictionary * nodeChild in arr ) {
        
        if ([nodeChild valueForKey:@"nodeContent"] && [nodeChild valueForKey:@"nodeName"]) {
            NSDictionary * pair = [NSDictionary dictionaryWithObject:[nodeChild valueForKey:@"nodeContent"]
                                                              forKey:[nodeChild valueForKey:@"nodeName"]];
            [result addEntriesFromDictionary:pair];
        } else if ([nodeChild valueForKey:@"nodeName"] && [nodeChild valueForKey:@"nodeChildArray"]) {
            
            //////////////////////////////////  This code only for debug  ///////////////////////////////////
//            NSArray* internalArr = [nodeChild valueForKey:@"nodeChildArray"];
//            NSDictionary * object = getNearestLawyerDictionaryComponent(internalArr);
//            NSDictionary * pair = [NSDictionary dictionaryWithObject:object
//                                                              forKey:[nodeChild valueForKey:@"nodeName"]];
            /////////////////////////////////////////////////////////////////////////////////////////////////
            
            NSDictionary * pair = [NSDictionary dictionaryWithObject:getNearestLawyerDictionaryComponent([nodeChild valueForKey:@"nodeChildArray"])
                                                              forKey:[nodeChild valueForKey:@"nodeName"]];
            [result addEntriesFromDictionary:pair];
        }
        
    }
    return result;
}

NSArray* getNearestLawyersArray(NSArray* arr) {
    NSMutableArray * result = [NSMutableArray arrayWithCapacity:[arr count]];
    for (NSDictionary * nodeChild in arr ) {
        NSDictionary * object = getNearestLawyerDictionaryComponent([nodeChild objectForKey:@"nodeChildArray"]);
        [result addObject:object];
    }
    return result;
}

NSArray * getMessagesAndSync(NSArray * arr) {
    NSMutableArray * result = [NSMutableArray arrayWithCapacity:[arr count]];
    for (NSDictionary * nodeChild in arr ) {
        NSDictionary * object = getMessageAndState([nodeChild objectForKey:@"nodeChildArray"]);
        [result addObject:object];
    }
    return result;
}



typedef enum { SOAPNotAggregateType=0, SOAPArrayType, SOAPStructType, SOAPMapType } SOAPType;


// maps type names for equality array, struct(dictionary), map

static NSString *equalsArray[] = {@"array", nil};
static NSString *equalsStruct[] = {@"sruct", @"Person", @"Lawyer", @"Country", @"Language", @"Education", @"Experience", @"Message", @"Location", nil};
static NSString *equalsMap[] = {@"map", nil};

NSString * typeNameNodeDictionary(NSDictionary * nodeDictionary) {
    
    NSArray *attributeArray = [nodeDictionary objectForKey:@"nodeAttributeArray"];
    
    for (NSDictionary *attrDict in attributeArray)
        if ( [[attrDict valueForKey:@"attributeName"] isEqualToString:@"type"]) 
            return [attrDict valueForKey:@"nodeContent"];
    
    return nil;
}




SOAPType defineSOAPType(NSString*typename);

SOAPType defineSOAPType(NSString*typename) {
    
    static SOAPType soapTypes[] = {SOAPArrayType, SOAPStructType, SOAPMapType, SOAPNotAggregateType};
    static  NSString ** equals[] = {equalsArray, equalsStruct, equalsMap, nil};
    
    SOAPType *pType = soapTypes;
    NSString ***pEqualsArray = equals;
    
    while (*pEqualsArray) {
        NSString **pEquals = *pEqualsArray;
        while (*pEquals) {
            if ([typename containsString:*pEquals])
                return *pType;
            pEquals++;
        }
        
        pType++;
        pEqualsArray++;
    }
    
    return *pType;
}

id parseNodeDictionary(NSDictionary * nodeDictionary) {
    
    if (nodeDictionary == nil)
        return nil;
    
    SOAPType soapType = SOAPNotAggregateType;
    
    NSArray *nodeChildArray;
    id content = nil;
    
    // get content of attribute "type" 
    NSString *nodeTypeName = typeNameNodeDictionary(nodeDictionary);
    
    
    //    if ([nodeTypeName containsString:@"array"])
    //        soapType = SOAPArrayType;
    //    else if ([nodeTypeName containsString:@"struct"])
    //        soapType = SOAPStructType;
    //    else if ([nodeTypeName containsString:@"map"])
    //        soapType = SOAPMapType;
    //    else if ([nodeDictionary objectForKey:@"nodeChildArray"])  // soap type not defined, but many entries exists - make dictionary
    //        soapType = SOAPStructType;
    
    soapType = defineSOAPType(nodeTypeName);
    
    // if SOAPNotAggregateType && many entries exists - make dictionary
    if (soapType == SOAPNotAggregateType && [nodeDictionary objectForKey:@"nodeChildArray"])
        soapType = SOAPStructType;
        
        if (soapType == SOAPNotAggregateType) { // simple type
            
            content = [nodeDictionary objectForKey:@"nodeContent"];
            if (content == nil)
                return nil;
            
            return [NSDictionary dictionaryWithObject:content forKey:[nodeDictionary valueForKey:@"nodeName"]];
        }
    
        else { // aggregate type - array, struct, map
            
            nodeChildArray = [nodeDictionary valueForKey:@"nodeChildArray"];
            if (nodeChildArray == nil)
                return nil;
            
            if (soapType == SOAPArrayType)
                content = [NSMutableArray arrayWithCapacity:nodeChildArray.count];
            else
                content = [NSMutableDictionary dictionaryWithCapacity:nodeChildArray.count];
        }
    
    
    
    for (NSDictionary *itemDict in nodeChildArray) {
        
        if (soapType == SOAPMapType) {  // MAP
            
            NSArray *mapArray = [itemDict objectForKey:@"nodeChildArray"];
            NSString *mapKey = nil;
            id mapValue = nil;
            
            for (NSDictionary *mapItem in mapArray) {
                
                NSString *mapNodeName = [mapItem valueForKey:@"nodeName"];
                
                if ([mapNodeName isEqualToString:@"key"]) {
                    mapKey = [mapItem valueForKey:@"nodeContent"];
                }
                
                else if ([mapNodeName isEqualToString:@"value"]) {
                    
                    NSString *mapValueTypeName = typeNameNodeDictionary(mapItem);
                    
                    //                    if ([mapValueTypeName containsString:@"array"] ||
                    //                        [mapValueTypeName containsString:@"struct"] ||
                    //                        [mapValueTypeName containsString:@"map"]
                    //                        )
                    //                        mapValue = [self parseNodeDictionary:mapItem];  // nested aggreagate - nested parsing
                    //                    else 
                    //                        mapValue = [mapItem objectForKey:@"nodeContent"];
                    
                    
                    if (defineSOAPType(mapValueTypeName) != SOAPNotAggregateType) // nested aggreagate - nested parsing
                        mapValue = parseNodeDictionary(mapItem);
                    else 
                        mapValue = [mapItem objectForKey:@"nodeContent"];
                    
                }
                
                if (mapKey && mapValue) 
                    [content setObject:mapValue forKey:mapKey];
            }
            
        }
        
        else { // Array or Struct
            
            // get content of attribute "type"
            
            NSString *itemTypeName = typeNameNodeDictionary(itemDict);
            
            id itemContent = nil;
            
            //            if ([itemTypeName containsString:@"array"] || [itemTypeName containsString:@"struct"]|| [itemTypeName containsString:@"map"]) 
            //                itemContent = [self parseNodeDictionary:itemDict];  // nested aggreagate - nested parsing
            //            else
            //                itemContent = [itemDict objectForKey:@"nodeContent"];
            
            if (defineSOAPType(itemTypeName) == SOAPNotAggregateType)
                itemContent = [itemDict objectForKey:@"nodeContent"];
            else
                itemContent = parseNodeDictionary(itemDict);  // nested aggreagate - nested parsing
            
            
            if (itemContent) {
                if (soapType == SOAPArrayType)
                    [content addObject:itemContent];
                else
                    [content setObject:itemContent forKey:[itemDict valueForKey:@"nodeName"]];
            }
            
        }
    }
    
    if (content && [content count]==0)
        return nil;
    
    return content;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface XMLParser ()

+ (NSArray *)getNodesArrayFromData:(NSData *)_xmlData byPathQuery:(NSString *)path;
+ (NSDictionary *)parseForError:(NSData *)_xmlData;
+ (NSString *)getErrorTextFromFaultcode:(NSString *)faultcode;

@end



//////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation XMLParser


#pragma mark -
#pragma mark Common parser

+ (NSDictionary *)parseData:(NSData *)xmlData ofType:(NSString *)dataType {
	
    // CategoryList
	if ([dataType isEqualToString:LCRequestLogin]) {		
		return [XMLParser parseForLogin:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestLogout]) {		
		return [XMLParser parseForLogout:xmlData];
	}
	else if ([dataType isEqualToString:LCRequestGetMyBriefMessages] ||
             [dataType isEqualToString:LCRequestMessagesAndSync] ||
             [dataType isEqualToString:LCRequestLawyerRegistrationStep2] ||
             [dataType isEqualToString:LCRequestLawyerRegistrationStep3] ||
             [dataType isEqualToString:LCRequesteditLawyerEducations] ||
             [dataType isEqualToString:LCRequstGetClientsOfLawyer] ||
             [dataType isEqualToString:LCRequesteditLawyerExperiences]) {
		return [XMLParser parseForMyBriefMessages:xmlData];
	}
	else if ([dataType isEqualToString:LCRequestGetLawyersBrief ] ||
             [dataType isEqualToString:LCRequestGetPersonsById] ||
             [dataType isEqualToString:LCRequestFindLawyers] ||
             [dataType isEqualToString:LCRequstCanSendMessagesForPerson] ||
             /*[dataType isEqualToString:LCRequstGetClientsOfLawyer] ||*/
             [dataType isEqualToString:LCRequstGetQuestionsOfPerson]||[dataType isEqualToString:LCRequestChatQuestiionsListForClient]) {
		return [XMLParser parseForLawyersBrief:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestGetLawyersAndSync]) {		
		return [XMLParser parseForLawyersAndSync:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestGetLawyersById]) {
		return [XMLParser parseForLawyerById:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestLawyersUpToDate]) {	
		return [XMLParser parseForLawyersUpToDate:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestGetMessageByID] ||
             [dataType isEqualToString:LCRequestGetAllInvitations]) {
		return [XMLParser parseForMessageByID:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestSendMessage] ||
             [dataType isEqualToString:LCRequestLawyerRegistrationStep5] ||
             [dataType isEqualToString:LCRequestChangePhoto]) {		
		return [XMLParser parseForSendMessage:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestSetMessageStatus] ||
             [dataType isEqualToString:LCRequestIsEmailVerificated] ||
             [dataType isEqualToString:LCRequestMessageStatusRead]) {
		return [XMLParser parseForSetMessageStatus:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestMessagesUpToDate] ||
             [dataType isEqualToString:LCRequestProductID]) {
		return [XMLParser parseForMessagesUpToDate:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestLawyerRegistrationStep1] ||
             [dataType isEqualToString:LCRequestClientRegistration] ||
             [dataType isEqualToString:LCRequestEditLawyerInfo]) {		
		return [XMLParser parseLawyerRegistrationStep1:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestChangeEmail] ||
             [dataType isEqualToString:LCRequestChangePassword] ||
             [dataType isEqualToString:LCRequestForgotPassword] ||
             [dataType isEqualToString:LCRequestInviteWithEmail]) {
		return [XMLParser parseForChangeEmail:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestLawyerRateVote]) {
		return [XMLParser parseForLawyerVote:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestCheckReceipt]) {
		return [XMLParser parseForReceiptVerify:xmlData];
	}
    else if ([dataType isEqualToString:LCRequestNearestLawyersLocations]) {
        return [XMLParser parseForNearestLawyersLocations:xmlData];
    }
    else if ([dataType isEqualToString:LCRequestSetLawyerLocation]) {
        return [XMLParser parseForSendLawyerLocation:xmlData];
    }
	return nil;
}

#pragma mark -
#pragma mark Service functions

+ (NSArray *)getNodesArrayFromData:(NSData *)_xmlData byPathQuery:(NSString *)path {
    NSMutableString *xmlNonPatched = [[[NSMutableString alloc] initWithData:_xmlData encoding:NSUTF8StringEncoding] autorelease];
	[xmlNonPatched replaceOccurrencesOfString:@"xmlns=" withString:@"xmlns:ree=" options:NSBackwardsSearch range:NSMakeRange(0, [xmlNonPatched length])];
	
	//XML data
	NSData *xmlData = [NSData dataWithData:[xmlNonPatched dataUsingEncoding:NSUTF8StringEncoding]];
	
    //Parse XML data from specified tag (key)
	NSString *xPathQuery = [NSString stringWithString:path];
	return PerformXMLXPathQuery(xmlData, xPathQuery);
}

+ (NSDictionary *)parseForError:(NSData *)_xmlData {
    NSDictionary * result;
    NSString *xPathQuery = @"//faultcode";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
    if (nodes && nodes.count) {
        result = [NSDictionary dictionaryWithObject:[self getErrorTextFromFaultcode:[[nodes objectAtIndex:0] valueForKey:@"nodeContent"]] forKey:@"errorString"];
    }
    else {
        result = [NSDictionary dictionaryWithObject:ErrorUnrecognizedServerError forKey:@"errorString"];
    }
    return result;
}

+ (NSString *)getErrorTextFromFaultcode:(NSString *)faultcode {
    if ([faultcode isEqualToString:@"AccessDeniedException"]) {
        return NSLocalizedString(@"Access denied", nil);
    }
    else if ([faultcode isEqualToString:@"AuthFailedException"]) {
        return NSLocalizedString(@"Auth failed", nil);
    }
    else if ([faultcode isEqualToString:@"NotFoundException"]) {
        return NSLocalizedString(@"Object have not found", nil);
    }
    else if ([faultcode isEqualToString:@"TokenNotFoundException"]) {
        return NSLocalizedString(@"Token not found", nil);
    }
    else if ([faultcode isEqualToString:@"CException"]) {
        return NSLocalizedString(ErrorUnrecognizedServerError, nil);
    }
    else if ([faultcode isEqualToString:@"SendMessageDeniedException"]) {
        return NSLocalizedString(ErrorNoSubscriptionSend, nil);
    }
    else if ([faultcode isEqualToString:@"ReceiveMessageDeniedException"]) {
        return NSLocalizedString(ErrorNoSubscriptionReceive, nil);
    }
    else if ([faultcode isEqualToString:@"EditQuestionException"])
    {
        return NSLocalizedString(@"Editing question failed.", nil);
    }
    return faultcode;
}

+ (NSString *)getValueFromXML:(NSString *)responseText forTag:(NSString *)tag {
    NSRange range = [responseText rangeOfString:tag];
    if (range.location!=NSNotFound) {
        return [NSString stringWithFormat:@"%d",[[responseText substringFromIndex:range.location+range.length+1] intValue]];
    }
    return @"";
}


#pragma mark -
#pragma mark Individual parsers

+ (NSDictionary *)parseForLogin:(NSData *)_xmlData {
	
	//Create text copy of response
	//NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
	
	//Init result variable
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	[result setValue:@"fail" forKey:@"result"];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSDictionary * sessionId = getDictionaryFromArray([[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"]);
        NSMutableDictionary * account = parseNodeDictionary([[[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"] objectAtIndex:1]);
        NSMutableDictionary * person = parseNodeDictionary([[[[[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"] objectAtIndex:1] valueForKey:@"nodeChildArray"] objectAtIndex:7]);
        
/*        NSArray * educations = parseNodeDictionary([[[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"] objectAtIndex:2]);
        NSArray * experiences = parseNodeDictionary([[[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"] objectAtIndex:3]);
        
        if (educations) {
            [person setObject:educations forKey:@"educations"];
        }
        else {
            [person setObject:[NSArray array] forKey:@"educations"];
        }
        
        if (experiences) {
            [person setObject:experiences forKey:@"experiences"];
        }
        else {
            [person setObject:[NSArray array] forKey:@"experiences"];
        } */
        
        [account setObject:person forKey:@"person"];
        [result setValue:@"success" forKey:@"result"];
        NSMutableDictionary * data = [NSMutableDictionary dictionaryWithCapacity:2];
        [data addEntriesFromDictionary:sessionId];
        [data setValue:account forKey:@"account"];
        [result setValue:data forKey:@"data"];
        return result;
    }
    
///    return nil;
	else {
		
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
	
	return (NSDictionary *) result;
}

+ (NSDictionary *)parseForLogout:(NSData *)_xmlData {
    //Create text copy of response
	//NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
	
	//Init result variable
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	[result setValue:@"fail" forKey:@"result"];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        [result setValue:@"success" forKey:@"result"];
        NSDictionary * res = [NSDictionary dictionaryWithObject:[[nodes objectAtIndex:0] valueForKey:@"nodeContent"] forKey:@"result"] ;
        [result setValue:res forKey:@"data"];
        return result;
    }
    
    ///    return nil;
	else {
		
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
	
	return (NSDictionary *) result;
}

+ (NSDictionary *)parseForMyBriefMessages:(NSData *)_xmlData {
    //NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
    
    //NSLog(@"XMLParser response text = %@", responseText);
	
	//Init result variable
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	[result setValue:@"fail" forKey:@"result"];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSArray * briefMessages = parseNodeDictionary([nodes objectAtIndex:0]);
        [result setValue:@"success" forKey:@"result"];
        [result setValue:briefMessages forKey:@"data"];
        return result;
    }
    
    ///    return nil;
	else {
		
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
	
	return (NSDictionary *) result;
}

+ (NSDictionary *)parseForLawyersBrief:(NSData *)_xmlData {
//    NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes]
//                                                       length:[_xmlData length]
//                                                     encoding:NSUTF8StringEncoding] autorelease];
//    NSLog(@"XMLParser response text = %@", responseText);
	
	//Init result variable
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	[result setValue:@"fail" forKey:@"result"];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSArray * briefLawyers = parseNodeDictionary([nodes objectAtIndex:0]);
        [result setValue:@"success" forKey:@"result"];
        [result setValue:briefLawyers forKey:@"data"];
        //NSLog(@"XMLParser parseForLawyersBrief: %@", result);
        return result;
    }
	else {
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
    //NSLog(@"XMLParser parseForLawyersBrief: %@", result);
	return (NSDictionary *) result;
}

+ (NSDictionary *)parseForLawyersAndSync:(NSData *)_xmlData {
    //NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
    return [XMLParser parseForLawyersBrief:_xmlData];
}

+ (NSDictionary *)parseForLawyerById:(NSData *)_xmlData {
    	//same code
	return [XMLParser parseForLawyersBrief:_xmlData];
}

+ (NSDictionary *)parseForLawyersUpToDate:(NSData *)_xmlData {
    return [XMLParser parseForLawyersBrief:_xmlData];
}

+ (NSDictionary *)parseForMessageByID:(NSData *)_xmlData {
    //same code
    //NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
	
	//Init result variable
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	[result setValue:@"fail" forKey:@"result"];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSArray * briefMessages = getArrayFromArray([[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"]);
        [result setValue:@"success" forKey:@"result"];
        [result setValue:briefMessages forKey:@"data"];
        return result;
    }
	else {
		
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
	
	return (NSDictionary *) result;
}

+ (NSDictionary *)parseForSendMessage:(NSData *)_xmlData {
    //same code
	return [XMLParser parseForLawyersBrief:_xmlData];
}

+ (NSDictionary *)parseForSetMessageStatus:(NSData *)_xmlData {
    //NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
	
	//Init result variable
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	[result setValue:@"fail" forKey:@"result"];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSArray * briefLawyers = parseNodeDictionary([nodes objectAtIndex:0]);
        [result setValue:@"success" forKey:@"result"];
        [result setValue:briefLawyers forKey:@"data"];
        return result;
    }
    
    ///    return nil;
	else {
		
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
        return (NSDictionary *) result;
	}
}

+ (NSDictionary *)parseForMessagesUpToDate:(NSData *)_xmlData {
    //NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
	
	//Init result variable
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	[result setValue:@"fail" forKey:@"result"];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSArray * briefLawyers = getArrayFromArray([[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"]);
        [result setValue:@"success" forKey:@"result"];
        [result setValue:briefLawyers forKey:@"data"];
        return result;
    }
	else {
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
	
	return (NSDictionary *) result;
}

+ (NSDictionary *)parseLawyerRegistrationStep1:(NSData *)_xmlData {
//    NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
//    NSLog(@"XMLParser parseLawyerRegistrationStep1 response: %@", responseText);
	
	//Init result variable
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	[result setValue:@"fail" forKey:@"result"];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSDictionary * sessionId = getDictionaryFromArray([[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"]);
        NSMutableDictionary * account = parseNodeDictionary([[[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"] objectAtIndex:1]);
        NSDictionary * person = parseNodeDictionary([[[[[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"] objectAtIndex:1] valueForKey:@"nodeChildArray"] objectAtIndex:7]);
        
        if ([[sessionId valueForKey:@"result"] length] > 1) {
            [result setValue:@"success" forKey:@"result"];
            [account setObject:person forKey:@"person"];
            NSMutableDictionary * data = [NSMutableDictionary dictionaryWithCapacity:2];
            [data setValue:account forKey:@"account"];
            [data setValue:[sessionId valueForKey:@"result"] forKey:@"sessionId"];
            [result setValue:data forKey:@"data"];
        }
        else if ([[sessionId valueForKey:@"result"] intValue] == 0){
            NSDictionary * account = parseNodeDictionary([[[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"] objectAtIndex:2]);
            [result setValue:@"success" forKey:@"result"];
            [result setValue:account forKey:@"data"];
        }
        
        //NSLog(@"parseLawyerRegistrationStep1: %@", result);
        return result;
    }
    
    ///    return nil;
	else {
		
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
	
	return (NSDictionary *) result;
}

+ (NSDictionary *)parseForChangeEmail:(NSData *)_xmlData {
    //NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
	
	//Init result variable
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	[result setValue:@"fail" forKey:@"result"];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSDictionary * info = parseNodeDictionary([nodes objectAtIndex:0]);
        [result setValue:@"success" forKey:@"result"];
        [result setValue:info forKey:@"data"];
        return result;
    }
    
    ///    return nil;
	else {
		
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
	
	return (NSDictionary *) result;
}

+ (NSDictionary *)parseForLawyerVote:(NSData *)_xmlData {
	//Init result variable
    //NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSDictionary * info = parseNodeDictionary([nodes objectAtIndex:0]);
        [result setValue:@"success" forKey:@"result"];
        [result setValue:info forKey:@"data"];
        return result;
    }
    
    ///    return nil;
	else {
		[result setValue:@"fail" forKey:@"result"];
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
	
	return (NSDictionary *) result;
}

+ (NSDictionary *)parseForReceiptVerify:(NSData *)_xmlData {
	//Init result variable
    //NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSDictionary * info = parseNodeDictionary([nodes objectAtIndex:0]);
        if ([[info objectForKey:@"result"] boolValue]) {
            [result setValue:@"success" forKey:@"result"];
        } else {
            [result setValue:@"fail" forKey:@"result"];
        }
        [result setValue:info forKey:@"data"];
        return result;
    }
	else {
		[result setValue:@"fail" forKey:@"result"];
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
	
	return (NSDictionary *) result;
}


+ (NSDictionary *)parseForNearestLawyersLocations:(NSData *)_xmlData {
//    NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
//    NSLog(@"XMLParser response text = %@", responseText);
	
	//Init result variable
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	[result setValue:@"fail" forKey:@"result"];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSArray * nearestLawyers = getNearestLawyersArray([[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"]);
        [result setValue:@"success" forKey:@"result"];
        [result setValue:nearestLawyers forKey:@"data"];
        return result;
        
//        NSDictionary * info = parseNodeDictionary([[nodes objectAtIndex:0] valueForKey:@"nodeChildArray"]);
//        if ([[info objectForKey:@"result"] boolValue]) {
//            [result setValue:@"success" forKey:@"result"];
//        } else {
//            [result setValue:@"fail" forKey:@"result"];
//        }
//        [result setValue:info forKey:@"data"];
//        return result;
    }
	else {
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
	return (NSDictionary *) result;
}


+ (NSDictionary *)parseForSendLawyerLocation:(NSData *)_xmlData {
//    NSString *responseText = [[[NSString alloc] initWithBytes:[_xmlData bytes] length:[_xmlData length] encoding:NSUTF8StringEncoding] autorelease];
//    NSLog(@"XMLParser response text = %@", responseText);
	
	//Init result variable
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	[result setValue:@"fail" forKey:@"result"];
	
	NSString *xPathQuery = @"//return";
	NSArray *nodes = [XMLParser getNodesArrayFromData:_xmlData byPathQuery:xPathQuery];
	
	if (nodes.count == 1) {
        NSDictionary * info = parseNodeDictionary([nodes objectAtIndex:0]);
        [result setValue:@"success" forKey:@"result"];
        [result setValue:info forKey:@"data"];
        return result;
    }
	else {
		//Compose error
		[result addEntriesFromDictionary:[XMLParser parseForError:_xmlData]];
	}
	return (NSDictionary *) result;
}


@end
