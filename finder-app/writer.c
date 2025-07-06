#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <syslog.h>

int main(int argc, char *argv[])
{
    /* Open connection to syslog using the LOG_USER facility */
    openlog("writer", LOG_PID, LOG_USER);

    if (argc != 3) {
        syslog(LOG_ERR, "Invalid number of arguments: expected 2, got %d", argc - 1);
        fprintf(stderr, "Usage: %s <file_path> <string>\n", argv[0]);
        closelog();
        return EXIT_FAILURE;
    }

    const char *file_path = argv[1];
    const char *string_to_write = argv[2];

    /* Open the file for writing, create if it doesn't exist, truncate if it does */
    int fd = open(file_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd == -1) {
        syslog(LOG_ERR, "Failed to open %s: %s", file_path, strerror(errno));
        perror("open");
        closelog();
        return EXIT_FAILURE;
    }

    /* Write the string followed by a newline (echo's default behaviour) */
    size_t len = strlen(string_to_write);
    ssize_t written = write(fd, string_to_write, len);

    /* Write the string */
    if (written == -1 || (size_t)written != len) {
        syslog(LOG_ERR, "Failed to write to %s: %s", file_path, strerror(errno));
        perror("write");
        close(fd);
        closelog();
        return EXIT_FAILURE;
    }

    /* Add a newline */
    if (write(fd, "\n", 1) != 1) {
        syslog(LOG_ERR, "Failed to write newline to %s: %s", file_path, strerror(errno));
        perror("write");
        close(fd);
        closelog();
        return EXIT_FAILURE;
    }

    close(fd);

    /* Log success with LOG_DEBUG level */
    syslog(LOG_DEBUG, "Writing %s to %s", string_to_write, file_path);

    closelog();
    return EXIT_SUCCESS;
}
