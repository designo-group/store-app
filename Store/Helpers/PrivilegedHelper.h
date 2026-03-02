//
//  PrivilegedHelper.h
//  Manager
//
//  Created by Rodrigue de Guerre on 02/12/2025.
//

#ifndef PrivilegedHelper_h
#define PrivilegedHelper_h
#import <Security/Security.h>

OSStatus RunShellCommandWithPrivileges(AuthorizationRef authRef,
                                       const char *command,
                                       FILE **pipe);

#endif /* PrivilegedHelper_h */
