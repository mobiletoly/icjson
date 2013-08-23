//
//  ICJSON.h
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

#import <Foundation/Foundation.h>


/// ------------------------------------------------------------------------------------------------------------------
/// JSON transform rule.
/// ------------------------------------------------------------------------------------------------------------------
@interface ICJSONRule : NSObject

@property (nonatomic, copy, readonly) NSString* path;
@property (nonatomic, readonly) SEL property;
@property (nonatomic, readonly) Class objectClass;

/// Create JSON transform rule for binding class to path
+ (ICJSONRule*)bindObjectClass:(Class)objectClass toPath:(NSString*)path;

/// Create JSON transform rule for binding class property to path
+ (ICJSONRule*)bindProperty:(SEL)property toPath:(NSString*)path;

/// Initialize JSON transform rule by binding path, class property and class together
- (id)initWithPath:(NSString*)path property:(SEL)property objectClass:(Class)objectClass;

@end


/// ------------------------------------------------------------------------------------------------------------------
/// JSON object helper.
/// ------------------------------------------------------------------------------------------------------------------
@interface ICJSON : NSObject

/// Deserialize JSON data and create Objective-C object.
+ (id)fromJSON:(NSData*)data rules:(NSArray* /*of<ICJSON>*/)transformRules error:(NSError**)error;

/// Not implemented yet.
+ (NSString*)toJSON:(id)object rules:(NSArray* /*of<ICJSON>*/)transformRules error:(NSError**)error;

@end
