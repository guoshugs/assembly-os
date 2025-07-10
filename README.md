# 🛠️ 32-bit Assembly Operating System Project

This is a complete x86 operating system learning project written in Assembly. It was built step-by-step from BIOS bootloading to protected mode, paging, task switching, and even a flat memory model.

这是一个完整的 32 位汇编操作系统项目，从主引导扇区（MBR）开始，一步步进入保护模式，实现分页、多任务切换，最后使用平坦内存模型构建系统。

---

## 📚 Key Features / 项目特性

- ✅ **Bootloader (MBR)** using x86 Assembly
- ✅ **Video memory output** at `0xb800`
- ✅ **Protected Mode transition** using GDT and CR0.PE
- ✅ **GDT / LDT / TSS** task state structures
- ✅ **System call interface** via software interrupts
- ✅ **Privilege-level switching** with CALL gates
- ✅ **Paging and memory management**
- ✅ **Multitasking**: cooperative and preemptive
- ✅ **Flat Memory Model** architecture at the end

---

## 📂 Directory Structure (simplified)

# 🛠️ 32-bit Assembly Operating System Project

This is a complete x86 operating system learning project written in Assembly. It was built step-by-step from BIOS bootloading to protected mode, paging, task switching, and even a flat memory model.

这是一个完整的 32 位汇编操作系统项目，从主引导扇区（MBR）开始，一步步进入保护模式，实现分页、多任务切换，最后使用平坦内存模型构建系统。

---

## 📚 Key Features / 项目特性

- ✅ **Bootloader (MBR)** using x86 Assembly
- ✅ **Video memory output** at `0xb800`
- ✅ **Protected Mode transition** using GDT and CR0.PE
- ✅ **GDT / LDT / TSS** task state structures
- ✅ **System call interface** via software interrupts
- ✅ **Privilege-level switching** with CALL gates
- ✅ **Paging and memory management**
- ✅ **Multitasking**: cooperative and preemptive
- ✅ **Flat Memory Model** architecture at the end

---

## 📂 Directory Structure (simplified)

assembly/
├── c05 ~ c17 # Step-by-step source folders
├── exam.asm # Test program
├── shownumber*.asm # Number display test
├── bochsrc.bxrc # Bochs configuration file
├── *.bin / *.lst # Compiled binaries and listings
└── LearnAsmVHardDisk.vhd (not included in repo)

---

## 🧪 Run Instructions

This project is designed to be run with [Bochs](http://bochs.sourceforge.net/).

You can:
1. Load `.bin` files via `bochsrc.bxrc`
2. Use the `.vhd` file with Bochs or VirtualBox to boot and test
3. Step through boot & kernel logic using Bochs's debugger

---

## 🎓 Purpose and Context

This project was developed as part of my study into x86 architecture and OS internals.  
It demonstrates:
- Low-level system understanding
- Direct memory and hardware manipulation
- Strong familiarity with protected mode and paging

It is included here as part of my school application portfolio.
