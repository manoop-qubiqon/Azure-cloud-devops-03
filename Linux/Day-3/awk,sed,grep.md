# grep, sed, and awk — The Text-Processing Trio
 
A practical guide to Linux's three most powerful text-processing tools, with examples and real-world use cases.
 
---
 
## Quick Comparison
 
| Tool | Best For | Strength |
|---|---|---|
| **`grep`** | Searching | Find lines that match a pattern |
| **`sed`** | Editing | Substitute, insert, or delete text in a stream |
| **`awk`** | Analyzing | Process columns, do math, format reports |
 
**Rule of thumb:**
- Need to *find* something? → `grep`
- Need to *change* something? → `sed`
- Need to *compute or format* something? → `awk`
---
 
## Sample File for Examples
 
We'll use a file called `employees.txt` for the examples below:
 
```
ID,Name,Department,Salary
101,Alice,Engineering,75000
102,Bob,Marketing,55000
103,Charlie,Engineering,82000
104,Diana,HR,48000
105,Eve,Engineering,91000
106,Frank,Marketing,52000
```
 
---
 
# 1. grep — Pattern Searching
 
`grep` (Global Regular Expression Print) searches text for lines matching a pattern.
 
### Basic syntax
 
```bash
grep "pattern" file
```
 
---
 
## Common grep Examples
 
### Simple search
 
```bash
grep "Engineering" employees.txt
```
 
Output:
```
101,Alice,Engineering,75000
103,Charlie,Engineering,82000
105,Eve,Engineering,91000
```
 
### Case-insensitive search (`-i`)
 
```bash
grep -i "alice" employees.txt
```
 
### Show line numbers (`-n`)
 
```bash
grep -n "Marketing" employees.txt
```
 
Output:
```
3:102,Bob,Marketing,55000
7:106,Frank,Marketing,52000
```
 
### Count matches (`-c`)
 
```bash
grep -c "Engineering" employees.txt
# Output: 3
```
 
### Invert match — lines that DON'T match (`-v`)
 
```bash
grep -v "Engineering" employees.txt
```
 
### Match whole words only (`-w`)
 
```bash
grep -w "HR" employees.txt
# matches "HR" but not "HRD" or "HR-team"
```
 
### Recursive search through directories (`-r`)
 
```bash
grep -r "TODO" /home/alice/projects/
```
 
### Show files that match (`-l`) or don't match (`-L`)
 
```bash
grep -l "ERROR" *.log         # filenames containing ERROR
grep -L "ERROR" *.log         # filenames NOT containing ERROR
```
 
### Show only the matching part (`-o`)
 
```bash
grep -oE "[0-9]+" employees.txt
# extracts all numbers
```
 
### Show context around matches (`-A`, `-B`, `-C`)
 
```bash
grep -A 2 "ERROR" app.log     # 2 lines After
grep -B 2 "ERROR" app.log     # 2 lines Before
grep -C 2 "ERROR" app.log     # 2 lines of Context (both sides)
```
 
### Extended regex (`-E` or `egrep`)
 
```bash
grep -E "Alice|Bob" employees.txt
grep -E "^[0-9]{3}," employees.txt    # lines starting with 3-digit ID
```
 
### Perl-compatible regex (`-P`)
 
```bash
grep -P "\d{5}" employees.txt    # any 5-digit number
```
 
### Multiple patterns
 
```bash
grep -e "Alice" -e "Bob" employees.txt
```
 
**Use cases:**
- Searching log files for errors: `grep -i error /var/log/syslog`
- Finding TODO comments in code: `grep -rn "TODO" src/`
- Filtering `ps` output: `ps aux | grep nginx`
- Checking config files: `grep -v "^#" config.conf | grep -v "^$"` (strip comments + blank lines)
---
 
# 2. sed — Stream Editor
 
`sed` reads text line by line and applies editing commands. It's most often used for **substitutions**.
 
### Basic syntax
 
```bash
sed 'command' file
```
 
---
 
## Common sed Examples
 
### Substitute (the most common use)
 
```bash
# Replace first occurrence per line
sed 's/Engineering/Tech/' employees.txt
 
# Replace ALL occurrences (global flag /g)
sed 's/Engineering/Tech/g' employees.txt
 
# Case-insensitive substitution
sed 's/engineering/Tech/gi' employees.txt
```
 
### Edit the file in place (`-i`)
 
```bash
sed -i 's/Engineering/Tech/g' employees.txt
 
# Safer: keep a backup with .bak extension
sed -i.bak 's/Engineering/Tech/g' employees.txt
```
 
> ⚠️ **Always test without `-i` first** — `sed -i` overwrites your file immediately.
 
### Use a different delimiter (helpful for paths)
 
```bash
# Instead of escaping every / in a path:
sed 's|/home/alice|/home/bob|g' config.txt
```
 
### Print only specific lines (`-n` + `p`)
 
```bash
sed -n '3p' employees.txt              # print only line 3
sed -n '2,5p' employees.txt            # print lines 2 through 5
sed -n '/Engineering/p' employees.txt  # print lines matching pattern
```
 
### Delete lines (`d`)
 
```bash
sed '1d' employees.txt                 # delete the header (line 1)
sed '2,4d' employees.txt               # delete lines 2 through 4
sed '/Marketing/d' employees.txt       # delete lines matching pattern
sed '/^$/d' file.txt                   # delete blank lines
sed '/^#/d' config.conf                # delete comment lines
```
 
### Insert and append lines
 
```bash
# Insert before line 2
sed '2i\New line inserted before line 2' employees.txt
 
# Append after line 2
sed '2a\New line appended after line 2' employees.txt
```
 
### Replace text on specific lines only
 
```bash
sed '3 s/Bob/Robert/' employees.txt          # only on line 3
sed '/Engineering/ s/0/X/g' employees.txt    # only on matching lines
```
 
### Multiple commands (`-e`)
 
```bash
sed -e 's/Engineering/Tech/g' -e 's/Marketing/Sales/g' employees.txt
```
 
### Print line numbers
 
```bash
sed = employees.txt | sed 'N; s/\n/\t/'
```
 
**Use cases:**
- Bulk find-and-replace across files: `sed -i 's/old_api/new_api/g' *.js`
- Removing comments and blank lines from configs
- Anonymizing data: `sed -i 's/[0-9]\{4\}/XXXX/g' data.txt`
- Quick header changes in CSVs
---
 
# 3. awk — Pattern Scanning and Processing
 
`awk` treats input as **records** (lines) split into **fields** (columns). It's perfect for working with structured data like CSVs and logs.
 
### Basic syntax
 
```bash
awk 'pattern { action }' file
```
 
### Built-in variables
 
| Variable | Meaning |
|---|---|
| `$0` | The whole line |
| `$1`, `$2`, `$3` | First, second, third field |
| `$NF` | Last field |
| `NR` | Current record (line) number |
| `NF` | Number of fields in the current line |
| `FS` | Field separator (input) |
| `OFS` | Output field separator |
 
---
 
## Common awk Examples
 
### Print specific columns
 
```bash
# Default separator is whitespace
awk '{print $1}' file.txt
 
# Use comma as separator with -F
awk -F',' '{print $2}' employees.txt
```
 
Output:
```
Name
Alice
Bob
Charlie
Diana
Eve
Frank
```
 
### Print multiple columns
 
```bash
awk -F',' '{print $2, $4}' employees.txt
```
 
Output:
```
Name Salary
Alice 75000
Bob 55000
...
```
 
### Print with custom formatting
 
```bash
awk -F',' '{print "Name: " $2 " | Dept: " $3}' employees.txt
```
 
### Skip the header (`NR > 1`)
 
```bash
awk -F',' 'NR > 1 {print $2, $4}' employees.txt
```
 
### Filter rows by condition
 
```bash
# Salary greater than 60000
awk -F',' 'NR > 1 && $4 > 60000 {print $2, $4}' employees.txt
 
# Only Engineering department
awk -F',' '$3 == "Engineering" {print $2, $4}' employees.txt
 
# Pattern match (regex)
awk -F',' '/Engineering/ {print $2}' employees.txt
```
 
### BEGIN and END blocks
 
```bash
awk -F',' '
BEGIN { print "=== Salary Report ===" }
NR > 1 { print $2 ": $" $4 }
END   { print "=== End of Report ===" }
' employees.txt
```
 
### Sum a column
 
```bash
awk -F',' 'NR > 1 {sum += $4} END {print "Total:", sum}' employees.txt
# Output: Total: 403000
```
 
### Average a column
 
```bash
awk -F',' 'NR > 1 {sum += $4; count++} END {print "Average:", sum/count}' employees.txt
```
 
### Find max / min
 
```bash
awk -F',' 'NR > 1 && $4 > max {max = $4; name = $2} END {print "Highest paid:", name, max}' employees.txt
```
 
### Count records by group
 
```bash
awk -F',' 'NR > 1 {count[$3]++} END {for (dept in count) print dept, count[dept]}' employees.txt
```
 
Output:
```
Engineering 3
Marketing 2
HR 1
```
 
### Formatted output with `printf`
 
```bash
awk -F',' 'NR > 1 {printf "%-10s %8d\n", $2, $4}' employees.txt
```
 
Output:
```
Alice         75000
Bob           55000
Charlie       82000
...
```
 
### Change the output field separator
 
```bash
awk -F',' 'BEGIN {OFS=" | "} NR > 1 {print $2, $3, $4}' employees.txt
```
 
Output:
```
Alice | Engineering | 75000
Bob | Marketing | 55000
...
```
 
**Use cases:**
- CSV/TSV analysis without Excel
- Summarizing log files (count requests per IP, total bytes transferred)
- Quick reports from `ps`, `df`, `du`, `netstat` output
- Extracting and reformatting columns from any tabular data
---
 
# 4. Combining grep, sed, and awk
 
The real power comes from chaining them with pipes (`|`).
 
### Find error lines, extract timestamp and message
 
```bash
grep "ERROR" app.log | awk '{print $1, $2, $5}'
```
 
### Replace text and then filter
 
```bash
sed 's/WARN/WARNING/g' app.log | grep "WARNING"
```
 
### Count unique IPs in an Nginx access log
 
```bash
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head
```
 
### Sum the salary of all Engineering employees
 
```bash
grep "Engineering" employees.txt | awk -F',' '{sum += $4} END {print sum}'
# Output: 248000
```
 
### Strip comments and blank lines from a config, then save
 
```bash
grep -v "^#" httpd.conf | grep -v "^$" > httpd-clean.conf
```
 
### Find top 10 most memory-hungry processes
 
```bash
ps aux | awk 'NR > 1 {print $4, $11}' | sort -rn | head -10
```
 
### Replace IPs in a log with `XXX.XXX.XXX.XXX` for sharing
 
```bash
sed -E 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/XXX.XXX.XXX.XXX/g' access.log
```
 
---
 
## Quick Reference
 
| Task | Command |
|---|---|
| Search for pattern | `grep "pattern" file` |
| Case-insensitive search | `grep -i "pattern" file` |
| Search recursively | `grep -r "pattern" dir/` |
| Show line numbers | `grep -n "pattern" file` |
| Invert match | `grep -v "pattern" file` |
| Show context | `grep -C 3 "pattern" file` |
| Replace text | `sed 's/old/new/g' file` |
| Replace in place | `sed -i 's/old/new/g' file` |
| Delete lines | `sed '/pattern/d' file` |
| Print line range | `sed -n '5,10p' file` |
| Print column | `awk '{print $2}' file` |
| Print with separator | `awk -F',' '{print $2}' file` |
| Sum column | `awk '{s+=$1} END {print s}' file` |
| Filter rows | `awk '$3 > 100' file` |
| Group and count | `awk '{c[$1]++} END {for (k in c) print k, c[k]}' file` |
 
---