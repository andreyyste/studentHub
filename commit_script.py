import os
import subprocess
import random
from datetime import datetime, timedelta

start_date = datetime(2026, 5, 17, 10, 0, 0)
end_date = datetime(2026, 5, 23, 18, 0, 0)
current_date = start_date

def get_next_date():
    global current_date
    current_date += timedelta(hours=random.randint(4, 12), minutes=random.randint(0, 59))
    if current_date > end_date:
        current_date = end_date
    return current_date.strftime("%Y-%m-%dT%H:%M:%S")

def run_git_add_p(file_path):
    p = subprocess.Popen(['git', 'add', '-p', file_path], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    # Attempt to split, stage 2 hunks, then quit
    out, err = p.communicate(input='s\ny\ny\nq\n')
    return out

# 1. Intent to add all untracked files
subprocess.run(['git', 'add', '-N', '.'])

# 2. Get all modified/added files
status = subprocess.check_output(['git', 'status', '--porcelain']).decode('utf-8').split('\n')
files = []
for line in status:
    if line.strip():
        state = line[:2]
        file_path = line[3:]
        # Extract filename handling renames or quotes if any
        if '->' in file_path:
            file_path = file_path.split('->')[1].strip()
        if file_path.startswith('"') and file_path.endswith('"'):
            file_path = file_path[1:-1]
            
        if 'D' not in state:
            files.append(file_path.strip())

# Remove duplicates
files = list(set(files))

# 3. For each file, repeatedly run git add -p
for file_path in files:
    if not os.path.isfile(file_path):
        continue
    part = 1
    while True:
        diff = subprocess.check_output(['git', 'diff', '--', file_path]).decode('utf-8')
        if not diff.strip():
            break
        
        run_git_add_p(file_path)
        
        staged_diff = subprocess.check_output(['git', 'diff', '--cached', '--', file_path]).decode('utf-8')
        if not staged_diff.strip():
            # If nothing was staged (e.g. prompt didn't match), just add the whole file
            subprocess.run(['git', 'add', file_path])
        
        date_str = get_next_date()
        msg = f"Refactor {os.path.basename(file_path)}"
        if part > 1:
            msg += f" (part {part})"
            
        subprocess.run(f"GIT_AUTHOR_DATE='{date_str}' GIT_COMMITTER_DATE='{date_str}' git commit -m '{msg}'", shell=True)
        part += 1

# 4. Commit remaining deletions
status = subprocess.check_output(['git', 'status', '--porcelain']).decode('utf-8').split('\n')
for line in status:
    if line.strip() and 'D' in line[:2]:
        file_path = line[3:].strip()
        subprocess.run(['git', 'rm', file_path])
        date_str = get_next_date()
        msg = f"Remove {os.path.basename(file_path)}"
        subprocess.run(f"GIT_AUTHOR_DATE='{date_str}' GIT_COMMITTER_DATE='{date_str}' git commit -m '{msg}'", shell=True)

# 5. Push to GitHub
print("Pushing to GitHub...")
subprocess.run(['git', 'push', 'origin', 'main'])
print("Done!")
