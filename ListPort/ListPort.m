//
//  ListPort.m
//  ListPort
//
//  Created by simpzan on 01/07/2018.
//

#import "ListPort.h"

#include <libproc.h>
#include <sys/proc_info.h>
#include <sys/sysctl.h>

typedef struct proc_fdinfo proc_fdinfo;
typedef struct kinfo_proc kinfo_proc;
typedef struct socket_fdinfo socket_fdinfo;

BOOL isPort(proc_fdinfo *procFDInfo, int pid, int port) {
    if (procFDInfo->proc_fdtype != PROX_FDTYPE_SOCKET) return NO;
    
    socket_fdinfo socketInfo;
    int bytesUsed = proc_pidfdinfo(pid, procFDInfo->proc_fd, PROC_PIDFDSOCKETINFO, &socketInfo, PROC_PIDFDSOCKETINFO_SIZE);
    if (bytesUsed != PROC_PIDFDSOCKETINFO_SIZE) return NO;
    
    if (socketInfo.psi.soi_family == AF_INET && socketInfo.psi.soi_kind == SOCKINFO_TCP) {
        int localPort = (int)ntohs(socketInfo.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport);
        return port == localPort;
    }
    // todo: inet6, udp port check.
    return NO;
}
BOOL isProcessUsingPort(int pid, int port) {
    // Figure out the size of the buffer needed to hold the list of open FDs
    int bufferSize = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, 0, 0);
    if (bufferSize == -1) {
        ERRNO("proc_pidinfo(%d, PROC_PIDLISTFDS)", pid);
        return NO;
    }
    proc_fdinfo *procFDInfo = (proc_fdinfo *)malloc(bufferSize);
    if (!procFDInfo) {
        ERRNO("malloc(%d)", bufferSize);
        return NO;
    }
    proc_pidinfo(pid, PROC_PIDLISTFDS, 0, procFDInfo, bufferSize);
    BOOL matched = NO;
    for (int i = 0; i < bufferSize / PROC_PIDLISTFD_SIZE; i++) {
        matched = isPort(procFDInfo + i, pid, port);
        if (matched) break;
    }
    free(procFDInfo);
    return matched;
}

int getMaxArgumentSize() {
    int maxArgumentSize = 0;
    size_t size = sizeof(maxArgumentSize);
    int mib[] = { CTL_KERN, KERN_ARGMAX };
    if (sysctl(mib, 2, &maxArgumentSize, &size, NULL, 0) == -1) {
        perror("sysctl argument size");
        maxArgumentSize = 4096; // Default
    }
    return maxArgumentSize;
}
NSString *getProgramPath(int pid) {
    size_t size = getMaxArgumentSize();
    char *buffer = (char *)malloc(size);
    int mib[] = { CTL_KERN, KERN_PROCARGS2, pid };
    int result = sysctl(mib, 3, buffer, &size, NULL, 0);
    NSString *executable = NULL;
    if (result == 0) {
        executable = [NSString stringWithCString:(buffer+sizeof(int)) encoding:NSUTF8StringEncoding];
    }
    free(buffer);
    return executable;
}
NSArray *getProcesses() {
    int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    size_t length;
    int result = sysctl(mib, 3, NULL, &length, NULL, 0);
    if (result < 0) return NULL;
    
    kinfo_proc *info = malloc(length);
    if (!info) return NULL;
    
    result = sysctl(mib, 3, info, &length, NULL, 0);
    if (result < 0) {
        free(info);
        return NULL;
    }
    
    int count = (int)length / sizeof(kinfo_proc);
    NSMutableArray *pids = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        pid_t pid = info[i].kp_proc.p_pid;
        [pids addObject:@(pid)];
    }
    free(info);
    return pids;
}

NSString *ListPort(int port, int *processId) {
    NSArray *pids = getProcesses();
    if (!pids) return NULL;
    
    for (NSNumber *pidNumber in pids) {
        int pid = pidNumber.intValue;
        if (isProcessUsingPort(pid, port)) {
            *processId = pid;
            return getProgramPath(pid);
        }
    }
    return NULL;
}

