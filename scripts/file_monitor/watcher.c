// watcher.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/inotify.h>
#include <sys/socket.h>
#include <sys/un.h>

#include <pthread.h>

  #define SOCKET_PATH "/tmp/fs_notify_socket"

  #define EVENT_BUF_LEN (1024 * (sizeof(struct inotify_event) + 16))

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <ruta_a_vigilar>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    const char *watch_path = argv[1];

    int inotify_fd = inotify_init();
    if (inotify_fd < 0) {
        perror("inotify_init");
        exit(EXIT_FAILURE);
    }

    int wd = inotify_add_watch(inotify_fd, watch_path, IN_ACCESS | IN_OPEN | IN_MODIFY);
    if (wd == -1) {
        perror("inotify_add_watch");
        exit(EXIT_FAILURE);
    }

    int sock = socket(AF_UNIX, SOCK_DGRAM, 0);
    if (sock < 0) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    struct sockaddr_un addr = {0};
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);

    char buffer[EVENT_BUF_LEN];

    while (1) {
        int length = read(inotify_fd, buffer, EVENT_BUF_LEN);
        if (length < 0) continue;

        int i = 0;
        while (i < length) {
            struct inotify_event *event = (struct inotify_event *) &buffer[i];
            if (event->len > 0) {
                char msg[256];
                snprintf(msg, sizeof(msg), "📂 Evento: %s (mask=%x)", event->name, event->mask);
                sendto(sock, msg, strlen(msg), 0, (struct sockaddr *) &addr, sizeof(addr));
            }
            i += sizeof(struct inotify_event) + event->len;
        }
    }

    close(inotify_fd);
    return 0;
}
