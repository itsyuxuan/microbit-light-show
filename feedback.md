---
mark: 19

section_marks:
  analysis: 3
  communication: 2
  design: 4
  implementation: 10
---

### Sophistication of your design
This is a fantastic submission, very well done. The combination of memory encoded visuals and audio, plus random generation of the blood drips is very sophisticated.

### Sophistication of your implementation
Your use of functions is great - good function names and commenting makes them easier to understand. One nitpick is that calling convention was not always followed, a few saves of scratch registers by the callee and unnecessary doubled saves of the lr. music.S has a few examples.
Great use of memory too - global variables and constants used at a high level. One suggestion for improvement - you used words to store a single bit of information. This leaves 31 bits unused, can you think of a way to be more memory efficient?
You even further modularised your program by breaking it up into seperate files, which is appropriate for an assignment of this size. Your commenting is consistent and helpful. 

### Sophistication of analysis and evaluation
Analysis is perhaps the one area that could use some work. I saw that you mentioned functions being good for reusable/understandble code, memory for saving on register use, and the limitation on sharing a purely sequential CPU between visual and audio computation. 
Other potential topics - are there limitations on LCG? Why/why aren't they negligible for this purpose? Is saving on register usage the only reason why using memory is beneficial? 

### Sophistication of communication and expression
Good communication - language at an appropriate level of abstraction

Word count: 581

