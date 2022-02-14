# Modified xv6

## Specification 1 Implementation

- Modified makefile to execute strace.c as well during compilation.
- Add a mask member to the process structure in kernel/proc.h to record how many syscalls need to be traced.
- The trace function's primary role is to adjust the mask during the procedure. The argint function (such as argint (0, & mask) can be used to acquire the arguments of the trace syscall from user space. The register contents of the relevant place are obtained by Argint from the process's trapframe.
- Modify fork() (kernel/proc.c) to produce a new process that inherits the parent process's mask value.
- Get the current process's mask value to see if the presently called syscall is monitored and, if so, print out the related information.

## Specification 2 Implementation

- RR (round robin)
-- This is the default scheduler which checks the first process in the array which is runnable and runs it. The process yields itself after some time if required.

- FCFS (first come first serve)
-- The scheduler checks and finds the process which has the least creating time. This is done by including a new variable crt time in the process struct and recording the ticks variable value at creation of process.

- PBS (priority based scheduling)
-- First we need to include more variabes struct proc for sleep time, run time, end time and even run time in the last iteration.
-- We also need to initialize these variables and then at every tick I am updating run time, run_time_pbs, and even sleep time variables. We need to determine the niceness of the process based on these values and then we need to change dynamic prioirty based on this niceness.On change in prioriity using the set_priority system call, we also need to update the dynamic priority of the process.  Usage `set_priority [pid] [val]`

- MLFQ (Multi level feedback queue)
-- We need to first implement the queue data structure and functions to push/pop etc processes out of the queues. I have maintained 5 queues for processes of different priorities.
-- On the initiation of a process, push it to the end of the highest priority queue. The highest priority queue should be running always, if not empty. If the process completes, it leaves the system. If the process uses the complete time slice assigned for its current priority queue, it is preempted and inserted at the end of the next lower level queue.  If a process voluntarily relinquishes control of the CPU, it leaves the queuing network, and when the process becomes ready again after the I/O, it is inserted at the tail of the same queue, from which it is relinquished earlier. This can happen if a process goes to preform a syscall before the time slice is over, thus a process would always be on the higher level queue and lower process would be kept waiting, although the process would be entered at the end of the queue so ageing process would at sometime be scheduled. A round-robin scheduler should be used for processes at the lowest priority queue.

## Specification 3 Implementation

- Extract the required values from the processes using the already defined values in structs of the processes and print in the procdump function.

## Explain how the given can be exploited by a process

- A process can maintain its priority by surrendering just before it consumes all of the time available, preventing lower-priority processes from continuing.
- On a single CPU, 5 sub processes(all spawn at the same time).

## Tabulate the performances of the scheduling algorithms using the given benchmark program. Include the performance comparison between the default and 3 implemented policies in the README by showing the average waiting and running times for processes

| Scheduler | rtime | wtime |
| :-------: | :---: | :---: |
|   `RR`    |  26   |  125  |
|   `PBS`   |  24   |  126  |
|  `FCFS`   |  60   |  73   |
|  `MLFQ`   |  11   |  122  |

- Because the scheduler needs to perform more effort to pick which process to schedule next, 'MLFQ' has a longer 'wtime.'
- The 'rtime' of 'FCFS' is the highest because the CPU spends less time determining which process to pick up next and instead lets the process perform on its own.
