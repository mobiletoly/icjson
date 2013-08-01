//
//  ICExampleModel.h
//  ICJSONDemo
//
//  Created by Toly Pochkin on 7/5/13.
//
//

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

