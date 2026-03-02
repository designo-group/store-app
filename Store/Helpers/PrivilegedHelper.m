//
//  PrivilegedHelper.m
//  Manager
//
//  Created by Rodrigue de Guerre on 02/12/2025.
//

#import <Foundation/Foundation.h>
#import "PrivilegedHelper.h"

OSStatus RunShellCommandWithPrivileges(AuthorizationRef authRef,
                                       const char *command,
                                       FILE **pipe)
{
    char *args[] = { "-c", (char *)command, NULL };

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    OSStatus status = AuthorizationExecuteWithPrivileges(
        authRef,
        "/bin/zsh",
        kAuthorizationFlagDefaults,
        args,
        pipe
    );
#pragma clang diagnostic pop

    return status;
}
