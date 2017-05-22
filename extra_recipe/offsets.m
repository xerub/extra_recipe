//
//  offsets.m
//  extra_recipe
//
//  Created by xerub on 28/05/2017.
//  Copyright © 2017 xerub. All rights reserved.
//

#include <sys/utsname.h>
#include <UIKit/UIKit.h>

#include "offsets.h"

unsigned offsetof_p_pid = 0x10;               // proc_t::p_pid
unsigned offsetof_task = 0x18;                // proc_t::task
unsigned offsetof_p_ucred = 0x100;            // proc_t::p_ucred
unsigned offsetof_p_csflags = 0x2a8;          // proc_t::p_csflags
unsigned offsetof_itk_self = 0xD8;            // task_t::itk_self (convert_task_to_port)
unsigned offsetof_itk_sself = 0xE8;           // task_t::itk_sself (task_get_special_port)
unsigned offsetof_itk_bootstrap = 0x2b8;      // task_t::itk_bootstrap (task_get_special_port)
unsigned offsetof_ip_mscount = 0x9C;          // ipc_port_t::ip_mscount (ipc_port_make_send)
unsigned offsetof_ip_srights = 0xA0;          // ipc_port_t::ip_srights (ipc_port_make_send)
unsigned offsetof_special = 2 * sizeof(long); // host::special

const char *mp = NULL;

uint64_t AGXCommandQueue_vtable = 0;
uint64_t OSData_getMetaClass = 0;
uint64_t OSSerializer_serialize = 0;
uint64_t k_uuid_copy = 0;

uint64_t allproc = 0;
uint64_t realhost = 0;
uint64_t surfacevt = 0;
uint64_t call5 = 0;

int
init_offsets(void)
{
    struct utsname uts;

    if (uname(&uts)) {
        return ERR_INTERNAL;
    }

    NSString *version = [[UIDevice currentDevice] systemVersion];
    if ([version compare:@"10.0" options:NSNumericSearch] == NSOrderedAscending ||
        [version compare:@"10.2" options:NSNumericSearch] == NSOrderedDescending) {
        return ERR_UNSUPPORTED;
    }

    if (!strncmp(uts.machine, "iPhone9,", sizeof("iPhone9"))) {
        // iPhone 7 (plus)
        if ([version compare:@"10.1" options:NSNumericSearch] == NSOrderedAscending) {
            // 10.0[.x]
            mp = "@executable_path/mach-portal";
            AGXCommandQueue_vtable = 0xfffffff006f83b78;
            OSData_getMetaClass = 0xfffffff007479938;
            OSSerializer_serialize = 0xfffffff007490240;
            k_uuid_copy = 0xfffffff00749b5f8;
            allproc = 0xfffffff0075f0178;
            realhost = 0xfffffff00757c898;
            surfacevt = 0xfffffff006e521e0;
            call5 = 0xfffffff00633fe10;
        } else {
            // 10.1[.x]
            mp = "@executable_path/mach_portal";
            AGXCommandQueue_vtable = 0xfffffff006f83d38;
            OSData_getMetaClass = 0xfffffff00747ad9c;
            OSSerializer_serialize = 0xfffffff0074916b4;
            k_uuid_copy = 0xfffffff00749ca6c;
            allproc = 0xfffffff0075f0178;
            realhost = 0xfffffff00757c898;
            surfacevt = 0xfffffff006e521e0;
            call5 = 0xfffffff006337e10;
        }
    } else if (!strcmp(uts.machine, "iPhone8,1")) {
        // iPhone 6s
        if ([version compare:@"10.2" options:NSNumericSearch] == NSOrderedSame) {
            // 10.2
            AGXCommandQueue_vtable = 0xfffffff006f9b950;
            OSData_getMetaClass = 0xfffffff00743755c;
            OSSerializer_serialize = 0xfffffff00744df5c;
            k_uuid_copy = 0xfffffff007459378;
            allproc = 0xfffffff0075ac438;
            realhost = 0xfffffff007538a98;
            surfacevt = 0xfffffff006e84820;
            call5 = 0xfffffff0063cfe10;
            return ERR_UNSUPPORTED_YET; // TODO: remove after writing KPP bypass
        }
    }

    if (!AGXCommandQueue_vtable) {
        return ERR_UNSUPPORTED_YET;
    }

    return 0;
}
