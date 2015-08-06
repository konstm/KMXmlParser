//
//  XmlFilesController.m
//  KMXmlParserDemo
//
//  Created by Konstantin Medynsky on 14/06/2015.
//  Copyright (c) 2015 Konstm. All rights reserved.
//

#import "XmlFilesController.h"
#import "XmlParsedController.h"
#import "KMXmlParser.h"

@interface XmlFilesController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableviewXmlFiles;

@end

@implementation XmlFilesController
{
    NSArray *xmlSamplesList;
    NSDictionary *namesMapDict;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    xmlSamplesList = [[NSBundle mainBundle] pathsForResourcesOfType:nil inDirectory:@"XmlExamples"];
    
    namesMapDict = @{
                     @"LawersAndSync.xml"       : @"SOAP data with refs",
                     @"ErrorNameSpace.xml"      : @"Example with namespaces",
                     };
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}







//////////////////////////////
#pragma mark - functions

-(NSString*) mappedName:(NSUInteger)row
{
    if (row >= xmlSamplesList.count)
        return nil;
    
    NSString *fileName = [xmlSamplesList[row] lastPathComponent];;
    NSString *mapped = namesMapDict[fileName];
    
    if (mapped.length)
        return mapped;
    
    return fileName;
}


-(id) parseXmlFile:(NSString*)filePath
{
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (data.length == 0)
        return nil;
    
    NSString *trimmed = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSData *trimmedData = [trimmed dataUsingEncoding:NSUTF8StringEncoding];
    NSString *filename = [filePath lastPathComponent];

    id result;
    
    KMXmlParser *xmlParser = [[KMXmlParser alloc] init];
    
    if ([filename isEqualToString:@"BooksSample.xml"])
    {
        xmlParser.discloseArrayTags = @[@"item", @"book"];
        result = [xmlParser parseXml:trimmedData nodeName:@"books"];
    }
    else if ([filename isEqualToString:@"MediaBookConfig.xml"])
    {
        xmlParser.discloseArrayTags = @[@"page"];
        result = [xmlParser parseXml:trimmedData nodeName:@"mediaBook"];
    }
    else if ([filename isEqualToString:@"LawersAndSync.xml"])
    {
        xmlParser.parseAllAttributes = NO;
        result = [xmlParser parseXml:trimmedData nodeName:@"return"];
    }
    else if ([filename isEqualToString:@"ShopsSample.xml"])
    {
        xmlParser.alwaysArrayTags = @[@"adresses"];
        xmlParser.discloseArrayTags = @[@"shop"];
        result = [xmlParser parseXml:trimmedData nodeName:@"data"];
    }
    else if ([filename isEqualToString:@"RecipesSample.xml"])
    {
        xmlParser.discloseArrayTags = @[@"item", @"category"];
        result = [xmlParser parseXml:trimmedData nodeName:@"data"];
    }
    else if ([filename isEqualToString:@"ErrorNameSpace.xml"])
    {
        [xmlParser registerNameSpace:@"SOAP-ENV" uri:@"http://schemas.xmlsoap.org/soap/envelope/"];  // for SOAP errors parsing
        result = [xmlParser parseXml:trimmedData nodeName:@"SOAP-ENV:Fault"];
    }
    else if ([filename isEqualToString:@"MembersOfCongress.xml"])
    {
        result = [xmlParser parseXml:trimmedData];
    }
    else if ([filename isEqualToString:@"St_Louis_Zoo_sample.gpx"])
    {
        result = [xmlParser parseXml:trimmedData];
    }
    


    
    return result;
}



//////////////////////////////
#pragma mark - TableView methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return xmlSamplesList.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellName = @"CellName";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellName];
    }
    
    cell.textLabel.text = [self mappedName:indexPath.row];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *filePath = xmlSamplesList[indexPath.row];
    
    id result = [self parseXmlFile:filePath];
    NSString *description = [result description];;
    
    
    XmlParsedController *parsedController = [self.storyboard instantiateViewControllerWithIdentifier:@"XmlParsedController"];
    parsedController.parsedDescription = description;
    
    [self.navigationController pushViewController:parsedController animated:YES];
}


@end
