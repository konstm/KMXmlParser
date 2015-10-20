# KMXmlParser
XML parser that in general returns result as a composition of collections: arrays and dictionaries. The class KMXmlParser uses libxml2 library and based on the excellent work of Matt Gallagher: [Using libxml2 for XML parsing and XPath queries in Cocoa](http://www.cocoawithlove.com/2008/10/using-libxml2-for-parsing-and-xpath.html). Supports XPath expressions and can handle SOAP internal links specified by "id" and "href" attributes.

##Usage
Put this path "${SDKROOT}/usr/include/libxml2" under "Header Search Path" in section "Search Paths" of XCode's Build setting, include libxml2.dylib in "Link Binary With Libraries" list and add class files into your project. The common way to use an XML parser looks like this:
```
KMXmlParser *xmlParser = [[KMXmlParser alloc] init];
xmlParser.discloseArrayTags = @[@"item", @"book"];
result = [xmlParser parseXml:xmlData nodeName:@"books"];
```

##How the result may look like
The XML element with subelements is usually represented by a dictionary. For example, this element 
```
<book>
	<title>Recipes</title>
	<author>R. Worren</author>
	<year>2012</year>
	<publisher>First Publisher</publisher>
</book>
```
is converted to the dictionary:
```
book =     
{
	author = "R. Worren";
	publisher = "First Publisher";
	title = Recipes;
	year = 2012;
}
```
	
If such element in addition to subelements has its own content, like this:
```
<book>
	<title>Recipes</title>
	<author>R. Worren</author>
	<year>2012</year>
	<publisher>First Publisher</publisher>
	This is a sample of the book 
</book>
```
then this content appears in the entry with key "nodeContent":
```
book =     
{
	author = "R. Worren";
	nodeContent = "This is a sample of the book";
	publisher = "First Publisher";
	title = Recipes;
	year = 2012;
};
```


The sequence of identical subelements is converted to the array:

XML data
```
<book>
	<title>Recipes</title>
	<author>R. Worren</author>
	<year>2012</year>
	<publisher>First Publisher</publisher>
</book>
<book>
	<title>Cats</title>
	<author>S. Graham</author>
	<year>2013</year>
	<publisher>Second Publisher</publisher>
</book>
<book>
	<title>Advices</title>
	<author>E. Brown</author>
	<year>2014</year>
	<publisher>Third Publisher</publisher>
</book>
```

result
```
book =     
(
	{
		author = "R. Worren";
		publisher = "First Publisher";
		title = Recipes;
		year = 2012;
	},
	{
		author = "S. Graham";
		publisher = "Second Publisher";
		title = Cats;
		year = 2013;
	},
	{
		author = "E. Brown";
		publisher = "Third Publisher";
		title = Advices;
		year = 2014;
	}
)
```


Attributes are also included as dictionary entries in the result.

##Properties

#####`@property (strong, nonatomic) NSArray *discloseArrayTags;`
Allow to exclude from the result undesirable one-entry dictionary where value is an array and key of this entry is pointed in discloseArrayTags.
For example, the  xml element
```
<books>
	<item>
		<title>Recipes</title>
		<author>R. Worren</author>
		<year>2012</year>
		<publisher>First Publisher</publisher>
	</item>
	<item>
		<title>Cats</title>
		<author>S. Graham</author>
		<year>2013</year>
		<publisher>Second Publisher</publisher>
	</item>
	<item>
		<title>Advices</title>
		<author>E. Brown</author>
		<year>2014</year>
		<publisher>Third Publisher</publisher>
	</item>
</books>
```
is represented in the result as a dictionary with one key "item":
```
books =     
{
	item =    
	(
		{
			author = "R. Worren";
			publisher = "First Publisher";
			title = Recipes;
			year = 2012;
		},
		{
			author = "S. Graham";
			publisher = "Second Publisher";
			title = Cats;
			year = 2013;
		},
		{
			author = "E. Brown";
			publisher = "Third Publisher";
			title = Advices;
			year = 2014;
		}
	);
};
```
If we assign the property discloseArrayTags = @[@"item"] then the result looks like this:
```
books =     
(
	{
		author = "R. Worren";
		publisher = "First Publisher";
		title = Recipes;
		year = 2012;
	},
	{
		author = "S. Graham";
		publisher = "Second Publisher";
		title = Cats;
		year = 2013;
	},
	{
		author = "E. Brown";
		publisher = "Third Publisher";
		title = Advices;
		year = 2014;
	}
);
```
@[@"item"] is the default value 

 
#####`@property (strong, nonatomic) NSArray *alwaysArrayTags;`
XML elements with names equal to one of values of this property have to be always converted to the array even if they consist of one element.
For example, the XML element
```
<books>
	<item>
		<title>Recipes</title>
		<author>R. Worren</author>
		<year>2012</year>
		<publisher>First Publisher</publisher>
	</item>
</books>
```
is transformed usually to the dictionary
```
books =     
{
	item =         
	{
		author = "R. Worren";
		publisher = "First Publisher";
		title = Recipes;
		year = 2012;
	};
};
```

In case alwaysArrayTags is @[@"item"] we receive:
```
 books =     
 {
	item =         
	(
		{
			author = "R. Worren";
			publisher = "First Publisher";
			title = Recipes;
			year = 2012;
		}
	);
};
```

and if discloseArrayTags == @[@"item"] the result becomes this:
```
books =     
(
	{
		author = "R. Worren";
		publisher = "First Publisher";
		title = Recipes;
		year = 2012;
	}
);
```
@[@"item"] is the default value

 
#####`@property (assign, nonatomic) BOOL parseAllAttributes;`
Include or not attributes of all elements in the parsing. If included the attributes are presented in result as key-value pairs.
If element has attribute and subelement with the same name then one of them gets different ending. For example, the element
```
<book category="Cooking">
	<title>Recipes</title>
	<author>R. Worren</author>
	<category>Diet Cooking</category>
</book>
```
is converted to 
```
book =     
{
	author = "R. Worren";
	category = "Diet Cooking";
	category001 = Cooking;
	title = Recipes;
};
```
The default value is YES.

 
#####`@property (strong, nonatomic) NSArray *parseAttributesOfTags;`
Parse the attributes only of elements whose names are set in this array

 
#####`@property (assign, nonatomic) BOOL attributesAsSeparated;`
If YES, represent attributes in the separate dictionary under key "attributes":
```
<book category="Cooking" instock="YES">
	<title>Recipes</title>
	<author>R. Worren</author>
	<year>2012</year>
</book>
```
result:
```
book =     
{
	attributes =         {
		category = Cooking;
		instock = YES;
	};
	author = "R. Worren";
	title = Recipes;
	year = 2012;
};
```
The default value is NO

 
#####`@property (assign, nonatomic) BOOL doCollections;`
If YES, stop the parsing after first pass and return result as it was made by Matt Gallagher. 
The default value is NO.

 
#####`@property (nonatomic, assign) BOOL enableEmptyTags;`
if YES, the empty XML elements will be presented as [NSNull null] objects, otherwise they won't appear in the result.
The default value is NO;

##Methods
#####`-(void) setMappingKeyName:(NSString*)keyName valueName:(NSString*)valueName;`
Set key-value names to catch the data structure that can be often found in SOAP responses:
```
<item>
	<key xsi:type="xsd:string">roomJID</key>
	<value xsi:type="xsd:string">Hello13993697324679@question.181.222.222.222</value>
</item>
<item>
	<key xsi:type="xsd:string">ownerId</key>
	<value xsi:type="xsd:string">11412</value>
</item>
```
and parse it to the common dictionary:
```
{
	ownerId = 11412;
	roomJID = "Hello13993697324679@question.188.222.222.222";
}
```
The default values are of course @"key", @"value";

#####`-(void) clearMappingKeyValueNames;`
Removes key-value names.

 
#####`-(void) registerNameSpace:(NSString*)nsPrefix uri:(NSString*)uri;`
#####`-(void) unRegisterNameSpace:(NSString*)nsPrefix;`
#####`-(void) unRegisterAllNameSpaces;`
Work with namespace. Method registerNameSpace can be called many times before starting the parsing

 
#####`-(void) excludeTagFromParsing:(NSString*)tag doDump:(BOOL)doDump;`
Do not parse elements with name equal to tag. If doDump is set to YES, then element will be included in the result with its original data. Method excludeFromParsingTag can be called many times before starting the parsing.

#####`-(void) includeTagToParsing:(NSString*)tag;`
#####`-(void) includeAllTagsToParsing;`

 
#####`-(id) parseXml:(NSData*)xmlData xpathExpression:(NSString *)xpathExpression;`
Get the result of parsing on the output of execution of XPath expression. Returns nil when XPath query gives null or in case of a wrong xml data.

 
#####`-(id) parseXml:(NSData*)xmlData nodeName:(NSString*)nodeName;`
Parse only elements with name "nodeName". Internally [parseXml:xmlData nodeName:nodeName] is performed as [parseXml:xmlData xpathExpression:@"//nodeName"];

 
#####`-(id) parseXml:(NSData*)xmlData;`
Parse the whole xml document starting from the root element.

 
#####`+(id) parseXml:(NSData*)xmlData XPathExpression:(NSString*)xpathExpression;`
#####`+(id) parseXml:(NSData*)xmlData nodeName:(NSString*)nodeName;`
#####`+(id) parseXml:(NSData*)xmlData;`
Class methods with default settings of parsing control.


##Demo
Demo app demonstrates some examples of parser usage. To add another xml data for check parsing you should put xml file in the directory "XmlExamples" and then handle it in the method "parseXmlFile:"  in XmlFilesController.m


##References
[Cocoawithlove: Using libxml2 for XML parsing and XPath queries in Cocoa](http://www.cocoawithlove.com/2008/10/using-libxml2-for-parsing-and-xpath.html)

[libxml documentation](http://xmlsoft.org/)

[SOAP ref Attribute Information Item] (http://www.w3.org/TR/soap12-part2/#uniqueids)

## Licence

MIT 




