# Experiment on Object Files

An experiment on object files.

Basically on static linking.

## Steps

1.  Go to WSL environment.
1.  Move the terminal panel to the right.
1.  Compile the code: `make main`.
1.  experiments:
    -   check disassembled:
        -   `objdump -d main`
        -   `objdump -d main.o`
        -   `objdump -d sum.o`

    -   check the symbols:
        -   `readelf -SWs main`
        -   `readelf -SWs main.o`
        -   `readelf -SWs sum.o`
    
    -   check symbol table:
        -   `readelf -r main`
        -   `readelf -r main.o`
        -   `readelf -r sum.o`

    -   check hex:
        -   `hexdump -C main`
        -   `hexdump -C main.o`
        -   `hexdump -C sum.o`
1.  cases
    1.  `objdump -d main.o`
        -   ```text
                8:   be 02 00 00 00          mov    $0x2,%esi
                d:   bf 00 00 00 00          mov    $0x0,%edi
               12:   e8 00 00 00 00          callq  17 <main+0x17>
            ```
            -   `02 00 00 00` -> 2
                -   little-endian
                -   left is low address.
                -   `int` has 4 bytes
                -   hex has 4 bits.
            -   line `8`: load argument `2`.
            -   line `d`: load argument `array`.
                -   `00 00 00 00`
                    -   unknown address to `array`.
            -   line `12`: call function `sum`.
                -   `00 00 00 00`
                    -   unknown address to `sum`.
    1.  `objdump -d main`
        -   In `<main>`:

            ```text
              40049f:       be 02 00 00 00          mov    $0x2,%esi
              4004a4:       bf 30 10 60 00          mov    $0x601030,%edi
              4004a9:       e8 0a 00 00 00          callq  4004b8 <sum>
            ```
            -   those addresses are resolved.
    1.  `readelf -r main.o`
        -   ```text
            Relocation section '.rela.text' at offset 0x498 contains 2 entries:
              Offset          Info           Type           Sym. Value    Sym. Name + Addend
            00000000000e  000d0000000a R_X86_64_32       0000000000000000 array + 0
            000000000013  000f00000002 R_X86_64_PC32     0000000000000000 sum - 4
            ```
            -   `R_X86_64_32` := replace the `0`s to a absolute address
            -   `R_X86_64_PC32` := replace the `0`s to a relative address to PC.
    1.  `objdump -dx main.o`
        -   ```text
               8:   be 02 00 00 00          mov    $0x2,%esi
               d:   bf 00 00 00 00          mov    $0x0,%edi
                                    e: R_X86_64_32  array
              12:   e8 00 00 00 00          callq  17 <main+0x17>
                                    13: R_X86_64_PC32       sum-0x4
              17:   89 45 fc                mov    %eax,-0x4(%rbp)
            ```
            -   it shows the relocation records.
                -   `e: R_X86_64_32  array`
                -   `13: R_X86_64_PC32       sum-0x4`
            -   `e:`: at `e` offset from the beginning of `main`, there has a reference to a memory location.
                -   memory location: global data structure array.
            -   `R_X86_64_32  array`
                -   the target address, linker overwrites the `00 00 00 00` to which, is the absolute address of `array`.
                -   `R_X86_64_32`
                    -   `32`: 32 bits -> 4 bytes -> overwrite the following four bytes -> overwrite `00 00 00 00`.
            -   `R_X86_64_PC32       sum-0x4`
                -   `-0x4`: `addend`.
                -   `<the exact address of sum> - 4 = <address of the 00 00 00 00> + <address that is overwrited to 00 00 00 00>`.
                -   PC alway pointers to the next instruction while CPU is working on the previous instruction.
                    -   PC is pointing `17` while the instruction at `12` is executing.
    1.  `objdump -d main`
        -   In `<main>`:

            ```text
              40049f:       be 02 00 00 00          mov    $0x2,%esi
              4004a4:       bf 30 10 60 00          mov    $0x601030,%edi
              4004a9:       e8 0a 00 00 00          callq  4004b8 <sum>
              4004ae:       89 45 fc                mov    %eax,-0x4(%rbp)
            ```
            -   `0a 00 00 00` = `4004b8` - `4004ae`.
            -   PC alway pointers to the next instruction while CPU is working on the previous instruction.
                -   PC is pointing `4004ae` while the instruction at `4004a9` is executing.
    1.  `objdump -dx main`
        -   ```text
            SYMBOL TABLE:
            ...
            0000000000601030 g     O .data  0000000000000010              array
            ...
            00000000004004b8 g     F .text  0000000000000045              sum
            ```
            -   linker at static linking
                1.  linker combine the relocatable object files.
                1.  linker looks for the relocation entries in `.rel.data` and `.rel.text` in `main.o` and `sum.o`.
                    -   eg. linker found `array` in `main.o`. 
                1.  linker finds exact address of the `array` in the combined file.
                1.  linker replaces the 4 bytes `00 00 00 00` started from address `e` to the new address.
            -   `.data`: `array` is put at `.data` section.
1.  compile `make main.2`
1.  cases
    1.  `objdump -dx main.2.o`
        -   ```text
               8:   be 02 00 00 00          mov    $0x2,%esi
               d:   bf 00 00 00 00          mov    $0x0,%edi
                                    e: R_X86_64_32  array+0xc
              12:   e8 00 00 00 00          callq  17 <main+0x17>
                                    13: R_X86_64_PC32       sum-0x4
            ```
            -   `array+0xc`
                -   `+0xc`
                    -   `addend`.
                    -   the array offset.

## Additions

### `readelf`

-   `Ndx` := index of the section where it has been.
    -   `UND` := unknown. From other relocatable object file.
    -   `1` := `.text`
    -   `3` := `.data`
-   `.rela` := relocation entries.
    -   only relocatable objects have.
    -   executable objects do not have.
        -   those entries are resolved by linking.

### Relocation entries

```c
typedef struct {
    long offset;     /* Offset of the reference to relocate */
    long type:32,    /* Relocation type */
         symbol:32;  /* Symbol table index */
    long addend;     /* Constant part of relocation expression */
} Elf64_Rela;
```
-   `offset`
    -   offset in `.text`/`.data` section.

#### Example

`objdump -dx main.o`:

```text
   8:   be 02 00 00 00          mov    $0x2,%esi
   d:   bf 00 00 00 00          mov    $0x0,%edi
                        e: R_X86_64_32  array
  12:   e8 00 00 00 00          callq  17 <main+0x17>
                        13: R_X86_64_PC32       sum-0x4
  17:   89 45 fc                mov    %eax,-0x4(%rbp)
```

-   `array`
    -   `offset = e`
    -   `type = R_X86_64_32`
    -   `symbol` not shown here.
    -   `addend = 0`
-   `sum`
    -   `offset = 13`
    -   `type = R_X86_64_PC32`
    -   `symbol` not shown here.
    -   `addend = -0x4`

### GCC

-   `no-pie`
    -   That flag is telling gcc not to make a position independent executable (PIE). PIE is a precodition to enable address space layout randomization (ASLR). ASLR is a security feature where the kernel loads the binary and dependencies into a random location of virtual memory each time it's run.

### Tools

-   GNU `binutils`
    -   `ar`. Creates static libraries, and inserts, deletes, lists, and extracts members.
    -   `strings`. Lists all of the printable strings contained in an object file.
    -   `strip`. Deletes symbol table information from an object file.
    -   `nm`. Lists the symbols defined in the symbol table of an object file. 
    -   `size`. Lists the names and sizes of the sections in an object file.
    -   `readelf`. Displays the complete structure of an object file, including all of the information encoded in the ELF header. Subsumes the functionality of `size` and `nm`.
    -   `objdump`. The mother of all binary tools. Can display all of the information in an object file. Its most useful function is disassembling the binary instructions in the `.text` section.

-   Linux systems
    -   `ldd`: Lists the shared libraries that an executable needs at run time.

## Reference

-   <https://youtu.be/E804eTETaQs>
-   csapp/Chapter 7: Linking.
