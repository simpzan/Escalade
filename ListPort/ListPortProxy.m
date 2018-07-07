//
//  ListPortProxy.m
//  Escalade
//
//  Created by simpzan on 07/07/2018.
//

#include <arpa/inet.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>
#include "ListPortProxy.h"

#define LOG_I(format, args...) NSLog(format, ##args)
#define LOG_E(format, args...) NSLog(format, ##args)
#define ERRNO(format, args...) NSLog(format " failed, %s\n", ##args, strerror(errno))

NSString *parseResponse(char *response, int *pid) {
    char *tail = response + strlen(response) - 1;
    if (*tail == '\n') *tail = 0;

    *pid = atoi(response);
    const char *space = strchr(response, ' ');
    if (!space) return NULL;
    return [NSString stringWithUTF8String:space + 1];
}

NSString *rpc(int sock, int port, int *pid) {
    char request[16] = { 0 };
    sprintf(request, "%d\n", port);
    send(sock, request, strlen(request), 0);

    char response[1024] = { 0 };
    ssize_t result = recv(sock, response, sizeof(response), 0);
    if (result <= 0) {
        ERRNO(@"recv()");
        return NULL;
    }
    return parseResponse(response, pid);
}

int tcpConnect(const char *address, int port) {
    struct sockaddr_in server_address = { 0 };
    server_address.sin_family = AF_INET;
    inet_pton(AF_INET, address, &server_address.sin_addr);
    server_address.sin_port = htons(port);

    int sock = socket(PF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        ERRNO(@"socket()");
        return -1;
    }
    int result = connect(sock, (struct sockaddr*)&server_address, sizeof(server_address));
    if (result < 0) {
        ERRNO(@"connect(%s:%d)", address, port);
        close(sock);
        return 0;
    }
    return sock;
}

NSString *ListPortRPC(int port, int *processId) {
    int sock = tcpConnect("127.0.0.1", 9999);
    NSString *output = NULL;
    if (sock) output = rpc(sock, port, processId);
    close(sock);
    return output;
}
