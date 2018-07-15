//
//  ListPortProxy.m
//  Escalade
//
//  Created by simpzan on 07/07/2018.
//

#include <arpa/inet.h>
#include <sys/socket.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "ListPortProxy.h"

#define LOG_I(format, args...) printf(format "\n", ##args)
#define LOG_E(format, args...) printf(format "\n", ##args)
#define ERRNO(format, args...) printf(format " failed, %s\n", ##args, strerror(errno))


NSString *readString(int sock) {
    char buffer[1024] = { 0 };
    int64_t result = read(sock, buffer, sizeof(buffer));
    if (result <= 0) return NULL;
    return [NSString stringWithUTF8String:buffer];
}
BOOL writeString(int sock, NSString *response) {
    const char *data = [response UTF8String];
    int64_t length = [response length];
    int64_t result = write(sock, data, length);
    if (result < 0) {
        ERRNO("write %lld bytes", length);
        return NO;
    }
    if (result != length) {
        LOG_E("incomplete write");
        return NO;
    }
    return YES;
}

int tcpConnect(const char *address, int port) {
    struct sockaddr_in server_address = { 0 };
    server_address.sin_family = AF_INET;
    inet_pton(AF_INET, address, &server_address.sin_addr);
    server_address.sin_port = htons(port);

    int sock = socket(PF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        ERRNO("socket()");
        return -1;
    }
    int result = connect(sock, (struct sockaddr*)&server_address, sizeof(server_address));
    if (result < 0) {
        ERRNO("connect(%s:%d)", address, port);
        close(sock);
        return 0;
    }
    return sock;
}
int tcpListen(int port) {
    int listen_sock = socket(PF_INET, SOCK_STREAM, 0);
    if (listen_sock < 0) {
        ERRNO("socket()");
        return -1;
    }

    struct sockaddr_in server_address = { 0 };
    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(port);
    server_address.sin_addr.s_addr = htonl(INADDR_ANY);

    int result = bind(listen_sock, (struct sockaddr *)&server_address, sizeof(server_address));
    if (result < 0) {
        ERRNO("bind(%s:%d)", "INADDR_ANY", port);
        return -1;
    }

    int wait_size = 16;
    result = listen(listen_sock, wait_size);
    if (result < 0) {
        ERRNO("listen(%d)", port);
        return -1;
    }
    return listen_sock;
}

typedef NSString *(^RequestHandler)(NSString *request);
void handleRequest(int sock, RequestHandler handler) {
    NSString *request = readString(sock);
    if (!request) return;
    NSString *response = handler(request);
    LOG_I("%s -> %s", request.UTF8String, response.UTF8String);
    writeString(sock, response);
}
int handleRequests(int listenSock, RequestHandler handler) {
    struct sockaddr_in client_address = { 0 };
    socklen_t client_address_len = 0;

    while (true) {
        int sock = accept(listenSock, (struct sockaddr *)&client_address, &client_address_len);
        if (sock < 0) {
            ERRNO("accept(%d)", sock);
            return 1;
        }
        handleRequest(sock, handler);
        close(sock);
    }
}

NSString *clientRPC(NSString *request, int port) {
    NSString *response = NULL;
    int sock = tcpConnect("127.0.0.1", port);
    if (sock < 0) return response;
    BOOL ok = writeString(sock, request);
    if (ok) response = readString(sock);
    close(sock);
    return response;
}
int startServer(int port, RequestHandler handler) {
    int sock = tcpListen(port);
    if (sock < 0) return -1;
    handleRequests(sock, handler);
    close(sock);
    return 0;
}


static int listPortServicePort = 9997;

NSString *parseResponse(NSString *response, int *pid) {
    NSArray *components = [response componentsSeparatedByString:@" "];
    if (components.count < 2) return NULL;
    int thePid = [components[0]intValue];
    if (thePid <= 0) return NULL;
    *pid = thePid;
    NSArray *programParts = [components subarrayWithRange:NSMakeRange(1, components.count - 1)];
    return [programParts componentsJoinedByString:@" "];
}
NSString *ListPortRPC(uint32_t port, int *processId) {
    NSString *request = [NSString stringWithFormat:@"%u", port];
    NSString *response = clientRPC(request, listPortServicePort);
    return parseResponse(response, processId);
}
//#define LISTPORT
#ifdef LISTPORT
#include "ListPort.h"
int ListPortServer(void) {
    return startServer(listPortServicePort, ^NSString *(NSString *request) {
        uint32_t port = (uint32_t)[request longLongValue];
        int pid = -1;
        NSString *program = ListPort(port, &pid);
        if (!program) LOG_E("NotFound");
        NSString *response = [NSString stringWithFormat:@"%d %s", pid, program.UTF8String];
        return response;
    });
}
#endif
