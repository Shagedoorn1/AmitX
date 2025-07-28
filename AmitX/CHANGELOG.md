# CHANGELOG.md  
_The timeline of dreams, bugs, and caffeine-fueled progress._

---

## [0.0.1] — *“Awake and Booting”*  
*Release date: 2025-06-14*

The very first public hoot. She’s alive. She boots. She hoots. And she compiles C like it’s nobody’s business.

---

### Added

- **Owly Compiler**  
  - Translates `.owly` files into proper, honest C code.  
  - Supports `func` declarations, `main`, `print`, and even **C-style for loops**.  
  - Output so clean, C compilers smile politely.  

- **Owly Shell Integration**  
  - A shell interface that hoots back when spoken to.  
  - Supports `hoot`, `clear`, and looking aesthetic while doing it.  

- **CLI Compilation Script**  
  - Run your Owly code in one command: `./owlyc.sh test.owly`  
  - Add `--verbose` to watch the generated C in VS Code.  
  - Add `--nodelete` if you’re a file hoarder, this does not delet the generated C code.  

- **Boot Script (`boot.sh`)**  
  - Kicks off the AmitX shell environment.  
  - Uses `make run` behind the scenes like a sneaky raccoon.  
  - Or use `./boot.sh`, same result, hopefully!
---

### Tools

- **Basic Makefile**  
  - Abstracts the build and run steps.  
  - `make run` launches the shell with all its shiny GTK glory.  

- **C project structure**  
  - Structured enough to fool people into thinking it’s organized.  
  - Separate headers for `amitx_info.h` and shell GUI.

---

### Known Oddities

- The shell might take a second to launch. She’s waking up, let her vibe.  
- Owly *will* judge your function order if you define before declaring. She compiles it anyway.  
- No user management, process isolation, or real kernel tasks — **yet**.
- Kernel might not work, largely because it doesn't exist yet.

---

### Roadmap Hints

- Support for pipes in the shell (hoot | grep 'danger')  
- A filesystem (probably called `hootfs`, let’s be real)  
- Owly: string manipulation, conditionals, pyfor loops maybe  
- Syntax for declaring variables without sacrificing your soul  

## [0.1.0] — *“Ring 0 Royalty”*
*Release date: 2025-07-08*

This is it. The kernel exists. It boots, interrupts, ticks, and even *sleeps*.
No emulator magic — just pure hardware hugs.

---
### Added

- **The Kernel**
  - It's real. It's C. It's got assembly in all the right places.
  - Lives in the noble `src/`, birthed by bootloaders, welcomed by GRUB.
  - Prints, divides by zero (on purpose), and recovers with *grace*.
  - Keyboard input handler (IRQ1 party)  
- **GDT + IDT Setup**
  - Who needs user space? We're comfy in ring 0.
  - Installed and loaded like legends.
  - Custom interrupt handlers make your CPU say: "yes, chef".

- **ISR + Timer interrupts (PIT at 100 Hz)**
  -IRQ0 fires. We catch it. `tick_count++`  
  - Remapped and ready for action — no more PIC noise.  
  - Added `isr_stub.S` with handcrafted `cli`, `pusha`, `iret` like it’s the '90s.

- **Sleep function**
  - Sleeps for real seconds using timer ticks.
  - No more fake delays — this nap is hardware-approved.
  - Debug prints included, because if an interrupt fires and no one logs it, did it really happen?

---

### Tools

- **How to Build and boot?**
```sh
cd AmitX/Kernel
chmod +x boo.sh
./boo.sh
```
The kernel will build and boot in QEMU automatically.

---

### Know oddities
- Timer interrupts used to fire only once — it’s fine now, it's debugged away with rage and love
- When testing the ISRs , make sure that the mistakes you made on purpose are volatile, GCC is too kind sometimes.
- `sleep()` was spiritually broken before ticks were fully understood.
- No keyboard input — sleeping beauty awaits her princess IRQ1.

---

### Roadmap Hints
- Paging, because memory management is sexy  
- Multitasking (even if it’s fake at first)  
- Fancy `screen_puts_at()` so we can print in style  
- Owly code that can call into kernel land

## [0.2.0] — *"Cyclone Engaged"*
*Release date: 2025-07-11*

A shell within a shell. Cyclone is born — a tiny interactive terminal nested inside the kernel.
It runs commands, reads virtual files, changes logos, and doesn't even crash when you lie to it.

### Added
- **Main Menu**
  - Includes Perch, Owly, Cyclone and Exit
  - Perch: launch the Perch app
  - Owly: nothing for now
  - Cyclone: load Cyclone terminal
  - Exit: exit the kernel
  - Navigate with `w`, `d` and `enter`
- **AmitC**
  - It's sys_calls and stuff
  - That's it
- **Cyclone**
  - Accepts commands like: `echo`, `clear`, `read`, `hex`, and `coffee` (yes, really).
- **Command parser**
  - Includes commands:
    1. `echo`
    2. `clear`
    3. `hex <number>`
    4. `time`
    5. `back`
    6. `quit`
    7. `switch logo`
    8. `ls`
    9. `read <filename>`
  - It's coding like the 90`s
- **File System Layer**
  - Virtual file layer with static files living at paths like `/Saved/hello.txt` and `/Saved/log.txt`
  - `fs_read(path)` returns the contents of any preloaded file.
  - `fs_debug_list()` prints the FS tree for dev convenience.
- **String Utilities Expanded**
  - Added `strcmp`, `strcat` and a bunch of helpers
  - `atoi()` now helps turn string arguments into number for commands like `hex`.
- **Owly, now more owl**
  - Now includes:
    - small owly
     ```
      ___
     (o,o)
     {" "}
      " "
      ```
    - big owly
    ```
      ____________
     / ____  ____ \
    / / @  \/ @  \ \
    \ \____/\____/ /\
     \_____\/_____/||
     /       /\\\\\//
     |0xC0FFEE\\\\\\
     \        \\\\\\
      \________/\\\\
        _||_||_  \\\
         -- --    \\
    ```
  - switch between them with `switch logo`
- **Settings Parser (Planned)**
  - Reads from `/Saved/setting.cfg` (mocked in-memory for now).
  - Allows boot-time configuration like logo style default theme, and more.
- **Menu System Overhaul**
  - Clean separation between menu navigation and REPL input
  - `menu` flag enables or disables navigation logic cleanly.
- **Better Boot Script UX**
  - `boo.sh` launches QEMU in full-screen with `-full-screen`.
  - Includes hardware exit via `isa-debug-exit`.

### Tools
- **Cyclone Commands Are Modular**
  - All live in `/cyclone/commands.c/.h`
  - Easily extended with more shell utilities like `cat`, `touch`, or `set`.
- **Settings System (WIP)**
  - Parse `key=value` pairs from a virtual `.cfg` file.
  - Foundation for saving preferences like color theme, default user, shell behaviour.
### Known Oddities
- `strcat` doesn't copy — it appends in place, so always work with fresh memory.
- Reading files more than once with `read` now works correctly
- Cyclone REPL can still accidentally process phantom charaters, or swallow characters if `first` isn't set correctly, this should be fine.
### Roadmap Hints
- Save/Load from real user-modifiable files (not just `const char*`)
- Writable filesystem with `fs_write()` and `fs_create()`
- Environment settings saved *across reboots*
- History, tab autocomplete, maybe even `.bashrc`-like boot behaviour.
- Owly scripting that can call internal functions and syscalls.

## [0.2.1] — *Remember*
### Added
- **Kernel**
  - Paging, finally
  - An actually working `malloc()` and `strdup()`
  - page mapping, sort of, some physical address might not work so be carefull
  - Simple GUI elements to make AmitX just a tiny bit prettier:
    1. `draw_box(x, y, width, height, color)`
    2. `draw_title_box(x, y, width, height, title, color)`
    3. `draw_progress_bar(x, y, width, percent, fg, bg)`
  - Screen.h now also provides several color themes:
    1. `COLOR_THEME_DEFAULT = 0x0F` white on black
    2. `COLOR_THEME_STATUS 0x1F` white on blue
    3. `COLOR_THEME_HIGHLIGHT = 0xF0` black on white
  - Main menu is now drawn with the `draw_list` function
  - Simple task managing and scheduling
  - A `|` in cyclone as the cursor
  - A proper syscall table and ISR128
### Removed
- AmitC, irrelevant, we have *real* syscalls now.
### Fixed
- **Kernel**
  - Fixed bug with `back` command that would print characters in the main menu
  - The corsor works ***properly*** now
  - Something with heap.c probably, I spent a lot of time on it. It's better now, I hope.
### Up next
  - Experiments with improved graphics are being done