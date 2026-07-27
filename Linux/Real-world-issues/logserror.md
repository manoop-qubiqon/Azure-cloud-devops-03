#####################
May  4 10:08:45 server app[23111]: INFO Starting batch processing job id=7781
May  4 10:09:02 server app[23111]: INFO Loading dataset into memory (size=1.2GB)
May  4 10:09:10 server kernel: Memory pressure detected: usage at 78%
May  4 10:09:25 server kernel: Memory pressure detected: usage at 85%
May  4 10:09:40 server kernel: Memory pressure detected: usage at 91%
May  4 10:09:55 server kernel: kswapd0: reclaiming memory...
May  4 10:10:01 server kernel: kswapd0: page allocation failure: order:0, mode:0x14000c0(GFP_KERNEL)
May  4 10:10:01 server kernel: CPU: 1 PID: 1023 Comm: kswapd0 Not tainted
May  4 10:10:02 server kernel: Node 0 Normal free:2048kB min:4096kB low:8192kB high:12288kB
May  4 10:10:05 server kernel: Tasks state (memory values in pages):
May  4 10:10:05 server kernel: [  pid  ]   uid  tgid total_vm      rss pgtables_bytes swapents oom_score_adj name
May  4 10:10:05 server kernel: [ 23111]  1000 23111  3000000  2500000   45000        0             0 python
May  4 10:10:05 server kernel: [ 19872]  1000 19872  1500000  1200000   22000        0             0 java
May  4 10:10:05 server kernel: [ 11234]     0 11234   250000   150000   12000        0         -1000 systemd
May  4 10:10:10 server kernel: oom-kill:constraint=CONSTRAINT_NONE,nodemask=(null),cpuset=/,mems_allowed=0
May  4 10:10:10 server kernel: Out of memory: Kill process 23111 (python) score 987 or sacrifice child
May  4 10:10:10 server kernel: Killed process 23111 (python) total-vm:12000000kB, anon-rss:9800000kB, file-rss:1024kB, shmem-rss:0kB
May  4 10:10:10 server kernel: oom_reaper: reaped process 23111 (python), now anon-rss:0kB

May  4 10:12:01 server kernel: [10234.567890] python invoked oom-killer: gfp_mask=0x14000c0(GFP_KERNEL), order=0, oom_score_adj=0
May  4 10:12:01 server kernel: [10234.567891] CPU: 2 PID: 24567 Comm: python Not tainted 5.15.0-91-generic #101-Ubuntu
May  4 10:12:01 server kernel: [10234.567892] Hardware name: VMware Virtual Platform
May  4 10:12:01 server kernel: [10234.567893] Call Trace:
May  4 10:12:01 server kernel: [10234.567894]  dump_stack+0x6d/0x8b
May  4 10:12:01 server kernel: [10234.567895]  oom_kill_process.cold+0xb/0x10
May  4 10:12:01 server kernel: [10234.567896]  out_of_memory+0x1f5/0x500
May  4 10:12:01 server kernel: [10234.567897]  __alloc_pages_slowpath.constprop.0+0x9c5/0xb40
May  4 10:12:01 server kernel: [10234.567898] Mem-Info:
May  4 10:12:01 server kernel: [10234.567899] active_anon:2048000 inactive_anon:1024000 isolated_anon:0
May  4 10:12:01 server kernel: [10234.567900] free:1024kB min:2048kB low:4096kB high:8192kB
May  4 10:12:01 server kernel: [10234.567901] Node 0 Normal free:1024kB min:2048kB low:4096kB high:8192kB
May  4 10:12:01 server kernel: [10234.567902] Out of memory: Killed process 24567 (python) total-vm:4096000kB, anon-rss:3500000kB, file-rss:0kB, shmem-rss:0kB
May  4 10:12:01 server kernel: [10234.567903] oom_reaper: reaped process 24567 (python), now anon-rss:0kB

May  4 10:12:02 server systemd[1]: app.service: Main process exited, code=killed, status=9/KILL
May  4 10:12:02 server systemd[1]: app.service: Failed with result 'signal'.
May  4 10:12:02 server systemd[1]: app.service: Scheduled restart job, restart counter is at 3.
May  4 10:12:02 server systemd[1]: Stopped Application Service.
May  4 10:12:02 server systemd[1]: Started Application Service.

May  4 10:12:05 server app[24601]: ERROR Failed to allocate memory buffer
May  4 10:12:06 server app[24601]: WARNING Retrying operation after memory allocation failure
May  4 10:12:10 server app[24601]: ERROR Out of memory while processing request id=8821
May  4 10:12:15 server kernel: Memory pressure detected: usage at 96%
May  4 10:12:20 server kernel: kswapd0: reclaiming memory...
May  4 10:12:25 server app[24601]: INFO Restarted successfully
May  4 10:12:30 server app[24601]: INFO Processing resumed

May  4 10:13:01 server nginx: 502 Bad Gateway upstream timed out
May  4 10:13:02 server nginx: upstream prematurely closed connection
May  4 10:13:05 server app[24601]: ERROR Request failed due to backend crash
May  4 10:13:10 server app[24601]: INFO Health check failed
May  4 10:13:15 server app[24601]: INFO Attempting recovery


#############################

Scenario:

A production application is crashing intermittently. Users are reporting downtime and failed requests.

You have been provided with a log file: app_issue.log

Your task is to analyze the logs and identify the root cause of the issue.

Use Linux commands to investigate and answer the following questions.


### copy this log in your own vm and troubleshoot with this log.





###
What is the main issue observed in the logs?
Which process is causing the problem?
What is the PID of the affected process?
What message indicates the system ran out of memory?
Were there any warning signs before the failure? If yes, mention them.
What was the memory condition of the system at the time of failure?
How much memory was the process consuming (approx)?
Which component restarted after the failure?
Why did the system kill that specific process?
What is the role of the OOM killer in Linux?
What impact did this issue have on other services (e.g., web server)?
Is this a one-time issue or a recurring problem? Justify your answer from logs.
What are possible root causes of this issue? (list at least 3)
How would you prevent this issue in production?
What monitoring or alerting would you implement?
###


