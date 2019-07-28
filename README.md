# VectorClock Exercise for WM Elixir Lunch and Learn

## Overview


### A [Logical Clock](https://lamport.azurewebsites.net/pubs/time-clocks.pdf) has three conditions:
1. Within a single process, if event A happend before event B, then A -> B.
2. If event A is the sending of a message by one process, and event B is the receipt of that message by a second process, then A -> B. 
3. If A -> B and B -> C, then A -> C.

### A Vector Clock

A VectorClock is a data structure and set of operations that leverages the conditions of a Logical Clock to describe the ordering of events (aka Time) in a distributed system. These are useful when physical clocks are unreliable, especially when synching via NTP is not feasible.

Vector Clock's play two roles in Phoenix's Presence system via the Tracker. One VectorClock is used to optimize the size of the event logs in the Tracker CRDT, while the Tracker CRDT itself satisfies all of the below conditions for a Logical (and Vector) Clock.

Each process in a system keeps a vector of logical clocks for each process it has seen. Vector Clocks follow [these update rules](https://en.wikipedia.org/wiki/Vector_clock):

1. Initally all clocks are set to 0.
2. Each time a process experiences an internal event, it increments its own logical clock in the vector by one.
3. Each time a process sends a message, it increments its own logical clock in the vector by one (as in the bullet above, but not twice for the same event) and then sends a copy of its own vector.
4. Each time a process receives a message, it increments its own logical clock in the vector by one and updates each element in its vector by taking the maximum of the value in its own vector clock and the value in the vector in the received message (for every element).

### Getting Started

There is a provided test harness that asserts the following 4 update rules. The implementation of the vector clock that satisfies these assertions is left to the user.

The tests assume this implemenatation is done within a GenServer module, which has convenient abstractions for state, naming, message handling, etc. However, there are detailed notes describing generic assertions if some other implementation is preferred.

**Note:** A Vector Clock tracks distributed state within a system of processes, for this exercise assume that the calling process in the tests is not a part of that system (it does not implement the TimestampedProcess type).
