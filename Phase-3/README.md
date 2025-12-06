# Phase 3 – Input & Interrupt Handling

Integrated keyboard-driven control using hardware and software interrupts:
- Game waits on a static screen until any key is pressed
- Red car moves by default in the center lane
- Left/right arrow keys shift the car between the three lanes (bounded correctly)
- Up/down arrow keys move the car vertically one block at a time (with limits)
- ESC opens a centered confirmation dialog (“Do you want to quit?”)
- Pressing Y exits smoothly back to the main screen
- Pressing N resumes the game without glitches
- Pressing ESC again resumes the game directly
- Confirmation dialog implemented through software interrupts

Movement logic, lane constraints, and pause/resume flow were cleanly modularized into subroutines.  


---

The attached PDF contains the official Phase 3 instructions.  

The code in this folder is labeled accordingly as **Phase 3**.

