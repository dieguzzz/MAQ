---
description: Load MetroPTY project context from Obsidian vault to reduce token usage
---

# /context — Load Project Context

This workflow loads the structured context from the `.context/` Obsidian vault
instead of re-exploring the codebase from scratch.

## Steps

### 1. Load Quick Context (always)

// turbo
Read the main index for a quick overview:

```
view_file .context/00-INDEX.md
```

### 2. Load Architecture overview (if working on code changes)

// turbo

```
view_file .context/architecture/best-practices.md
```

### 3. Load relevant MOC based on the task

**If working with models:**
// turbo

```
view_file .context/models/_MOC.md
```

**If working with services:**
// turbo

```
view_file .context/services/_MOC.md
```

**If working with Firebase:**
// turbo

```
view_file .context/firebase/collections.md
view_file .context/firebase/cloud-functions.md
```

**If working with features/UI:**
// turbo

```
view_file .context/features/all-features.md
```

### 4. Load State (if needed)

// turbo

```
view_file .context/state/current-status.md
```

### 5. Load specific notes as needed

Based on the MOC, read only the specific notes relevant to the current task.
For example, if working on reports:

```
view_file .context/models/report-models.md
```

## Tips

- Start with step 1 ALWAYS
- Only read what you need for the current task
- If context is missing, add new notes to `.context/` for future conversations
- Update `state/current-status.md` when completing major work
