#import <IOKit/IOKitLib.h>
#import <sys/sysctl.h>
#import "VarSystemInfo.h"
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

@interface VarSystemInfo ()
@property (readwrite, strong, nonatomic) NSString *sysName;
@property (readwrite, strong, nonatomic) NSString *sysUserName;
@property (readwrite, strong, nonatomic) NSString *sysFullUserName;
@property (readwrite, strong, nonatomic) NSString *sysOSName;
@property (readwrite, strong, nonatomic) NSString *sysOSVersion;
@property (readwrite, strong, nonatomic) NSString *sysPhysicalMemory;
@property (readwrite, strong, nonatomic) NSString *sysSerialNumber;
@property (readwrite, strong, nonatomic) NSString *sysUUID;
@property (readwrite, strong, nonatomic) NSString *sysModelID;
@property (readwrite, strong, nonatomic) NSString *sysModelName;
@property (readwrite, strong, nonatomic) NSString *sysProcessorName;
@property (readwrite, strong, nonatomic) NSString *sysProcessorSpeed;
@property (readwrite, strong, nonatomic) NSNumber *sysProcessorCount;
@property (readonly,  strong, nonatomic) NSString *getOSVersionInfo;

- (NSString *) _strIORegistryEntry:(NSString *)registryKey;
- (NSString *) _strControlEntry:(NSString *)ctlKey;
- (NSNumber *) _numControlEntry:(NSString *)ctlKey;
- (NSString *) _modelNameFromID:(NSString *)modelID;
- (NSString *) _parseBrandName:(NSString *)brandName;
@end

static NSString* const kVarSysInfoVersionFormat  = @"%@.%@.%@ (%@)";
static NSString* const kVarSysInfoPlatformExpert = @"IOPlatformExpertDevice";

static NSString* const kVarSysInfoKeyOSVersion = @"kern.osrelease";
static NSString* const kVarSysInfoKeyOSBuild   = @"kern.osversion";
static NSString* const kVarSysInfoKeyModel     = @"hw.model";
static NSString* const kVarSysInfoKeyCPUCount  = @"hw.physicalcpu";
static NSString* const kVarSysInfoKeyCPUFreq   = @"hw.cpufrequency";
static NSString* const kVarSysInfoKeyCPUBrand  = @"machdep.cpu.brand_string";

static NSString* const kVarSysInfoMachineNames       = @"MachineNames";
static NSString* const kVarSysInfoMachineiMac        = @"iMac";
static NSString* const kVarSysInfoMachineMacmini     = @"Mac mini";
static NSString* const kVarSysInfoMachineMacBookAir  = @"MacBook Air";
static NSString* const kVarSysInfoMachineMacBookPro  = @"MacBook Pro";
static NSString* const kVarSysInfoMachineMacPro      = @"Mac Pro";

#pragma mark - Implementation:
#pragma mark -

@implementation VarSystemInfo

@synthesize sysName, sysUserName, sysFullUserName;
@synthesize sysOSName, sysOSVersion;
@synthesize sysPhysicalMemory;
@synthesize sysSerialNumber, sysUUID;
@synthesize sysModelID, sysModelName;
@synthesize sysProcessorName, sysProcessorSpeed, sysProcessorCount;

#pragma mark - Helper Methods:

- (NSString *) _strIORegistryEntry:(NSString *)registryKey {
    
    NSString *retString;
    
    io_service_t service =
    IOServiceGetMatchingService( kIOMasterPortDefault,
                                IOServiceMatching([kVarSysInfoPlatformExpert UTF8String]) );
    if ( service ) {
        
        CFTypeRef cfRefString =
        IORegistryEntryCreateCFProperty( service,
                                        (__bridge CFStringRef)registryKey,
                                        kCFAllocatorDefault, kNilOptions );
        if ( cfRefString ) {
            
            retString = [NSString stringWithString:(__bridge NSString *)cfRefString];
            CFRelease(cfRefString);
            
        } IOObjectRelease( service );
        
    } return retString;
}

- (NSString *) _strControlEntry:(NSString *)ctlKey {
    
    size_t size = 0;
    if ( sysctlbyname([ctlKey UTF8String], NULL, &size, NULL, 0) == -1 ) return nil;
    
    char *machine = calloc( 1, size );
    
    sysctlbyname([ctlKey UTF8String], machine, &size, NULL, 0);
    NSString *ctlValue = [NSString stringWithCString:machine encoding:[NSString defaultCStringEncoding]];
    
    free(machine); return ctlValue;
}

- (NSNumber *) _numControlEntry:(NSString *)ctlKey {
    
    size_t size = sizeof( uint64_t ); uint64_t ctlValue = 0;
    if ( sysctlbyname([ctlKey UTF8String], &ctlValue, &size, NULL, 0) == -1 ) return nil;
    return [NSNumber numberWithUnsignedLongLong:ctlValue];
}

- (NSString *) _modelNameFromID:(NSString *)modelID {
    size_t size;
    sysctlbyname("hw.model", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.model", model, &size, NULL, 0);
    NSLog(@"%s", model);
    
    return [NSString stringWithUTF8String:model];
}

- (NSString *) _parseBrandName:(NSString *)brandName {
    
    if ( !brandName ) return nil;
    
    NSMutableArray *newWords = [NSMutableArray array];
    NSString *strCopyRight = @"r", *strTradeMark = @"tm", *strCPU = @"CPU";
    
    NSArray *words = [brandName componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
    
    for ( NSString *word in words ) {
        
        if ( [word isEqualToString:strCPU] )       break;
        if ( [word isEqualToString:@""] )          continue;
        if ( [word.lowercaseString isEqualToString:strCopyRight] ) continue;
        if ( [word.lowercaseString isEqualToString:strTradeMark] ) continue;
        
        if ( [word length] > 0 ) {
            
            NSString *firstChar = [word substringToIndex:1];
            if ( NSNotFound != [firstChar rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location ) continue;
            
            [newWords addObject:word];
            
        } } return [newWords componentsJoinedByString:@" "];
}

- (NSString *) getOSVersionInfo {
    
    NSString *darwinVer = [self _strControlEntry:kVarSysInfoKeyOSVersion];
    NSString *buildNo = [self _strControlEntry:kVarSysInfoKeyOSBuild];
    if ( !darwinVer || !buildNo ) return nil;
    
    NSString *majorVer = @"10", *minorVer = @"x", *bugFix = @"x";
    NSArray *darwinChunks = [darwinVer componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    
    if ( [darwinChunks count] > 0 ) {
        
        NSInteger firstChunk = [(NSString *)[darwinChunks objectAtIndex:0] integerValue];
        minorVer = [NSString stringWithFormat:@"%ld", (firstChunk - 4)];
        bugFix = [darwinChunks objectAtIndex:1];
        return [NSString stringWithFormat:kVarSysInfoVersionFormat, majorVer, minorVer, bugFix, buildNo];
        
    } return nil;
}

#pragma mark - Initalization:

- (void) setupSystemInformation {
    
    NSProcessInfo *pi = [NSProcessInfo processInfo];
    
    self.sysName = [[NSHost currentHost] localizedName];
    self.sysUserName = NSUserName();
    self.sysFullUserName = NSFullUserName();
    self.sysOSName = pi.operatingSystemVersionString;
    self.sysOSVersion = self.getOSVersionInfo;
    self.sysPhysicalMemory = [[NSNumber numberWithUnsignedLongLong:pi.physicalMemory] stringValue];
    self.sysSerialNumber = [self _strIORegistryEntry:(__bridge NSString *)CFSTR(kIOPlatformSerialNumberKey)];
    self.sysUUID = [self _strIORegistryEntry:(__bridge NSString *)CFSTR(kIOPlatformUUIDKey)];
    self.sysModelID = [self _strControlEntry:kVarSysInfoKeyModel];
    self.sysModelName = [self _modelNameFromID:self.sysModelID];
    self.sysProcessorName = [self _parseBrandName:[self _strControlEntry:kVarSysInfoKeyCPUBrand]];
    self.sysProcessorSpeed = [self _numControlEntry:kVarSysInfoKeyCPUFreq];
    self.sysProcessorCount = [self _numControlEntry:kVarSysInfoKeyCPUCount];
}

- (id) init {
    
    if ( (self = [super init]) ) {
        
        [self setupSystemInformation];
        
    } return self;
}

- (NSDictionary*)data{
    return @{@"sysname":self.sysName,
             @"sysUserName":self.sysUserName,
             @"sysFullUserName":self.sysFullUserName,
             @"sysOSName":self.sysOSName,
             @"sysOSVersion":self.sysOSVersion,
             @"sysPhysicalMemory":self.sysPhysicalMemory,
             @"sysUUID":self.sysUUID,
             @"sysModelID":self.sysModelID,
             @"sysModelName":self.sysModelName,
             @"sysProcessorName":self.sysProcessorName,
             @"sysProcessorSpeed":self.sysProcessorSpeed,
             @"sysProcessorCount":self.sysProcessorCount};
}

@end