//
//  XMLParser.h
//  W1Client
//
//  Created by Oleg Lutsenko on 12/1/09.
//  Copyright 2009 KaTeT-Software. All rights reserved.
//

#import <Foundation/Foundation.h>


NSArray * getMessagesAndSync(NSArray * arr);
NSArray* getNearestLawyersArray(NSArray* arr);
NSDictionary* getNearestLawyerDictionaryComponent(NSArray* arr);


@interface XMLParser : NSObject {
	
}


+ (NSString *)getErrorTextFromFaultcode:(NSString *)faultcode;

+ (NSDictionary *)parseData:(NSData *)xmlData ofType:(NSString *)dataType;

+ (NSDictionary *)parseForLogin:(NSData *)_xmlData;
+ (NSDictionary *)parseForLogout:(NSData *)_xmlData;
+ (NSDictionary *)parseForMyBriefMessages:(NSData *)_xmlData;
+ (NSDictionary *)parseForLawyersBrief:(NSData *)_xmlData;
+ (NSDictionary *)parseForLawyersAndSync:(NSData *)_xmlData;
+ (NSDictionary *)parseForLawyerById:(NSData *)_xmlData;
+ (NSDictionary *)parseForLawyersUpToDate:(NSData *)_xmlData;
+ (NSDictionary *)parseForMessageByID:(NSData *)_xmlData;
+ (NSDictionary *)parseForSendMessage:(NSData *)_xmlData;
+ (NSDictionary *)parseForSetMessageStatus:(NSData *)_xmlData;
+ (NSDictionary *)parseForMessagesUpToDate:(NSData *)_xmlData;

+ (NSDictionary *)parseLawyerRegistrationStep1:(NSData *)_xmlData;
+ (NSDictionary *)parseForChangeEmail:(NSData *)_xmlData;
+ (NSDictionary *)parseForLawyerVote:(NSData *)_xmlData;
+ (NSDictionary *)parseForReceiptVerify:(NSData *)_xmlData;

+ (NSDictionary *)parseForNearestLawyersLocations:(NSData *)_xmlData;
+ (NSDictionary *)parseForSendLawyerLocation:(NSData *)_xmlData;
+ (NSString *)getValueFromXML:(NSString *)responseText forTag:(NSString *)tag;
NSString * typeNameNodeDictionary(NSDictionary * nodeDictionary) ;

id parseNodeDictionary(NSDictionary * nodeDictionary) ;

@end
