#include "shell_core.h"
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include "../amitx_info.h"

#define PROMPT AMITX_SHELL_PROMPT

void boot_sequence() {
    sleep(1);
    printf("Booting ");
    fflush(stdout);
    for (int i = 0; i < 3; i++) {
        sleep(1);
        printf(". ");
        fflush(stdout);
    }
    printf("\n");
}

void insert_text(const char *text) {
    GtkTextIter iter;
    gtk_text_buffer_get_end_iter(buffer, &iter);
    gtk_text_buffer_insert(buffer, &iter, text, -1);
}

void insert_prompt() {
    insert_text(PROMPT);
}

void startup_msg() {
    insert_text(AMITX_BOOT_MSG);
    insert_text("\n");
}

void run_clear() {
    gtk_text_buffer_set_text(buffer, "", -1);
    startup_msg();
    insert_prompt();
}

void run_hoot(const char *cmd) {
    insert_text("\n");
    insert_text(cmd + 5);
    insert_text("\n");
    insert_prompt();
}

void run_why() {
    FILE *file = fopen("../MOTIVE.md", "r");
    insert_text("\n");
    if (file) {
        char line[512];
        insert_text("\n");
        while (fgets(line, sizeof(line), file)) {
            insert_text(line);
        }
        insert_text("\n");
        fclose(file);
        insert_text("\n");
        insert_prompt();
    } else {
        insert_text("\nCould not load MOTIVE.md\n\n");
        insert_prompt();
    }
}

typedef enum {
    CMD_CLEAR,
    CMD_HOOT,
    CMD_WHY,
    CMD_UNKNOWN
} CommandType;

CommandType parse_command(const char *cmd) {
    if (strcmp(cmd, "clear") == 0) {
        return CMD_CLEAR;
    } else if (strncmp(cmd, "hoot ", 5) == 0) {
        return CMD_HOOT;
    } else if (strcmp(cmd, "why") == 0) {
        return CMD_WHY;
    } else {
        return CMD_UNKNOWN;
    }
}

void run_command(const char *cmd) {
    CommandType type = parse_command(cmd);

    switch (type) {
        case CMD_CLEAR:
            run_clear();
            break;
        case CMD_HOOT:
            run_hoot(cmd);
            break;
        case CMD_WHY:
            run_why();
            break;
        case CMD_UNKNOWN:
        default:
            insert_text("\nUnknown command\n");
            insert_prompt();
            break;
    }
}