#ifndef SHELL_CORE_H
#define SHELL_CORE_H

#include <gtk/gtk.h>

extern GtkTextBuffer *buffer;

void insert_text(const char *text);
void insert_prompt();
void startup_msg();
void run_command(const char *cmd);
void boot_sequence();

#endif