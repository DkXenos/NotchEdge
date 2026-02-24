#ifndef Notch_Bridging_Header_h
#define Notch_Bridging_Header_h

// Exposes forkpty() and openpty() for PTY creation.
// forkpty forks the process, connects the child to a slave PTY,
// and returns the master fd to the parent — giving us a real terminal.
#include <util.h>
#include <termios.h>
#include <sys/ioctl.h>

#endif
