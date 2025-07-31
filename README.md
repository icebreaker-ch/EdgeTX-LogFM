# LogFM The LogFileManager
A tool to manage logfiles, recorded by the SD Logging special function
on an [EdgeTX](https://github.com/EdgeTX/edgetx) B&W or color radio.

The script has been tested on the following radios:
- Radiomaster Zorro
- Horus X12S
- Horus X10S
- Taranis X7 ACCESS
- Taranis X9D+ 2019

**Author:** Roland Schäuble (icebreaker)

## Features and Operation
The start screen shows a tree view (root, Model and logfiles) of the logfiles found on the SD card in the LOGS directory.
Navigation through the tree elements with the Rotary Wheel.
<br/>
Short pressing ```Enter``` on a selected node checks/unchecks all files under that node.
<br/>
Check/unckeck all logfiles for a model by pressing ```Enter``` on a Model node.
<br/>
All logfiles on the SD card can be checked/unckecked by pressing ```Enter``` on the root node.
<br/>
A long press of ```Enter``` leads to a confirmation page to delete the checked logfiles.

During deletion, the progress is displayed.
<br/>
After all checked files were deleted, you are presented a report
of the number of files deleted and the saved space on the SD card.

## Screenshots
### Radiomaster Zorro
| ![](https://github.com/user-attachments/assets/a86aa20c-747c-48a3-ac11-5144622ec98e) |
|:--:|
| *Tree view* |

| ![](https://github.com/user-attachments/assets/835705d0-1f88-4ff6-803e-7915701d4087) |
|:--:|
| Confirmation |

| ![](https://github.com/user-attachments/assets/73dc9109-de82-4f1b-abe3-d030bfaa8c1c) |
|:--:|
| Progress |

| ![](https://github.com/user-attachments/assets/9d906af2-37e5-435c-adfb-189b4e62941b) |
|:--:|
| Report |

## Installation
Copy the file ```LogFM.lua``` and the folder ```LogFM``` to the ```/SCRIPTS/TOOLS``` folder on the SD card.
