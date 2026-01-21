#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"orgLifelineMed.AnalgesiaTool";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "Calculator_PixelArt" asset catalog image resource.
static NSString * const ACImageNameCalculatorPixelArt AC_SWIFT_PRIVATE = @"Calculator_PixelArt";

/// The "Morphine_Molecule" asset catalog image resource.
static NSString * const ACImageNameMorphineMolecule AC_SWIFT_PRIVATE = @"Morphine_Molecule";

/// The "alcohol_units" asset catalog image resource.
static NSString * const ACImageNameAlcoholUnits AC_SWIFT_PRIVATE = @"alcohol_units";

/// The "street_drug_units" asset catalog image resource.
static NSString * const ACImageNameStreetDrugUnits AC_SWIFT_PRIVATE = @"street_drug_units";

#undef AC_SWIFT_PRIVATE
