ICJSON
======

Tiny but yet flexible iOS library to easily deserialize/serialize JSON with simple set of rules (cannot do serialization part yet, but it is coming very soon).

First of all, why would you want to use this library, if great NSJSONSerialization class is available from Foundation framework? The answer is simple - NSJSONSerialization does not deal with domain models and uses NSDictionary, NSArray etc to access data. ICJSON (pronounce it as "I see JSON") allows you to deserialize JSON by using Objective-C interfaces and properties.

So here is a very simple example. Let's assume that we have example1.json file in our XCode project (for a simple example to have local file is OK, we don't want to deal with networking code) with content such as:

```
{
    "client": "ICJSONDemo",
    "people": [
                {
                "id": 1,
                "firstName": "John",
                "lastName": "Smith",
                "age": 25,
                "address": {
                    "streetAddress": "21 2nd Street",
                    "city": "New York",
                    "state": "NY",
                    "postalCode": 10021
                },
                "phoneNumbers": [
                                 {
                                 "type": "home",
                                 "number": "212 555-1234"
                                 },
                                 {
                                 "type": "fax",
                                 "number": "646 555-4567"
                                 }
                                 ]
                },
                {
                "id": 2,
                "firstName": "Toly",
                "lastName": "Pochkin",
                "age": 35,
                "address": {
                    "streetAddress": "123 1st Street",
                    "city": "Seattle",
                    "state": "WA",
                    "postalCode": 98119
                },
                "phoneNumbers": [
                                 {
                                 "type": "home",
                                 "number": "213 111-2222"
                                 },
                                 {
                                 "type": "fax",
                                 "number": "213 222-1111"
                                 }
                                 ]
                }
                ]
}
```

Let's define a simple model

```
/// ICExample1Model.h

#import <Foundation/Foundation.h>

@class ICAddress;

/// Example model.
@interface ICExample : NSObject
@property (nonatomic) NSArray*/*<ICPerson*/ people;
@property (nonatomic) NSString* client;
@end


/// Person
@interface ICPerson : NSObject
@property (nonatomic) NSNumber* personId;
@property (nonatomic) NSString* firstName;
@property (nonatomic) NSString* lastName;
@property (nonatomic) NSNumber* age;
@property (nonatomic) ICAddress* address;
@property (nonatomic) NSArray*/*<ICPhoneNumber*/ phoneNumbers;
@end

/// Person's address
@interface ICAddress : NSObject
@property (nonatomic) NSString* streetAddress;
@property (nonatomic) NSString* city;
@property (nonatomic) NSString* state;
@property (nonatomic) NSNumber* postalCode;
@end

/// Person's phone number
@interface ICPhoneNumber : NSObject
@property (nonatomic) NSString* type;
@property (nonatomic) NSString* number;
@end

```

```
/// ICExample1Model.m


#import "ICExampleModel.h"

@implementation ICExample
@end

@implementation ICPerson
@end

@implementation ICAddress
@end

@implementation ICPhoneNumber
@end
```

ICExample model contains array of ICPerson objects as well as some "client" string property. ICPerson object contains personal information as well as ICAddress object and array of ICPhoneNumber objects, etc.

Let's read JSON file and convert it into hierarchy of objects:

```
    NSError* error;
    NSData* data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"example1" ofType:@"json"] options:0 error:&error];
    if (data == nil) {
        NSLog(@"ERROR READING FILE - %@", error);
    }
    else {
        NSArray* const rules =
                @[
                    // Bind entire JSON object to ICExample class
                  [ICJSONRule bindObjectClass:[ICExample class]        toPath:@"/"],

                    // Bind root "people" JSON key to an array of ICPerson type
                    // Now ICExample.people is an array of ICPerson items
                  [ICJSONRule bindObjectClass:[ICPerson class]         toPath:@"/people"],

                    // Map "id" JSON key to ICPerson.personId class
                  [ICJSONRule bindProperty:@selector(personId)         toPath:@"/people/id"],

                    // Bind "address" JSON key to ICAddress class
                  [ICJSONRule bindObjectClass:[ICAddress class]        toPath:@"/people/address"],

                    // Bind "phoneNumbers" JSON key to an array of ICPhoneNumber type
                    // Now ICExample.people.phoneNumbers is an array of ICPhoneNumber items
                  [ICJSONRule bindObjectClass:[ICPhoneNumber class]    toPath:@"/people/phoneNumbers"],
                ];
        error = nil;
        ICExample* example1 = [ICJSON fromJSON:data rules:rules error:&error];
        if (example1 == nil) {
            NSLog(@"ERROR PARSING JSON - %@", error);
        }
        else {
            NSLog(@"CLIENT : %@", example1.client);
            for (ICPerson* const person in example1.people) {
                NSLog(@"----- Person %@ ------------------------------", person.personId);
                NSLog(@"Name: %@ %@", person.firstName, person.lastName);
                NSLog(@"Age: %@", person.age);
                ICAddress* const address = person.address;
                if (address != nil) {
                    NSLog(@"Address: ");
                    NSLog(@"      %@", address.streetAddress);
                    NSLog(@"      %@, %@ %@", address.city, address.state, address.postalCode);
                }
                NSArray* const phoneNumbers = person.phoneNumbers;
                if (phoneNumbers != nil) {
                    for (ICPhoneNumber* phoneNumber in phoneNumbers) {
                        NSLog(@"Phone (%@): %@", phoneNumber.type, phoneNumber.number);
                    }
                }
                NSLog(@"\n");
            }
            
            error = nil;
            NSData* outputData = [ICJSON toJSON:example1 rules:rules error:&error];
        }
    }
```

In order to properly parse a JSON data - we have to set up set of rules. We can do it by creating ICJSONRule obejcts and pass an array of rules to [ICJSON fromJSON:] selector. Luckily ICJSON is smart enough to match simple JSON fields (strings, numbers) to Objective-C properties with the same name. If your Objective-C property name is different from JSON identifier, you should use [ICJSONRule bindProperty: toPath] selector. E.g. this is how we bind JSON's "id" field inside "people" array to personId property inside ICPerson interface:

```
[ICJSONRule bindProperty:@selector(personId) toPath:@"/people/id"]
```

Easy, right?

Also make sure to bind your model interfaces to JSON data structures. E.g. here is how we bind ICAddress interface to "address" data structure inside "people" structure.

```
[ICJSONRule bindObjectClass:[ICAddress class] toPath:@"/people/address"]
```

But what to do if you have an array of structures? ICJSON will help as well. All you have to do is to bind JSON data structure to Objective-C's property declared as NSArray. Once ICJSON detects that property is NSArray, it will instantiate array of binded interfaces.

```
[ICJSONRule bindObjectClass:[ICPhoneNumber class]    toPath:@"/people/phoneNumbers"]
```

Note that you can easily apply bindObjectClass and bindProperty to the same interface field (to bind an interface and specify that JSON field and Objective-C property has different names). E.g.

```
[ICJSONRule bindProperty:@selector(coolPhoneNumbers) toPath:@"/people/phoneNumbers"]
[ICJSONRule bindObjectClass:[ICPhoneNumber class] toPath:@"/people/phoneNumbers"]
```
