//
//  JSONObjectHelper.h
//
//  Created by Toly Pochkin on 3/21/13.
//
//  Helps in deserializing JSON into Objective-C classes.
//

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
+ (id)fromJSON:(NSData*)data rules:(NSArray*/*<ICJSON>*/)transformRules error:(NSError**)error;

/// Not implemented yet.
+ (NSString*)toJSON:(id)object rules:(NSArray*/*<ICJSON>*/)transformRules error:(NSError**)error;

@end
