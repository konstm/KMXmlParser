//
//  XmlParsedController.m
//  KMXmlParserDemo
//
//  Created by Konstantin Medynsky on 14/06/2015.
//  Copyright (c) 2015 Konstm. All rights reserved.
//

#import "XmlParsedController.h"

@interface XmlParsedController ()
@property (weak, nonatomic) IBOutlet UITextView *textviewParsed;
@end

@implementation XmlParsedController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textviewParsed.text = self.parsedDescription;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
