//
//  ICJSON.m
//
// The MIT License (MIT)
//
// Copyright (c) 2013 Toly Pochkin
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import "ICJSON.h"
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - ICJSONRule private declarations

@interface ICJSONRule ()

@property (nonatomic, copy, readwrite) NSString* path;
@property (nonatomic, readwrite) SEL property;
@property (nonatomic, readwrite) Class objectClass;

/// Convert JSON transform rules array into dictionary.
+ (NSDictionary*)rulesDictionaryFromRulesArray:(NSArray*)rules;

@end


#pragma mark - ICJSONRule implementation

@implementation ICJSONRule


/// ------------------------------------------------------------------------------------------------------------------
- (id)copyWithZone:(NSZone*)zone
{
    ICJSONRule* const rule = [[ICJSONRule allocWithZone:zone] initWithPath:self.path property:self.property objectClass:self.objectClass];
    return rule;
}

/// ------------------------------------------------------------------------------------------------------------------
- (NSString*)description
{
    return [NSString stringWithFormat:@"ICJSONRule <%08X> (path = '%@', objectClass = %@, property = %@)", (int)self, self.path, self.objectClass, NSStringFromSelector(self.property)];
}

/// ------------------------------------------------------------------------------------------------------------------
- (id)initWithPath:(NSString*)path property:(SEL)property objectClass:(Class)objectClass
{
    self = [super init];
    if (self) {
        _path = path;
        _property = property;
        _objectClass = objectClass;
    }
    return self;
}

/// ------------------------------------------------------------------------------------------------------------------
+ (ICJSONRule*)bindObjectClass:(Class)objectClass toPath:(NSString*)path
{
    return [[ICJSONRule alloc] initWithPath:path property:nil objectClass:objectClass];
}

/// ------------------------------------------------------------------------------------------------------------------
+ (ICJSONRule*)bindProperty:(SEL)property toPath:(NSString*)path
{
    return [[ICJSONRule alloc] initWithPath:path property:property objectClass:nil];
}

/// ------------------------------------------------------------------------------------------------------------------
+ (NSDictionary*)rulesDictionaryFromRulesArray:(NSArray*)rules
{
    NSMutableDictionary* const dict = [NSMutableDictionary dictionaryWithCapacity:rules.count];
    for (ICJSONRule* const rule in rules) {
        NSString* const path = rule.path;
        ICJSONRule* const existingRule = dict[path];
        if (existingRule == nil) {
            dict[path] = rule;
        }
        else {
            if (rule.property != nil) {
                existingRule.property = rule.property;
            }
            if (rule.objectClass != nil) {
                existingRule.objectClass = rule.objectClass;
            }
        }
    }
    return dict;
}

@end



#pragma mark - ICJSON implementation

@implementation ICJSON

/// ------------------------------------------------------------------------------------------------------------------
+ (id)fromJSON:(NSData*)data rules:(NSArray* /*of<ICJSONRule>*/)transformRules error:(NSError**)error
{
    NSDictionary* const rulesDict = [ICJSONRule rulesDictionaryFromRulesArray:transformRules];
    id rootObject;
    ICJSONRule* const rootRule = rulesDict[@"/"];
    Class rootObjectClass = nil;
    if (rootRule != nil && rootRule.objectClass != nil) {
        rootObjectClass = rootRule.objectClass;
        rootObject = [[rootObjectClass alloc] init];
    }
    else {
        rootObject = [NSMutableDictionary dictionary];
    }

    NSDictionary* const dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
    if (dict == nil) {
        return nil;
    }
    for (id const key in dict.allKeys) {
        id value = dict[key];
        NSString* const path = [ICJSON buildPathForKey:key fromRootPath:@"/"];
        id object = [ICJSON readJSONPropertiesFrom:value key:key path:@"/" rules:rulesDict];
        if (object != nil) {
            ICJSONRule* const rule = rulesDict[path];
            if (rootObjectClass == nil) {
                rootObject[key] = object;
            }
            else {
                NSString* const propertyName = [ICJSON propertyNameFromKey:key rule:rule];
                SEL const property = NSSelectorFromString(propertyName);
                if ([rootObject respondsToSelector:property]) {
                    [rootObject setValue:object forKey:propertyName];
                }
            }
        }
        // TODO handle NSDictionary
    }
    return rootObject;
}

/// ------------------------------------------------------------------------------------------------------------------
+ (NSString*)toJSON:(id)object rules:(NSArray* /*of<ICJSONRule>*/)transformRules error:(NSError**)error
{
    NSMutableString* const buffer = [NSMutableString stringWithCapacity:1024];
    [ICJSON appendJSONObject:object toBuffer:buffer];
    return buffer;
}

/// ------------------------------------------------------------------------------------------------------------------
+ (void)appendJSONObject:(id)object toBuffer:(NSMutableString*)buffer
{
    unsigned int outCount, i;
    objc_property_t* properties = class_copyPropertyList([object class], &outCount);
    for (i = 0; i < outCount; i++) {
    	objc_property_t property = properties[i];
    	const char* propName = property_getName(property);
    	if (propName) {
    		const char* const propType = getPropertyType(property);
    		NSString* const propertyName = [NSString stringWithCString:propName encoding:NSASCIIStringEncoding];
    		NSString* const propertyType = [NSString stringWithCString:propType encoding:NSASCIIStringEncoding];
            //SEL const propSel = NSSelectorFromString(propertyName);
            //NSLog(@">>> %@ -- %@", propertyName, propertyType);
    	}
    }
    free(properties);
}

/// ------------------------------------------------------------------------------------------------------------------
static const char* getPropertyType(objc_property_t property) {
    const char* attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char* state = buffer;
    char* attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T') {
            return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
        }
    }
    return "@";
}

/// ------------------------------------------------------------------------------------------------------------------
+ (NSString*)buildPathForKey:(NSString*)key
                fromRootPath:(NSString*)rootPath
{
    NSString* path = [NSString stringWithFormat:@"%@%@%@", rootPath,
                      [rootPath isEqualToString:@"/"] ? @"" : @"/",
                      key == nil ? @"" : key];
    return path;
}

/// ------------------------------------------------------------------------------------------------------------------
+ (NSString*)propertyNameFromKey:(NSString*)key
                            rule:(ICJSONRule*)rule
{
    if (rule != nil && rule.property != nil) {
        return NSStringFromSelector(rule.property);
    }
    return key;
}

/// ------------------------------------------------------------------------------------------------------------------
+ (id)readJSONPropertiesFrom:(id)srcObject key:(NSString*)rootKey path:(NSString*)rootPath rules:(NSDictionary*)rulesDict
{
    if ([srcObject isKindOfClass:[NSString class]] || [srcObject isKindOfClass:[NSNumber class]]) {
        return srcObject;
    }

    if ([srcObject isKindOfClass:[NSArray class]]) {
        NSArray* const values = (NSArray*)srcObject;
        NSMutableArray* const outputValues = [NSMutableArray array];
        for (id const value in values) {
            id const outputValue = [ICJSON readJSONPropertiesFrom:value key:rootKey path:rootPath rules:rulesDict];
            if (outputValue != nil) {
                [outputValues addObject:outputValue];
            }
        }
        return outputValues;
    }
    
    NSString* const path = [ICJSON buildPathForKey:rootKey fromRootPath:rootPath];
    ICJSONRule* const rootRule = rulesDict[path];
    if (rootRule != nil && rootRule.objectClass != nil) {
        id rootObject = [[rootRule.objectClass alloc] init];
        NSDictionary* const dict = (NSDictionary*)srcObject;
        for (NSString* const key in dict.allKeys) {
            id const value = dict[key];
            id const object = [ICJSON readJSONPropertiesFrom:value key:key path:path rules:rulesDict];
            if (object != nil) {
                NSString* const objectPath = [ICJSON buildPathForKey:key fromRootPath:path];
                ICJSONRule* const objectRule = rulesDict[objectPath];
                NSString* const propertyName = [ICJSON propertyNameFromKey:key rule:objectRule];
                SEL const property = NSSelectorFromString(propertyName);
                if ([rootObject respondsToSelector:property]) {
                    [rootObject setValue:object forKey:propertyName];
                }
            }
        }
        return rootObject;
    }

    NSMutableDictionary* const rootObject = [NSMutableDictionary dictionary];
    NSDictionary* const dict = (NSDictionary*)srcObject;
    for (NSString* const key in dict.allKeys) {
        id value = dict[key];
        id object = [ICJSON readJSONPropertiesFrom:value key:key path:path rules:rulesDict];
        if (object != nil) {
            rootObject[key] = object;
        }
    }
    return rootObject;
}


@end
