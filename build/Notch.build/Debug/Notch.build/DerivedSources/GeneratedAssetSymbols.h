#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "airdrop" asset catalog image resource.
static NSString * const ACImageNameAirdrop AC_SWIFT_PRIVATE = @"airdrop";

/// The "bluetooth" asset catalog image resource.
static NSString * const ACImageNameBluetooth AC_SWIFT_PRIVATE = @"bluetooth";

/// The "screenshot" asset catalog image resource.
static NSString * const ACImageNameScreenshot AC_SWIFT_PRIVATE = @"screenshot";

/// The "terminal" asset catalog image resource.
static NSString * const ACImageNameTerminal AC_SWIFT_PRIVATE = @"terminal";

/// The "wifi" asset catalog image resource.
static NSString * const ACImageNameWifi AC_SWIFT_PRIVATE = @"wifi";

#undef AC_SWIFT_PRIVATE
