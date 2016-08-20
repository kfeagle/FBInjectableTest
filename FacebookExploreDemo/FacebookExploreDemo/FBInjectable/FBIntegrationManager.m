//
//  FBIntegrationManager.m
//  FacebookExploreDemo
//
//  Created by everettjf on 16/8/19.
//  Copyright © 2016年 everettjf. All rights reserved.
//

#import "FBIntegrationManager.h"
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

#define InjectableSectionName "FBInjectable"

static NSArray<Class>* readConfigurationClasses(){
    static NSMutableArray<Class> *classes;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Dl_info info;
        dladdr(readConfigurationClasses, &info);
        
#ifndef __LP64__
        const struct mach_header *mhp = _dyld_get_image_header(0);
        unsigned long size = 0;
        uint8_t *memory = getsectiondata(mhp, "__DATA", InjectableSectionName, & size);
#else /* defined(__LP64__) */
        const struct mach_header_64 *mhp = (struct mach_header_64*)info.dli_fbase;
        unsigned long size = 0;
        uint64_t *memory = (uint64_t*)getsectiondata(mhp, "__DATA", InjectableSectionName, & size);
#endif /* defined(__LP64__) */
        
        classes = [NSMutableArray new];
        
        for(int idx = 0; idx < size/sizeof(void*); ++idx){
            char *string = (char*)memory[idx];
            
            NSString *str = [NSString stringWithUTF8String:string];
            str = [str substringWithRange:NSMakeRange(2, str.length-3)];
            NSArray<NSString*> *components = [str componentsSeparatedByString:@" "];
            str = [components objectAtIndex:0];
            if(!str)return;
            
            NSString *className;
            NSRange range = [str rangeOfString:@"("];
            if(range.length > 0){
                className = [str substringToIndex:range.location];
            }else{
                className = str;
            }
            
            NSLog(@"class name = %@", className);
            Class cls = NSClassFromString(className);
            if(cls) [classes addObject:cls];
        }
    });
    
    return classes;
}

@implementation FBIntegrationManager

+ (Class)classForProtocol:(Protocol*)protocol{
    NSArray<Class> *classes = [self classesForProtocol_internal:protocol];
    return classes.firstObject;
}

+ (NSArray<Class>*)classesForProtocol:(Protocol*)protocol{
    return [self classesForProtocol_internal:protocol];
}

+ (NSArray<Class>*)classesForProtocol_internal:(id)protocol{
    NSArray<Class> *allClasses = readConfigurationClasses();
    NSLog(@"all classes = %@", allClasses);
    
    return allClasses;
}
@end
