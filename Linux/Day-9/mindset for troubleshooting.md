# Network Troubleshooting Mentality in DevOps
 
A guide to thinking like a senior DevOps engineer when faced with network issues. Tools are easy to learn — **mindset** is what separates a good engineer from a great one.
 
> "When something breaks, the panic you feel is inversely proportional to the structure of your thinking."
 
---
 
## Table of Contents
 
1. [The Core Mindset](#1-the-core-mindset)
2. [The 5 Golden Rules](#2-the-5-golden-rules)
3. [The OSI Layered Thinking Approach](#3-the-osi-layered-thinking-approach)
4. [The Scientific Method for Troubleshooting](#4-the-scientific-method-for-troubleshooting)
5. [Asking the Right Questions](#5-asking-the-right-questions)
6. [Common Cognitive Traps](#6-common-cognitive-traps)
7. [Working Under Pressure](#7-working-under-pressure)
8. [Communication During Incidents](#8-communication-during-incidents)
9. [Documentation & Post-Mortem Mindset](#9-documentation--post-mortem-mindset)
10. [Growing the Troubleshooting Muscle](#10-growing-the-troubleshooting-muscle)
---
 
## 1. The Core Mindset
 
### Think Like a Detective, Not a Magician
 
A great DevOps engineer doesn't *guess* — they **gather evidence, form hypotheses, and test them**.
 
- **Magician thinking**: "Let me restart the server and hope it works."
- **Detective thinking**: "What changed? What does the data show? What's the most likely cause?"
### Key Principles
 
| Principle | Why It Matters |
|-----------|----------------|
| **Stay calm** | Panic narrows your thinking; calm widens it. |
| **Assume nothing** | "It should work" is not the same as "it works." |
| **Verify, don't assume** | Test every link in the chain. |
| **Reproduce the problem** | A bug you can't reproduce is a bug you can't fix. |
| **Change one thing at a time** | Otherwise you'll never know what fixed it. |
| **Always check logs first** | Logs tell stories — listen to them. |
| **Trust data, not feelings** | "It feels slow" → measure it. |
 
---
 
## 2. The 5 Golden Rules
 
### Rule 1: **What Changed?**
 
> 90% of production issues come from a recent change.
 
When something breaks, ask:
- Was there a deployment?
- Was there a config change?
- Did a certificate expire?
- Did someone update DNS records?
- Did a cron job run?
- Did the cloud provider push an update?
```bash
# Check recent changes
git log --since="2 hours ago"
sudo journalctl --since "1 hour ago"
last -n 20                          # recent logins
sudo ausearch -ts recent            # audit log
```
 
---
 
### Rule 2: **Reproduce Before You Fix**
 
If you can't reproduce it, you're guessing.
 
- Can you trigger it on demand?
- Does it happen for all users or some?
- Does it happen in all regions or one?
- Is it time-based (cron, business hours, midnight UTC)?
> **A fix without reproduction is a wish, not a solution.**
 
---
 
### Rule 3: **Isolate the Variable**
 
Narrow the search space:
 
- **Is it client-side or server-side?** Try from a different machine.
- **Is it DNS or network?** Use IP instead of hostname.
- **Is it the app or the infrastructure?** Test the underlying TCP port.
- **Is it one server or all?** Compare healthy vs unhealthy.
> The skill of debugging is the skill of **bisection** — keep cutting the problem space in half.
 
---
 
### Rule 4: **Bottom Up vs Top Down**
 
Two valid strategies — pick based on the symptom:
 
**Bottom-Up (OSI Layer 1 → 7)**
- Start at physical/network layer.
- Best when: nothing works, full outage.
- Example: "Can't reach anything" → check cable, link, IP, gateway, DNS, app.
**Top-Down (App → Network)**
- Start at the application.
- Best when: one specific thing is broken.
- Example: "Login button broken" → check app logs first.
---
 
### Rule 5: **One Change at a Time**
 
When experimenting:
- Document what you change.
- Change ONE thing.
- Test.
- Revert if it doesn't help.
- Move to the next.
> If you change five things and it works, you'll never know which fix mattered — and the bug will return.
 
---
 
## 3. The OSI Layered Thinking Approach
 
The OSI model isn't theoretical — it's a **mental checklist** that prevents missed steps.
 
```
┌─────────────────────────────────────────────────────────────┐
│  L7  Application   → Is the app logic correct? Logs OK?     │
│  L6  Presentation  → TLS/SSL, encoding, certs                │
│  L5  Session       → Auth, cookies, session state           │
│  L4  Transport     → TCP/UDP, ports, firewall                │
│  L3  Network       → IP, routing, ICMP, subnets             │
│  L2  Data Link     → MAC, ARP, VLAN, switch                  │
│  L1  Physical      → Cable, NIC, link light                 │
└─────────────────────────────────────────────────────────────┘
```
 
### The "Climb the Stack" Question
 
> *At which layer does the problem first appear?*
 
- Can you ping? → L3 works
- Can you connect on port? → L4 works
- Does TLS handshake succeed? → L6 works
- Does the app respond? → L7 works
**The first failing layer is where to focus.**
 
---
 
## 4. The Scientific Method for Troubleshooting
 
Treat every incident like a science experiment.
 
```
1. OBSERVE       → What are the exact symptoms?
2. QUESTION      → Why might this be happening?
3. HYPOTHESIZE   → "I think it's DNS"
4. PREDICT       → "If DNS is down, dig should fail"
5. TEST          → Run `dig`
6. ANALYZE       → Did the result confirm or deny?
7. CONCLUDE      → Fix or form a new hypothesis
```
 
### Example in Action
 
**Symptom:** Users report the app is slow.
 
| Step | Action |
|------|--------|
| Observe | Latency spike at 3 PM, only for European users. |
| Question | Why now? Why Europe? |
| Hypothesize | "EU CDN edge has issues." |
| Predict | "If CDN is bad, direct origin should be fast." |
| Test | `curl -w '%{time_total}' direct-origin.com` from EU |
| Analyze | Origin: 80ms, CDN: 2.5s → CDN issue confirmed |
| Conclude | Failover to backup CDN; open ticket with provider |
 
---
 
## 5. Asking the Right Questions
 
The questions you ask shape the answers you find.
 
### Initial Triage Questions
 
- **Scope**: Who is affected? One user, one team, everyone?
- **Timing**: When did it start? Has it happened before?
- **Frequency**: Constant or intermittent?
- **Environment**: Prod, staging, dev?
- **Last known good state**: When did it last work?
- **Recent changes**: Deploy, config, infrastructure, DNS, certs?
- **Geography**: All regions or specific ones?
- **Severity**: Total outage or degraded?
### Question Patterns That Save Hours
 
| Don't Ask | Ask Instead |
|-----------|-------------|
| "Is it working?" | "What exact error do you see?" |
| "Is the server up?" | "What does `systemctl status` show?" |
| "Did you change anything?" | "Walk me through what you did, in order." |
| "Is it slow?" | "What's the latency in ms?" |
| "Is DNS broken?" | "What does `dig` return vs expected?" |
 
> **Specificity beats speed.** A vague question wastes 10 minutes; a precise one solves the problem.
 
---
 
## 6. Common Cognitive Traps
 
Even experienced engineers fall into these traps. Knowing them is half the defense.
 
### Trap 1: **Confirmation Bias**
Looking only at evidence that supports your theory.
> **Antidote**: Actively look for evidence that *disproves* your hypothesis.
 
### Trap 2: **The "It Worked Yesterday" Fallacy**
Assuming nothing changed because *you* didn't change anything.
> **Antidote**: Something changed somewhere — DNS, certs, cloud provider, dependency, time-based events.
 
### Trap 3: **Tunnel Vision**
Drilling deep into one theory while the real cause is elsewhere.
> **Antidote**: Set a timer — if your theory doesn't pan out in 15 mins, step back and reassess.
 
### Trap 4: **The "Fix-and-Forget"**
Restarting the service fixes the symptom but not the cause.
> **Antidote**: Always ask "WHY did this happen?" after the fire is out.
 
### Trap 5: **Solving the Wrong Problem**
Spending hours on a network issue when it was an app bug.
> **Antidote**: Validate your assumptions early. Ping ≠ HTTPS works.
 
### Trap 6: **Skipping the Basics**
"It can't be DNS" → it's always DNS.
> **Antidote**: Even with 10 years of experience, run through the basics first.
 
### Trap 7: **Hero Mode**
Trying to fix everything alone under pressure.
> **Antidote**: Ask for help early. Two heads catch tunnel vision.
 
---
 
## 7. Working Under Pressure
 
Production is down. Slack is on fire. Your manager is asking for updates every 5 minutes.
 
### The Calm Operator's Playbook
 
**1. Breathe. Literally.**
A 10-second pause before acting prevents 10 hours of cleanup.
 
**2. Stabilize before you investigate.**
- Can you failover?
- Can you roll back?
- Can you scale up to absorb load?
> **Restoring service > finding root cause** (during the incident).
 
**3. Triage like an ER doctor.**
- What's bleeding the worst? Fix that first.
- Can the patient (system) survive while you investigate?
**4. Don't make it worse.**
- Don't run untested commands in prod.
- Don't restart everything in panic.
- Don't delete logs that might be evidence.
**5. Time-box your actions.**
- "I'll spend 15 minutes on this theory, then escalate."
- This prevents tunnel vision and analysis paralysis.
### The 4-Quadrant Decision Matrix
 
```
                     │  Reversible    │  Irreversible
─────────────────────┼────────────────┼──────────────────
  Low Impact         │  Just do it    │  Test first
─────────────────────┼────────────────┼──────────────────
  High Impact        │  Get approval  │  STOP. Think.
                     │  Test in stg   │  Get 2 reviewers.
```
 
---
 
## 8. Communication During Incidents
 
Technical skill is half the job. Communication is the other half.
 
### The Status Update Formula
 
Every status update should answer:
1. **What's broken?** (1 sentence)
2. **What's the impact?** (Who/what is affected)
3. **What are we doing?** (Current action)
4. **What's the ETA?** (Honest estimate, or "investigating")
5. **Next update at:** (Specific time)
**Example:**
> "API latency spiked at 14:30 UTC. EU users seeing 5s+ response times.
> We've failed over to backup CDN; recovery in progress.
> ETA: Full recovery by 15:00 UTC. Next update at 14:50."
 
### Communication Rules
 
- **Over-communicate, don't under-communicate.** Silence breeds panic.
- **Don't speculate publicly.** "We think it's the database" → blame culture.
- **Acknowledge before solving.** "We see it, we're on it" buys you trust.
- **Separate the war room from the broadcast channel.** Engineers fix; comms team updates.
- **Avoid blame language.** "X deployed bad code" → "A recent change introduced a regression."
---
 
## 9. Documentation & Post-Mortem Mindset
 
The incident isn't over when the system is fixed. It's over when you've learned from it.
 
### The Blameless Post-Mortem
 
Focus on **systems**, not **people**.
 
- ❌ "Alice pushed broken code"
- ✅ "Our pre-deploy tests didn't catch this class of bug"
### What to Document
 
| Section | Content |
|---------|---------|
| **Summary** | One-paragraph overview |
| **Timeline** | Minute-by-minute, all timestamps in UTC |
| **Impact** | Users affected, revenue, SLA impact |
| **Root Cause** | The actual cause (not just symptom) |
| **Resolution** | What fixed it |
| **Lessons Learned** | What we'd do differently |
| **Action Items** | With owners and due dates |
 
### The "Five Whys" Technique
 
Keep asking "why" until you hit the real cause.
 
> The website went down.
> **Why?** Load balancer rejected all traffic.
> **Why?** Health checks all failed.
> **Why?** Backend returned 503.
> **Why?** Database connection pool exhausted.
> **Why?** A new feature opened connections without releasing them.
>
> **Root cause:** Connection leak in feature X.
> **Action item:** Add connection pool monitoring + linter rule.
 
---
 
## 10. Growing the Troubleshooting Muscle
 
Troubleshooting is a skill, and like any skill, it improves with deliberate practice.
 
### Habits of Senior Engineers
 
1. **Read post-mortems** — even from other companies (Gitlab, Cloudflare, AWS publish them).
2. **Break things on purpose** in lab/dev environments (chaos engineering at home).
3. **Build a personal runbook** of every issue you've solved.
4. **Learn your tools deeply** — `tcpdump`, `dig`, `ss`, `strace` reward mastery.
5. **Pair-debug** with senior engineers — absorb their thinking patterns.
6. **Practice on Linux at every layer** — from kernel netstack to HTTP.
7. **Subscribe to status pages** of cloud providers — learn how big outages unfold.
### The Learning Loop
 
```
Encounter problem → Solve it → Document it → Share it → Internalize it
```
 
Each cycle makes the next one faster.
 
### Books / Resources Worth Studying
 
- *Site Reliability Engineering* (Google) — the SRE bible
- *The Phoenix Project* — DevOps culture in narrative form
- *TCP/IP Illustrated, Volume 1* — for deep network understanding
- *Linux Performance* (Brendan Gregg) — system-level diagnostics
- Cloudflare, GitHub, AWS, GitLab post-mortems — real-world case studies
---
 
## The Troubleshooter's Creed
 
> 1. I will stay calm.
> 2. I will trust data, not feelings.
> 3. I will reproduce before I fix.
> 4. I will change one thing at a time.
> 5. I will ask "what changed?" first.
> 6. I will check the basics, even when I'm sure it's not them.
> 7. I will document what I learn.
> 8. I will communicate honestly and often.
> 9. I will fix the cause, not just the symptom.
> 10. I will not blame people — I will fix systems.
 
---
 
## Decision Flowchart: "Something Is Broken"
 
```
                       SOMETHING IS BROKEN
                              │
                              ▼
                    ┌──────────────────┐
                    │ Is it critical?  │
                    └──────────────────┘
                       │            │
                  YES  │            │  NO
                       ▼            ▼
              ┌────────────┐   ┌────────────┐
              │ Stabilize  │   │ Investigate│
              │ (failover/ │   │ thoroughly │
              │  rollback) │   │            │
              └─────┬──────┘   └─────┬──────┘
                    │                │
                    ▼                ▼
              ┌──────────────────────────┐
              │  What changed recently?  │
              └──────────────┬───────────┘
                             │
                             ▼
              ┌──────────────────────────┐
              │  Reproduce the problem   │
              └──────────────┬───────────┘
                             │
                             ▼
              ┌──────────────────────────┐
              │ Isolate (bottom-up or    │
              │ top-down, OSI layers)    │
              └──────────────┬───────────┘
                             │
                             ▼
              ┌──────────────────────────┐
              │ Hypothesize → Test →     │
              │ Analyze → Repeat         │
              └──────────────┬───────────┘
                             │
                             ▼
              ┌──────────────────────────┐
              │ Fix root cause           │
              │ (not just symptom)       │
              └──────────────┬───────────┘
                             │
                             ▼
              ┌──────────────────────────┐
              │ Document & post-mortem   │
              └──────────────────────────┘
```
 
---
 
## Final Wisdom
 
> **Tools change. Cloud providers change. Languages change.**
> **The mindset is permanent.**
 
A great DevOps engineer is recognized not by how many commands they know, but by:
 
- **How calmly** they handle a 3 AM page
- **How methodically** they narrow down a problem
- **How honestly** they communicate during incidents
- **How thoroughly** they learn from every failure
- **How generously** they share that knowledge with the team
> "It's not the tools in your hand that matter — it's the way you think with them."
 
---