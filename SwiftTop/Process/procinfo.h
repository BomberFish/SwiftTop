// bomberfish
// procinfo.h – SwiftTop
// created on 2024-01-10

#ifndef procinfo_h
#define procinfo_h

int proc_pidpath(int pid, void * buffer, uint32_t  buffersize) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
int proc_listpidspath(uint32_t type, uint32_t typeinfo, const char *path, uint32_t pathflags, void *buffer, int buffersize) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
int proc_listpids(uint32_t type, uint32_t typeinfo, void *buffer, int buffersize) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
int proc_listallpids(void * buffer, int buffersize) __OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_4_1);
int proc_listpgrppids(pid_t pgrpid, void * buffer, int buffersize) __OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_4_1);
int proc_listchildpids(pid_t ppid, void * buffer, int buffersize) __OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_4_1);
int proc_pidinfo(int pid, int flavor, uint64_t arg,  void *buffer, int buffersize);
int proc_pidfileportinfo(int pid, uint32_t fileport, int flavor, void *buffer, int buffersize) __OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_4_3);
int proc_name(int pid, void * buffer, uint32_t buffersize) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
int proc_regionfilename(int pid, uint64_t address, void * buffer, uint32_t buffersize) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
int proc_kmsgbuf(void * buffer, uint32_t buffersize) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
int proc_libversion(int *major, int * minor) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
int proc_pidfdinfo(int pid, int fd, int flavor, void * buffer, int buffersize) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);

kern_return_t mach_vm_read(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, vm_offset_t *data, mach_msg_type_number_t *dataCnt);
kern_return_t mach_vm_read_overwrite(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, mach_vm_address_t data, mach_vm_size_t *outsize);


struct proc_bsdinfo {
    uint32_t                pbi_flags;              /* 64bit; emulated etc */
    uint32_t                pbi_status;
    uint32_t                pbi_xstatus;
    uint32_t                pbi_pid;
    uint32_t                pbi_ppid;
    uid_t                   pbi_uid;
    gid_t                   pbi_gid;
    uid_t                   pbi_ruid;
    gid_t                   pbi_rgid;
    uid_t                   pbi_svuid;
    gid_t                   pbi_svgid;
    uint32_t                rfu_1;                  /* reserved */
    char                    pbi_comm[MAXCOMLEN];
    char                    pbi_name[2 * MAXCOMLEN];  /* empty if no name is registered */
    uint32_t                pbi_nfiles;
    uint32_t                pbi_pgid;
    uint32_t                pbi_pjobc;
    uint32_t                e_tdev;                 /* controlling tty dev */
    uint32_t                e_tpgid;                /* tty process group id */
    int32_t                 pbi_nice;
    uint64_t                pbi_start_tvsec;
    uint64_t                pbi_start_tvusec;
};


struct proc_bsdshortinfo {
    uint32_t                pbsi_pid;               /* process id */
    uint32_t                pbsi_ppid;              /* process parent id */
    uint32_t                pbsi_pgid;              /* process perp id */
    uint32_t                pbsi_status;            /* p_stat value, SZOMB, SRUN, etc */
    char                    pbsi_comm[MAXCOMLEN];   /* upto 16 characters of process name */
    uint32_t                pbsi_flags;              /* 64bit; emulated etc */
    uid_t                   pbsi_uid;               /* current uid on process */
    gid_t                   pbsi_gid;               /* current gid on process */
    uid_t                   pbsi_ruid;              /* current ruid on process */
    gid_t                   pbsi_rgid;              /* current tgid on process */
    uid_t                   pbsi_svuid;             /* current svuid on process */
    gid_t                   pbsi_svgid;             /* current svgid on process */
    uint32_t                pbsi_rfu;               /* reserved for future use*/
};


#define PROC_ALL_PIDS           1
#define PROC_PGRP_ONLY          2
#define PROC_TTY_ONLY           3
#define PROC_UID_ONLY           4
#define PROC_RUID_ONLY          5
#define PROC_PPID_ONLY          6
#define PROC_KDBG_ONLY          7

/* pbi_flags values */
#define PROC_FLAG_SYSTEM        1       /*  System process */
#define PROC_FLAG_TRACED        2       /* process currently being traced, possibly by gdb */
#define PROC_FLAG_INEXIT        4       /* process is working its way in exit() */
#define PROC_FLAG_PPWAIT        8
#define PROC_FLAG_LP64          0x10    /* 64bit process */
#define PROC_FLAG_SLEADER       0x20    /* The process is the session leader */
#define PROC_FLAG_CTTY          0x40    /* process has a control tty */
#define PROC_FLAG_CONTROLT      0x80    /* Has a controlling terminal */
#define PROC_FLAG_THCWD         0x100   /* process has a thread with cwd */
/* process control bits for resource starvation */
#define PROC_FLAG_PC_THROTTLE   0x200   /* In resource starvation situations, this process is to be throttled */
#define PROC_FLAG_PC_SUSP       0x400   /* In resource starvation situations, this process is to be suspended */
#define PROC_FLAG_PC_KILL       0x600   /* In resource starvation situations, this process is to be terminated */
#define PROC_FLAG_PC_MASK       0x600
/* process action bits for resource starvation */
#define PROC_FLAG_PA_THROTTLE   0x800   /* The process is currently throttled due to resource starvation */
#define PROC_FLAG_PA_SUSP       0x1000  /* The process is currently suspended due to resource starvation */
#define PROC_FLAG_PSUGID        0x2000   /* process has set privileges since last exec */
#define PROC_FLAG_EXEC          0x4000   /* process has called exec  */

/* Flavors for proc_pidinfo() */
#define PROC_PIDLISTFDS                 1
#define PROC_PIDLISTFD_SIZE             (sizeof(struct proc_fdinfo))

#define PROC_PIDTASKALLINFO             2
#define PROC_PIDTASKALLINFO_SIZE        (sizeof(struct proc_taskallinfo))

#define PROC_PIDTBSDINFO                3
#define PROC_PIDTBSDINFO_SIZE           (sizeof(struct proc_bsdinfo))

#define PROC_PIDTASKINFO                4
#define PROC_PIDTASKINFO_SIZE           (sizeof(struct proc_taskinfo))

#define PROC_PIDTHREADINFO              5
#define PROC_PIDTHREADINFO_SIZE         (sizeof(struct proc_threadinfo))

#define PROC_PIDLISTTHREADS             6
#define PROC_PIDLISTTHREADS_SIZE        (2* sizeof(uint32_t))

#define PROC_PIDREGIONINFO              7
#define PROC_PIDREGIONINFO_SIZE         (sizeof(struct proc_regioninfo))

#define PROC_PIDREGIONPATHINFO          8
#define PROC_PIDREGIONPATHINFO_SIZE     (sizeof(struct proc_regionwithpathinfo))

#define PROC_PIDVNODEPATHINFO           9
#define PROC_PIDVNODEPATHINFO_SIZE      (sizeof(struct proc_vnodepathinfo))

#define PROC_PIDTHREADPATHINFO          10
#define PROC_PIDTHREADPATHINFO_SIZE     (sizeof(struct proc_threadwithpathinfo))

#define PROC_PIDPATHINFO                11
#define PROC_PIDPATHINFO_SIZE           (MAXPATHLEN)
#define PROC_PIDPATHINFO_MAXSIZE        (4*MAXPATHLEN)

#define PROC_PIDWORKQUEUEINFO           12
#define PROC_PIDWORKQUEUEINFO_SIZE      (sizeof(struct proc_workqueueinfo))

#define PROC_PIDT_SHORTBSDINFO          13
#define PROC_PIDT_SHORTBSDINFO_SIZE     (sizeof(struct proc_bsdshortinfo))

#define PROC_PIDLISTFILEPORTS           14
#define PROC_PIDLISTFILEPORTS_SIZE      (sizeof(struct proc_fileportinfo))

#define PROC_PIDTHREADID64INFO          15
#define PROC_PIDTHREADID64INFO_SIZE     (sizeof(struct proc_threadinfo))

#define PROC_PID_RUSAGE                 16
#define PROC_PID_RUSAGE_SIZE            0

#define PROC_PIDFDVNODEINFO             1
#define PROC_PIDFDVNODEINFO_SIZE        (sizeof(struct vnode_fdinfo))

#define PROC_PIDFDVNODEPATHINFO         2
#define PROC_PIDFDVNODEPATHINFO_SIZE    (sizeof(struct vnode_fdinfowithpath))

#define PROC_PIDFDSOCKETINFO            3
#define PROC_PIDFDSOCKETINFO_SIZE       (sizeof(struct socket_fdinfo))

#define PROC_PIDFDPSEMINFO              4
#define PROC_PIDFDPSEMINFO_SIZE         (sizeof(struct psem_fdinfo))

#define PROC_PIDFDPSHMINFO              5
#define PROC_PIDFDPSHMINFO_SIZE         (sizeof(struct pshm_fdinfo))

#define PROC_PIDFDPIPEINFO              6
#define PROC_PIDFDPIPEINFO_SIZE         (sizeof(struct pipe_fdinfo))

#define PROC_PIDFDKQUEUEINFO            7
#define PROC_PIDFDKQUEUEINFO_SIZE       (sizeof(struct kqueue_fdinfo))

#define PROC_PIDFDATALKINFO             8
#define PROC_PIDFDATALKINFO_SIZE        (sizeof(struct appletalk_fdinfo))

#define PROC_PIDFDCHANNELINFO           10
#define PROC_PIDFDCHANNELINFO_SIZE      (sizeof(struct channel_fdinfo))

/* Flavors for proc_pidfileportinfo */

#define PROC_PIDFILEPORTVNODEPATHINFO   2       /* out: vnode_fdinfowithpath */
#define PROC_PIDFILEPORTVNODEPATHINFO_SIZE      \
                                    PROC_PIDFDVNODEPATHINFO_SIZE

#define PROC_PIDFILEPORTSOCKETINFO      3       /* out: socket_fdinfo */
#define PROC_PIDFILEPORTSOCKETINFO_SIZE PROC_PIDFDSOCKETINFO_SIZE

#define PROC_PIDFILEPORTPSHMINFO        5       /* out: pshm_fdinfo */
#define PROC_PIDFILEPORTPSHMINFO_SIZE   PROC_PIDFDPSHMINFO_SIZE

#define PROC_PIDFILEPORTPIPEINFO        6       /* out: pipe_fdinfo */
#define PROC_PIDFILEPORTPIPEINFO_SIZE   PROC_PIDFDPIPEINFO_SIZE

/* used for proc_setcontrol */
#define PROC_SELFSET_PCONTROL           1

#define PROC_SELFSET_THREADNAME         2
#define PROC_SELFSET_THREADNAME_SIZE    (MAXTHREADNAMESIZE -1)

#define PROC_SELFSET_VMRSRCOWNER        3

#define PROC_SELFSET_DELAYIDLESLEEP     4

/* used for proc_dirtycontrol */
#define PROC_DIRTYCONTROL_TRACK         1
#define PROC_DIRTYCONTROL_SET           2
#define PROC_DIRTYCONTROL_GET           3
#define PROC_DIRTYCONTROL_CLEAR         4

/* proc_track_dirty() flags */
#define PROC_DIRTY_TRACK                0x1
#define PROC_DIRTY_ALLOW_IDLE_EXIT      0x2
#define PROC_DIRTY_DEFER                0x4
#define PROC_DIRTY_LAUNCH_IN_PROGRESS   0x8
#define PROC_DIRTY_DEFER_ALWAYS         0x10

/* proc_get_dirty() flags */
#define PROC_DIRTY_TRACKED              0x1
#define PROC_DIRTY_ALLOWS_IDLE_EXIT     0x2
#define PROC_DIRTY_IS_DIRTY             0x4
#define PROC_DIRTY_LAUNCH_IS_IN_PROGRESS   0x8

/* Flavors for proc_udata_info */
#define PROC_UDATA_INFO_GET             1
#define PROC_UDATA_INFO_SET             2



#endif /* procinfo_h */
