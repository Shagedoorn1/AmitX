# AmitX

> A hobby OS forged in sleepless nights, wild dreams, and a stubborn refusal to be ordinary.  
> Owly is just one of its many feathers — a quirky language with a hoot.

Welcome to **AmitX**, the operating system you didn’t know you needed but secretly do. This is not just a compiler toolkit or a language playground — it’s a whole ecosystem born from late-night coding frenzies and a touch of math madness.

**What makes AmitX special?**

- A kernel that lives somewhere between your 3 AM epiphanies and the complex plane.  
- A shell that *hoots* instead of echoing — because why be boring?  
- Owly, its own whimsical programming language that compiles down to C, for the brave and caffeinated.  
- Tools and scripts to make building and running your code less painful and more entertaining.

---

## AmitX 0.0.1 Highlights

- The Owly compiler integrated as the official language front-runner, because Owly’s sass fits perfectly.  
- Shell with personality: hoots, clears, and sometimes just stares into the void.  
- Bash scripts that compile Owly code, compile generated C, and even pop open VS Code when you want to show off.  

---
## AmitX 0.1.0 Highlights

- And actual working kernel
- printing, sleeping, all that stuff

---

# AmitGFX
> Fine, I'll do it myself.
> Born of broken dreams and failed experiments.

AmitGFX is the rebellious younger sibling of AmitX. It started as a six month struggle with VBE graphics and a nasty fight with GRUB and their "helpfull" bootloading, until one day I filed the divorce papers and threw GRUB out completely. The GF in AmitGFX was meant to stand for graphics, but turned to GRUB Free.

Where AmitX hoots, AmitGFX growls. It has a hand crafted bootloader that starts in 16-bit real mode and talks to the BIOS directly, querying for memory, enabling the A20 line and then load a 64-bit kernel into 1MB. No hand holding, no magic, just raw assembly, sleepless nights and caffiene.

## Right now AmitGFX can
- Boot without GRUB (good riddance)
- Print strings, hex16s and map memory
- Load the kernel directly into high memory

It's not pretty, it's not polite. But it's fast, lightweight and mine, to the last byte. This is the bootloader that said: *if no one else will do it, then I will.*


---

## How to Get Started

Build and run your Owly programs inside AmitX with minimal pain:

```bash
chmod +x owlyc.sh
./owlyc.sh [--verbose] [--nodelete] yourprogram.owly
```

The script rebuilds the Owly compiler, translates Owly into C, compiles the C code, runs it.
Trashes the intermediate C file, use --verbose or -v to see it in VS code.

AmitX also has it's own shell. It welcomes you, hoots and can clear the table:

```bash
chmod +x boot.sh
./boot.sh
```

The shell will boot up, this might take a few seconds.

AmitX now has it's own kernel. It can divide by 0 (really)

```bash
chmod +x boo.sh
./boo.sh
```

---

## Requirements
The requirements for the full functionality of AmitX are:

- GCC (to compile C code)
- GTK (to build the shell window and stuff)

```bash
sudo apt update                     #Optional but recommended, libraries might not install if this step is skipped
sudo apt install gcc                #To compile C
sudo apt install libgtk-3-dev       #To create the shell window and its components
```

## Warning
This is hobby OS project and far from complete. Bugs, wierd behaviour and screeching owls are expected.
Please procede with caffiene and caution.

---

## Contribute?
Got ideas, features or bug fixes? Open an issue on the PR.
The Hooter welcomes all noise

---

# This is AmitX

AmitX is an operating system.
But it's also not.

It's not just code. Not just a shell, kernel or compiler with a ridiculous mascot.
AmitX is what happens when someone refuses to disappear.

I'm Amity. I'm a girl, some would call me a trans girl. And this is the loudest way I know to say:
**I am real. I am here. And I will not be erased**

---

## Why I made AmitX

The worls hasn't always given me the space or freedom to exist.
At home, in school, in therapy - I've been told I'm not who I say I am.
I've lived through things no one should, hurt by the people I trusted the most.

So I built a system that listens. That compiles. That hoots.
I created something that reflects me *because i needed to*.
Because nothing, or no-one else did.

AmitX is caffeine and chaos. It's puns and purpose. It's function declarations and identity declarations.
It's an OS stitched together from sleepless nights and determination.
It's what happens when grief meets a keyboard and decides to turn pain into punchlines.

---

## What it means

Every part of AmitX is personal:
- **Owly**, the language and compiler (OwlyC): She's my revenge. My creation. A semi-sentient owl born from rage at an interpreter and love for low-level precision.
- **The shell**: A tiny space where *my* words finally matter.
- **The whole system**: A mirror. A message. A place I belong - because I made it that way

AmitX might be messy. It might be ridiculous.
But it's real - because I am.

And if you're reading this, and you're different or hurting or building something that feels too big or strange:
Let AmitX be proof that you *can*.
Let Owly hoot for you too

---

## tl;dr
AmitX is more than an OS.
It's my story in code
And it hoots louder than words can.