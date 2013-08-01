//
//  ICViewController.m
//  ICJSONDemo
//
//  Created by Toly Pochkin on 7/5/13.
//
//

#import "ICViewController.h"
#import "ICJSON.h"
#import "ICExampleModel.h"

@interface ICViewController ()

- (IBAction)example1;

@end

@implementation ICViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)example1
{
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
            //NSLog(@"%@", example1);
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
}

@end
