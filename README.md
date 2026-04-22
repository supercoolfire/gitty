## 🛠️ Fixing Leaked / Bad Commits (Flow Guide)

### 1. Identify your situation

- **A. Last commit only (not pushed)** → go to Step 2  
- **B. Specific commit (not latest)** → go to Step 3  
- **C. Sensitive file across history** → go to Step 4  

---

### 2. Remove last commit
```bash
git reset --hard HEAD~1
```
➡ Done → go to Step 6

---

### 3. Remove specific commit
```bash
git rebase -i <commit-before-bad>
```
- Change `pick` → `drop`

➡ Done → go to Step 6

---

### 4. Remove sensitive file everywhere
```bash
git filter-repo --path .env --invert-paths
```

➡ Done → go to Step 6

---

### 5. 🚨 ONLY if something went wrong (Recovery)

Use this **only if you broke something**:

```bash
git reflog
```

- Find the commit **before you started editing history**

```bash
git reset --hard <commit_hash>
git push --force
```

➡ Back to safe state

---

### 6. Push changes
```bash
git push origin main --force
```

---

### 7. Reset broken working state (optional)

If things look weird locally:
```bash
git reset --hard
```

---

## 🧠 Key Idea (for future you)

- Steps **2–4 = action**
- Step **5 = panic button**
- Step **6 = finalize**
