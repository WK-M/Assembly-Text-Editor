# Assembly Text Editor 
This is the final project that was dedicated for CSc 21000 (Assembly Language) at CCNY.

## Prerequisites
- DOSBOX
- TASM

## Background
This is an assembly text editor with vim-like features such as the movement and deleting at cursor position. In addition to the vim-like features, I have added a drawing option which allows users to draw boxes. A unique features about these boxes is that there is a "block" detection which prevents letters from overwriting the boxes.

## To Run:
- In DOSBOX:

```
tasm main
tlink main /t
main
```

### Credit:
Thank you to srajan-17, as I gained some knowledge after looking at his code when implementing the text.
