//
//  unjail.m
//  extra_recipe
//
//  Created by xerub on 16/05/2017.
//  Copyright © 2017 xerub. All rights reserved.
//

#include "unjail.h"
#include "offsets.h"
#include "libjb.h"

kern_return_t mach_vm_allocate(vm_map_t target, mach_vm_address_t *address, mach_vm_size_t size, int flags);

#include "patchfinder64.h"

uint64_t hibit_guess = 0;

// @qwertyoruiop's physalloc

static uint64_t
kalloc(vm_size_t size)
{
    mach_vm_address_t address = 0;

    if (hibit_guess == 0xFFFFFFE000000000) {
        // md = IOBufferMemoryDescriptor::withOptions(kIOMemoryTypeVirtual, size, 1)
        uint64_t md = kx5(constget(7) + kaslr_shift, 0x10, size, 1, 0, 0) | hibit_guess;
        // md->getBytesNoCopy()
        return kx5(constget(8) + kaslr_shift, md, 0, 0, 0, 0) | hibit_guess;
    }

    mach_vm_allocate(tfp0, (mach_vm_address_t *)&address, size, VM_FLAGS_ANYWHERE);
    return address;
}

int
unjail2(uint64_t allproc, uint64_t credpatch)
{
    int rv;

    if (mp) {
        hibit_guess = 0xFFFFFFE000000000;
    }

    rv = init_kernel(kernel_base, NULL);
    assert(rv == 0);

    uint64_t trust_chain = find_trustcache();
    uint64_t amficache = find_amficache();

    term_kernel();

    char path[4096];
    uint32_t size = sizeof(path);
    _NSGetExecutablePath(path, &size);
    char *pt = realpath(path, NULL);

    NSString *execpath = [[NSString stringWithUTF8String:pt] stringByDeletingLastPathComponent];

    /* 1. fix containermanagerd */

    pid_t pd;
    uint64_t c_cred = 0;
    uint64_t proc = kread_uint64(allproc);
    while (proc) {
        char comm[20];
        kread(proc + offsetof_p_comm, comm, 16);
        comm[17] = 0;
        if (strstr(comm, "containermanager")) {
            break;
        }
        proc = kread_uint64(proc);
    }
    if (proc) {
        printf("containermanagerd proc: 0x%llx\n", proc);
        c_cred = kread_uint64(proc + offsetof_p_ucred);
        kwrite_uint64(proc + offsetof_p_ucred, credpatch);
    }

#ifdef WANT_CYDIA
    NSString *bootstrap = [execpath stringByAppendingPathComponent:@"bootstrap.tar"];

    /* 2. remount "/" */

    {
        struct utsname uts;
        uname(&uts);

        vm_offset_t off = 0xd8;
        if (strstr(uts.version, "16.0.0")) {
            off = 0xd0;
        }

        uint64_t _rootvnode = mp ? (constget(5) + kaslr_shift) : (find_gPhysBase() + 0x38);
        uint64_t rootfs_vnode = kread_uint64(_rootvnode);
        uint64_t v_mount = kread_uint64(rootfs_vnode + off);
        uint32_t v_flag = kread_uint32(v_mount + 0x71);

        kwrite_uint32(v_mount + 0x71, v_flag & ~(1 << 6));

        char *nmz = strdup("/dev/disk0s1s1");
        rv = mount("hfs", "/", MNT_UPDATE, (void *)&nmz);
        NSLog(@"remounting: %d", rv);

        v_mount = kread_uint64(rootfs_vnode + off);
        kwrite_uint32(v_mount + 0x71, v_flag);
    }

    /* 3. untar bootstrap */

    int fd = open("/.installed_yaluX", O_RDONLY);
    if (fd == -1) {
        FILE *a = fopen([bootstrap UTF8String], "rb");
        if (a) {
            chdir("/");
            untar(a, "bootstrap");
            fclose(a);
            fd = creat("/.installed_yaluX", 0644);
            close(creat("/.cydia_no_stash", 0644));
        }
    }
    close(fd);

#else	/* !WANT_CYDIA */
    NSString *bootstrap = [execpath stringByAppendingPathComponent:@"bootstrap.dmg"];
    const char *jl;

    /* 2. extract and run hdik */

    jl = "/tmp/hdik";
    long dmg = HFSOpen("/usr/standalone/update/ramdisk/arm64SURamDisk.dmg", 27);
    if (dmg >= 0) {
        long len = HFSReadFile(dmg, "/usr/sbin/hdik", gLoadAddr, 0, 0);
        printf("hdik = %ld\n", len);
        if (len > 0) {
            int fd = creat(jl, 0755);
            if (fd >= 0) {
                write(fd, gLoadAddr, len);
                close(fd);
            }
        }
        HFSClose(dmg);
    }
    posix_spawn(&pd, jl, NULL, NULL, (char **)&(const char*[]){ jl, [bootstrap UTF8String], "-nomount", NULL }, NULL);
    waitpid(pd, NULL, 0);
    sleep(2);

    char thedisk[11];
    strcpy(thedisk, "/dev/diskN");
    for (int i = 9; i > 2; i--) {
        struct stat st;
        thedisk[9] = i + '0';
        rv = stat(thedisk, &st);
        if (rv == 0) {
            break;
        }
    }
    printf("thedisk: %s\n", thedisk);

    /* 3. mount */

    memset(&args, 0, sizeof(args));
    args.fspec = thedisk;
    args.hfs_mask = 0777;
    //args.hfs_encoding = -1;
    //args.flags = HFSFSMNT_EXTENDED_ARGS;
    //struct timeval tv = { 0, 0 };
    //gettimeofday((struct timeval *)&tv, &args.hfs_timezone);
    rv = mount("hfs", "/Developer", MNT_RDONLY, &args);
    printf("mount: %d\n", rv);
#endif	/* !WANT_CYDIA */

    /* 4. inject trust cache */

    printf("trust_chain = 0x%llx\n", trust_chain);

    struct trust_mem mem;
    mem.next = kread_uint64(trust_chain);
    *(uint64_t *)&mem.uuid[0] = 0xabadbabeabadbabe;
    *(uint64_t *)&mem.uuid[8] = 0xabadbabeabadbabe;

#ifdef WANT_CYDIA
    rv = grab_hashes("/", kread, amficache, mem.next);
#else
    rv = grab_hashes("/Developer", kread, amficache, mem.next);
#endif
    printf("rv = %d, numhash = %d\n", rv, numhash);

    size_t length = (sizeof(mem) + numhash * 20 + 0xFFFF) & ~0xFFFF;
    uint64_t kernel_trust = kalloc(length);
    printf("alloced: 0x%zx => 0x%llx\n", length, kernel_trust);

    mem.count = numhash;
    kwrite(kernel_trust, &mem, sizeof(mem));
    kwrite(kernel_trust + sizeof(mem), allhash, numhash * 20);
    kwrite_uint64(trust_chain, kernel_trust);

    free(allhash);
    free(allkern);
    free(amfitab);

    /* 5. load daemons */

#ifdef WANT_CYDIA
    // FIXME
    rv = posix_spawn(&pd, pt, NULL, NULL, (char **)&(const char*[]){ pt, "derp", "/Library/LaunchDaemons", NULL }, NULL);
#else
    rv = posix_spawn(&pd, pt, NULL, NULL, (char **)&(const char*[]){ pt, "derp", "/Developer/Library/LaunchDaemons/com.openssh.sshd.plist", NULL }, NULL);
#endif

    int tries = 3;
    while (tries-- > 0) {
        sleep(1);
        uint64_t proc = kread_uint64(allproc);
        while (proc) {
            uint32_t pid = kread_uint32(proc + offsetof_p_pid);
            if (pid == pd) {
                uint32_t csflags = kread_uint32(proc + offsetof_p_csflags);
                csflags = (csflags | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW) & ~(CS_RESTRICT | CS_KILL | CS_HARD);
                kwrite_uint32(proc + offsetof_p_csflags, csflags);
                printf("empower\n");
                tries = 0;
                break;
            }
            proc = kread_uint64(proc);
        }
    }

    waitpid(pd, NULL, 0);

    if (proc) {
        kwrite_uint64(proc + offsetof_p_ucred, c_cred);
    }

    printf("done\n");

    FILE *f = fopen("/tmp/k", "wt");
    fprintf(f, "0x%llx 0x%llx\n0x%llx 0x%llx\n", kernel_base, kaslr_shift, trust_chain, amficache);
    fclose(f);
    return 0;
}
