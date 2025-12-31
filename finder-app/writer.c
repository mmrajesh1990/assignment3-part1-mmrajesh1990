#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <syslog.h>

int main(int argc, char *argv[])
{
    if (argc != 3) {
        syslog(LOG_ERR, "Invalid arguments. Usage: %s <file> <string>", argv[0]);
        return 1;
    }

    const char *file_path = argv[1];
    const char *text = argv[2];

    /* Open syslog */
    openlog("writer", LOG_PID | LOG_CONS, LOG_USER);

    FILE *fp = fopen(file_path, "w");
    if (fp == NULL) {
        syslog(LOG_ERR, "Failed to open file %s: %s", file_path, strerror(errno));
        closelog();
        return 1;
    }

    if (fprintf(fp, "%s", text) < 0) {
        syslog(LOG_ERR, "Failed to write to file %s: %s", file_path, strerror(errno));
        fclose(fp);
        closelog();
        return 1;
    }

    fclose(fp);

    syslog(LOG_DEBUG, "Writing %s to %s", text, file_path);

    closelog();
    return 0;
}

