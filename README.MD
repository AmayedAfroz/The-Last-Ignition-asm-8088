# The-Last-Ignition-asm-8088


<img width="426" height="240" alt="Image" src="https://github.com/user-attachments/assets/8e8f7238-c2af-4d17-8bb0-06ab423a742c" />

*Check out the full development breakdown and high-res gameplay on my [LinkedIn Post](https://www.linkedin.com/posts/amayedafroz_i-like-keeping-things-simple-if-i-can-build-ugcPost-7403553785127632896-krDg/?utm_source=share&utm_medium=member_desktop&rcm=ACoAAETZUNABlU7_wXTLLFhOR3xudJ692uqZi8U).*

8088 assembly 2D racing game, built solo, from scratch. Full project. Full features.  
And yeah — I kinda just did it on the side. Institution projects are fun sometimes.

---

This repository contains all six phases of the COAL semester project, from the static start screen all the way to a fully playable, multitasking game with background music.

---

## ⚙ Requirements
To run the project, you’ll need:
- **NASM** (for assembling the .asm files)
- **DOSBox** (to execute the .com files)

---
 
## ▶ Running the Project

### **Phases 1–4**
Each phase folder contains its respective `.asm` file(s).  
To run:

1. Assemble:
`nasm -f bin filename.asm -o filename.com`
*(Note: don’t be dumb — replace ‘filename’ with your actual file name).*

2. Load the `.com` file in DOSBox and run it.  
*(If you've never touched DOSBox before, you have to mount your local drive first. Type this in the DOSBox terminal):*

    mount c c:\path\to\your\folder
    c:
    filename.com

These phases cover the progression of screens, movement logic, animation, lane switching, and UI flow.

---

### **Phases 5 & 6**
These phases contain multiple `.asm` modules.

1. Assemble all files into `.com` binaries.  
2. Run the provided `run.bat` file inside DOSBox — it will execute everything in the correct order. 
*(Again, make sure you mounted your folder in DOSBox first using the mount command above).*

Phase 6 includes:
- Complete gameplay  
- Fuel system  
- Coins, scoring, collisions  
- Lane mechanics  
- Ending screens  
- Multitasking background music  

---

## 🎮 Want to Play the Actual Game?
**Phase 6 is the full game.** If you only want to play, simply assemble Phase 6 and run the `run.bat` file.

---

## 📁 Project Structure
Each folder contains:
- Phase-specific assembly code  
- A short Phase README  
- The official Phase instructions PDF  

---

## 💬 Contact
For any queries or help, feel free to reach out.
