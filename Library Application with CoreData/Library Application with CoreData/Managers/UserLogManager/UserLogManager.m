//
//  UserLogManager.m
//  Library Application with CoreData
//
//  Created by Ömer Emre Aslan on 22/07/15.
//  Copyright © 2015 omer. All rights reserved.
//

#import "UserLogManager.h"

@interface UserLogManager()
@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;
@end

@implementation UserLogManager

#pragma mark - Shared Instance methods
+ (instancetype)sharedInstance
{
    static UserLogManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
        
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedInstance];
}

- (id)copy
{
    return [self.class sharedInstance];
}

#pragma mark - Core Data method
- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
    
}

#pragma mark - Necessary Methods

- (void)createLog:(NSString *)transaction :(User *)user
{
    UserLog *userLog = [NSEntityDescription insertNewObjectForEntityForName:@"UserLog" inManagedObjectContext:self.managedObjectContext];
    [userLog setValue:user forKey:@"user"];
    if ([transaction isEqualToString:@"createUser"]) {
        [userLog setValue:@"User was created" forKey:@"transaction"];
        [userLog setValue:[NSDate date] forKey:@"transactionDate"];
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
    }
}


- (NSMutableArray *)getLogsFromUserName:(NSString *)username
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"UserLog"];
    request.predicate = [NSPredicate predicateWithFormat:@"user.username = %@", username];
    NSError *searchError;
    NSArray *logs;
    logs = [self.managedObjectContext executeFetchRequest:request error:&searchError];
    return [logs mutableCopy];
}

@end
