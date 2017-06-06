#import "AwsUserPoolPlugin.h"
#import "CognitoPoolIdentityProvider.h"

    @implementation MyManager

    @synthesize lastUsername;
    @synthesize lastPassword;

    + (id)sharedManager {
        static MyManager *sharedMyManager = nil;
        static dispatch_once_t onceToken;

        dispatch_once(&onceToken, ^{
            sharedMyManager = [[self alloc] init];
        });
        return sharedMyManager;
    }

    - (id)init {
      if (self = [super init]) {
            lastUsername = [[NSString alloc] initWithString:@""];
            lastPassword = [[NSString alloc] initWithString:@""];
      }
      return self;
    }

    @end

/**
    @implementation AWSCognitoIdentityUserPool (UserPoolsAdditions)

    - (AWSTask<NSString *> *)token {        
        MyManager *sharedManager = [MyManager sharedManager];

        return [[[self currentUser] getSession:sharedManager.lastUsername password:sharedManager.lastPassword validationData:nil]
                continueWithSuccessBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserSession *> * _Nonnull task) {
                    return [AWSTask taskWithResult:task.result.idToken.tokenString];
                }];
    }

    @end
**/

    @implementation AwsUserPoolPlugin
        //hard-coded region constant for the USWest2 region based on current project
        AWSRegionType const CognitoIdentityUserPoolRegion = AWSRegionUSWest2;

        //Config options for the AWS Cognito services to use my identityPool, userPool, and clientId
        NSString *CognitoIdentityUserPoolId;
        NSString *CognitoIdentityUserPoolAppClientId;
        NSString *CognitoIdentityUserPoolAppClientSecret;
        NSString *CognitoIdentityPoolId;
        //hard-coded for now, but need to include in config args from teh plugin calls
        NSString *USER_POOL_NAME = @"FuelStationApp";
        NSString *CognitoIdentityUserPoolRegionString = @"us-west-2";

        //AWS Objects to handle the service interactions
        AWSCognitoIdentityUserPool *pool;
        AWSCognitoIdentityUser *user;
        AWSCognitoIdentityUserPoolConfiguration *configuration;
        AWSServiceConfiguration *serviceConfiguration;
        AWSCognitoCredentialsProvider *credentialsProvider;

        AWSServiceConfiguration *serviceConfig;

    - (void)init:(CDVInvokedUrlCommand*)command{
        //add the aws loggin in verbose mode for the development process
        [AWSDDLog sharedInstance].logLevel = AWSDDLogLevelVerbose;
        [AWSDDLog addLogger:[AWSDDTTYLogger sharedInstance]];

        //grab the configuration options from the plugin command args at the first index
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];
        [self readOptions:options];

        
        // We can then set this as the default configuration for all AWS SDKs
        serviceConfiguration = [[AWSServiceConfiguration alloc] initWithRegion:CognitoIdentityUserPoolRegion credentialsProvider:nil];
        
        // Setup the pool
        configuration = [[AWSCognitoIdentityUserPoolConfiguration alloc]
                         initWithClientId:CognitoIdentityUserPoolAppClientId
                         clientSecret:CognitoIdentityUserPoolAppClientSecret
                         poolId:CognitoIdentityUserPoolId];
        //register the pool using the serviceConfig and poolConfig for the given poolName as key
        [AWSCognitoIdentityUserPool registerCognitoIdentityUserPoolWithConfiguration:serviceConfiguration
                                                               userPoolConfiguration:configuration
                                                                              forKey:USER_POOL_NAME];
        // Get the pool object now
        pool = [AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:USER_POOL_NAME];
        
        // The Credentials Provider holds our identity pool which allows access to AWS resources
        credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                               initWithRegionType:CognitoIdentityUserPoolRegion
                               identityPoolId:CognitoIdentityPoolId
                               identityProviderManager:pool];
        
        //init a new serviceConfig this time providing the credentialsProvider
        AWSServiceConfiguration *svcConfig = [[AWSServiceConfiguration alloc]
                                              initWithRegion:CognitoIdentityUserPoolRegion
                                              credentialsProvider:credentialsProvider];
        [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = svcConfig;
        

        //create a pluginResult to report back the init results and return to the command delegate
        CDVPluginResult *pluginResult = [CDVPluginResult
                                         resultWithStatus:CDVCommandStatus_OK
                                         messageAsString:@"Initialization successful"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

- (void)readOptions:(NSDictionary *)options {
    
    CognitoIdentityPoolId = [options objectForKey:@"arnIdentityPoolId"];
    CognitoIdentityUserPoolId = [options objectForKey:@"CognitoIdentityUserPoolId"];
    CognitoIdentityUserPoolAppClientId = [options objectForKey:@"CognitoIdentityUserPoolAppClientId"];
    //I do not use the Client Secret in my configurations
    CognitoIdentityUserPoolAppClientSecret = nil;
    
}

- (void)loginUser:(CDVInvokedUrlCommand*)command {
    // Get the user from the pool
    NSMutableDictionary* options = [command.arguments objectAtIndex:0];
    
    NSString *username = [options objectForKey:@"username"];
    NSString *password = [options objectForKey:@"password"];
    //    user = [pool currentUser];
    user = [pool getUser:username];
    
    // Make a call to get hold of the users session
    [[user getSession:username password:password validationData:nil]
     continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserSession *> * _Nullable task) {
         if (task.error) {
             NSLog(@"Could not get user session. Error: %@", task.error);
             
             // Create a pluginResult with the taskError and return to the calling pluginCommand
             CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo];
             [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
         } else {
             NSLog(@"Successfully retrieved user session data");
             
             // Get the session object from our result
             AWSCognitoIdentityUserSession *session = (AWSCognitoIdentityUserSession *) task.result;
             NSLog(@"ID TOKEN: %@", session.idToken.tokenString);
             
             // Build a token string
             NSString *key = [NSString
                              stringWithFormat:@"cognito-idp.%@.amazonaws.com/%@",
                              CognitoIdentityUserPoolRegionString,
                              CognitoIdentityUserPoolId];
             NSString *tokenStr = [session.idToken tokenString];
             NSDictionary *tokens = [[NSDictionary alloc] initWithObjectsAndKeys:tokenStr, key,  nil];
             
             CognitoPoolIdentityProvider *idProvider = [[CognitoPoolIdentityProvider alloc] init];
             [idProvider addTokens:tokens];
             
             AWSCognitoCredentialsProvider *creds = [[AWSCognitoCredentialsProvider alloc]
                                                     initWithRegionType:CognitoIdentityUserPoolRegion
                                                     identityPoolId:CognitoIdentityPoolId
                                                     identityProviderManager:idProvider];
             
             serviceConfig = [[AWSServiceConfiguration alloc]
                              initWithRegion:CognitoIdentityUserPoolRegion
                              credentialsProvider:creds];
             
             // This sets the default service configuration to allow the API gateway access to user authentication
             AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = serviceConfig;
             
             // Register the pool
             [AWSCognitoIdentityUserPool
              registerCognitoIdentityUserPoolWithConfiguration:serviceConfig
              userPoolConfiguration:configuration
              forKey:USER_POOL_NAME];
             
             // Create a pluginResult with the userSession and return to the JS layer w/ the plugins commandCallback
             CDVPluginResult *pluginResult = [CDVPluginResult
                                              resultWithStatus:CDVCommandStatus_OK
                                              messageAsDictionary:[task.result.idToken tokenString]];
             [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
         }
         return nil;
     }];
}

- (void)refreshSession:(CDVInvokedUrlCommand*)command {
    
    // Get the user from the pool
    user = [pool currentUser];
    // Get the session for the current user and refresh if needed...
    [[user getSession] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserSession *> * _Nonnull task) {
        if (task.error) {
            NSLog(@"There was an error refreshing session...");
            NSLog(@"\n\n**********\nPlease Login Again\n\n**********\n");
            // Create a pluginResult with the taskError and return to the calling pluginCommand
            CDVPluginResult *pluginResult = [CDVPluginResult
                                             resultWithStatus:CDVCommandStatus_ERROR
                                             messageAsDictionary:task.error.userInfo];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            
        } else {
            NSLog(@"\n\n**********\nSession was refreshed!!! Yay!!!\n\n**********\n");
            NSLog(@"\nEXPIRES: %@", task.result.expirationTime);
            NSLog(@"\n\nTOKEN: %@\n\n", task.result.idToken.tokenString);
			
            NSMutableDictionary *session = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [task.result.idToken tokenString], @"idToken",
                                            [task.result.accessToken tokenString], @"accessToken",
                                            [task.result.refreshToken tokenString], @"refreshToken", nil];
            
            // Create a pluginResult with the userSession and return to the JS layer w/ the plugins commandCallback
            CDVPluginResult *pluginResult = [CDVPluginResult
                                             resultWithStatus:CDVCommandStatus_OK
                                             messageAsDictionary:session];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            
        }
        return nil;
    }];
    
}

- (void)logout:(CDVInvokedUrlCommand*)command {
    
    // Get the user from the pool, signOut and clear the keychain of refresh tokens, etc.
    user = [pool currentUser];
    [user signOut];
    [credentialsProvider clearKeychain];
    
    CDVPluginResult *pluginResult = [CDVPluginResult
                                     resultWithStatus:CDVCommandStatus_OK
                                     messageAsString:@"SignOut successful"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

    - (void)offlineSignIn:(CDVInvokedUrlCommand*)command {
        /*
        // The SignIn will always return true, you need to manage the signin on the cordova side.
        // This function is needed if you already signin your user with internet and you want him to access to his data even in offline mode
        */
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *username = [options objectForKey:@"username"];
        NSString *password = [options objectForKey:@"password"];

        MyManager *sharedManager = [MyManager sharedManager];

        sharedManager.lastUsername = username;
        sharedManager.lastPassword = password;

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"SignIn offline successful"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

    - (void)signIn:(CDVInvokedUrlCommand*)command{
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *username = [options objectForKey:@"username"];
        NSString *password = [options objectForKey:@"password"];

        self.User = [self.Pool getUser:username];
    
        [[self.User getSession:username password:password validationData:nil] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserSession *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    NSLog(@"error : %@", task.error.userInfo);
                    MyManager *sharedManager = [MyManager sharedManager];

                    sharedManager.lastUsername = username;
                    sharedManager.lastPassword = password;

                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else{
                    self.actualAccessToken = task.result.accessToken;

                    MyManager *sharedManager = [MyManager sharedManager];

                    sharedManager.lastUsername = username;
                    sharedManager.lastPassword = password;

                    NSLog(@"!!!!!!!!!!! getIdentityId will start inside signIn");
                    [[self.credentialsProvider getIdentityId] continueWithBlock:^id _Nullable(AWSTask<NSString *> * _Nonnull task) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(task.error){
                                NSLog(@"!!!!!!!!!!! getIdentityId inside signIn, error : %@", task.error.userInfo);
                                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo[@"NSLocalizedDescription"]];
                                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                            } else {
                                NSLog(@"!!!!!!!!!!! getIdentityId inside signIn, task.result : %@", task.result);

                                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"SignIn successful"];
                                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                            }
                        });
                        return nil;
                    }];
                }
            });
            return nil;
        }];
    }

    - (void)signOut:(CDVInvokedUrlCommand *)command {
        self.User = [self.Pool currentUser];

        if (![self.CognitoIdentityUserPoolAppClientSecret isKindOfClass:[NSNull class]]) {
            NSLog(@"!!!!!!!!!!! getIdentityId will start inside signOut");
            [[self.credentialsProvider getIdentityId] continueWithBlock:^id _Nullable(AWSTask<NSString *> * _Nonnull task) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(task.error){
                        NSLog(@"!!!!!!!!!!! getIdentityId inside SignOut, error : %@", task.error.userInfo);
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo[@"NSLocalizedDescription"]];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    } else {
                        NSLog(@"!!!!!!!!!!! getIdentityId inside SignOut, task.result : %@", task.result);

                        [self.User signOut];

                        [self.credentialsProvider clearKeychain];

                        MyManager *sharedManager = [MyManager sharedManager];

                        sharedManager.lastUsername = @"";
                        sharedManager.lastPassword = @"";

                        self.dataset = nil;

                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"SignOut successful"];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }
                });
                return nil;
            }];
        }
        else {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No user connected"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];           
        }
    }

    - (void)signUp:(CDVInvokedUrlCommand*)command{
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *passwordString = [options objectForKey:@"password"];
        NSString *idString = [options objectForKey:@"id"];

        NSMutableArray* attributes = [options objectForKey:@"attributes"];
        NSMutableArray* attributesToSend = [NSMutableArray new];

        NSUInteger size = [attributes count];

        for (int i = 0; i < size; i++)
        {
            NSMutableDictionary* attributesIndex = [attributes objectAtIndex:i];

            AWSCognitoIdentityUserAttributeType * tmp = [AWSCognitoIdentityUserAttributeType new];

            tmp.name  = [attributesIndex objectForKey:@"name"];
            tmp.value = [attributesIndex objectForKey:@"value"];

            [attributesToSend addObject:tmp];
        }

        //sign up the user
        [[self.Pool signUp:idString password:passwordString userAttributes:attributesToSend validationData:nil] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserPoolSignUpResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    NSLog(@"error : %@", task.error);
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else{
                    AWSCognitoIdentityUserPoolSignUpResponse * response = task.result;
                    if(!response.userConfirmed){
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }
                    else {
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:false];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];                       
                    }
                }});
            return nil;
        }];
    }

    - (void)confirmSignUp:(CDVInvokedUrlCommand*)command{
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *tokenString = [options objectForKey:@"token"];
        NSString *idString = [options objectForKey:@"id"];

        if (idString) {
            self.User = [self.Pool getUser:idString];
        }

        [[self.User confirmSignUp:tokenString forceAliasCreation:YES] continueWithBlock: ^id _Nullable(AWSTask<AWSCognitoIdentityUserConfirmSignUpResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    NSLog(@"error : %@", task.error);
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else {
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"good token"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
            return nil;
        }];
    }

    - (void)forgotPassword:(CDVInvokedUrlCommand*)command{
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *idString = [options objectForKey:@"id"];        

        if (idString) {
            self.User = [self.Pool getUser:idString];
        }

        [[self.User forgotPassword] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserForgotPasswordResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    NSLog(@"error : %@", task.error);
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else {
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"good token"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
            return nil;
        }];
    }

    - (void)updatePassword:(CDVInvokedUrlCommand*)command {
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *confirmationCode = [options objectForKey:@"confirmationCode"];
        NSString *newPassword = [options objectForKey:@"newPassword"];

        [[self.User confirmForgotPassword:confirmationCode password:newPassword] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserConfirmForgotPasswordResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    NSLog(@"error : %@", task.error);
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else {
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"good token"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
            return nil;
        }];
    }

    -(void)getDetails:(CDVInvokedUrlCommand*)command {
        AWSCognitoIdentityProviderGetUserRequest* request = [AWSCognitoIdentityProviderGetUserRequest new];
        request.accessToken = self.actualAccessToken.tokenString;

        AWSCognitoIdentityProvider *defaultIdentityProvider = [AWSCognitoIdentityProvider defaultCognitoIdentityProvider];

        [[defaultIdentityProvider getUser:request] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityProviderGetUserResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    NSLog(@"error : %@", task.error);
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else {
                    AWSCognitoIdentityProviderGetUserResponse *response = task.result;

                    NSMutableDictionary *toReturn= [NSMutableDictionary dictionary];
                    NSUInteger size = [response.userAttributes count];

                    for (int i = 0; i < size; i++)
                    {
                        toReturn[response.userAttributes[i].name] = response.userAttributes[i].value;
                    }

                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:toReturn];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
            return nil;
        }];
    }

    - (void)resendConfirmationCode:(CDVInvokedUrlCommand*)command {
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *idString = [options objectForKey:@"id"];        

        if (idString) {
            self.User = [self.Pool getUser:idString];
        }

        [[self.User resendConfirmationCode] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserResendConfirmationCodeResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    NSLog(@"error : %@", task.error);
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo[@"message"]];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else {
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
            return nil;
        }];
    }

    /*
    ** Cognito Sync
    */

    - (void) createAWSCognitoDataset:(CDVInvokedUrlCommand *) command {
        // Add a dictionnary to allow to open multiple database

        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *idString = [options objectForKey:@"id"];
        NSString *cognitoId = self.credentialsProvider.identityId;

        NSLog(@"createAWSCognitoDataset idString : %@", idString);
        NSLog(@"createAWSCognitoDataset cognitoId : %@", cognitoId);

        AWSCognito *syncClient = [AWSCognito CognitoForKey:@"CognitoSync"];

            [[syncClient refreshDatasetMetadata] continueWithBlock:^id(AWSTask *task) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (task.error){
                        NSLog(@"createAWSCognitoDataset refreshDatasetMetadata error : %@", task.error);
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }
                    else {
                        NSLog(@"createAWSCognitoDataset refreshDatasetMetadata success : %@", task.result);
                        self.dataset = [syncClient openOrCreateDataset:idString];

                        self.dataset.conflictHandler = ^AWSCognitoResolvedConflict* (NSString *datasetName, AWSCognitoConflict *conflict) {
                            // override and always choose remote changes
                            return [conflict resolveWithRemoteRecord];
                        };
                        
                            [[self.dataset synchronize] continueWithBlock:^id(AWSTask *task) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (task.isCancelled) {
                                        NSLog(@"createAWSCognitoDataset isCancelled : %@", task.isCancelled);
                                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Canceled"];
                                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                    }
                                    else if(task.error){
                                        NSLog(@"createAWSCognitoDataset error : %@", task.error);
                                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo];
                                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                    } else {
                                        NSLog(@"createAWSCognitoDataset success : %@", task.result);
                                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"createAWSCognitoDataset Successful"];
                                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                    }
                                });
                                return nil;
                            }];
                    }
                });
                return nil;
            }];
    }


    - (void) getUserDataCognitoSync:(CDVInvokedUrlCommand *) command {
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];
        NSString *keyString = [options objectForKey:@"key"];

        NSString *value = [self.dataset stringForKey:keyString];

        NSLog(@"getUserDataCognitoSync, value : %@", value);
        NSLog(@"getUserDataCognitoSync, keyString: %@", keyString);

            [[self.dataset synchronize] continueWithBlock:^id(AWSTask *task) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (task.isCancelled) {
                        NSLog(@"getUserDataCognitoSync isCancelled : %@", task.isCancelled);
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Canceled"];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }
                    else if(task.error){
                        NSLog(@"getUserDataCognitoSync error : %@", task.error);
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    } else {
                        NSLog(@"getUserDataCognitoSync success : %@", value);
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }
                });
                return nil;
            }];
    }

    - (void) setUserDataCognitoSync:(CDVInvokedUrlCommand *) command {
        NSString *identityId = self.credentialsProvider.identityId;
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *keyString = [options objectForKey:@"key"];
        NSString *valueString = [options objectForKey:@"value"];

        [self.dataset setString:valueString forKey:keyString];
            [[self.dataset synchronize] continueWithBlock:^id(AWSTask *task) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (task.isCancelled) {
                        NSLog(@"isCancelled : %@", task.isCancelled);
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Canceled"];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }
                    else if(task.error){
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error"];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    } else {
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"setUserDataCognitoSync Successful"];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }
                });
                return nil;
            }];
    }

    @end
