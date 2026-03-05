---
description: Auto-update the .context/ Obsidian vault after completing work or before commits
---

# /update-context — Actualizar el Vault de Contexto

// turbo-all

This workflow updates the `.context/` vault after completing a module, feature, or significant change.

## When to run

- After completing a module or feature
- Before doing a commit
- After refactoring significant code
- After adding/removing services, models, or providers

## Steps

### 1. Check what changed

Identify which areas of the codebase were modified in this session.

### 2. Update state/current-status.md

Update the ✅/⚠️/❌ status if any feature changed status:

```
view_file c:\Users\Diegu\MAQ\.context\state\current-status.md
```

Then edit `current-status.md` with the new status.

### 3. Update relevant MOCs if files were added/removed

If new services, models, providers, or screens were added/deleted:

- Update `services/_MOC.md`
- Update `models/_MOC.md`
- Update `providers/_MOC.md`
- Update `features/all-features.md`

### 4. Update model notes if schemas changed

If model fields changed:

- Update the corresponding note in `models/`
- Verify Firestore field mapping is still accurate

### 5. Update best-practices.md if new patterns emerged

If new conventions or patterns were introduced:

```
view_file c:\Users\Diegu\MAQ\.context\architecture\best-practices.md
```

Add the new patterns/rules.

### 6. Update known-issues.md if bugs were fixed or found

```
view_file c:\Users\Diegu\MAQ\.context\state\known-issues.md
```

### 7. Update pending-work.md if tasks were completed

Mark completed items and add new ones:

```
view_file c:\Users\Diegu\MAQ\.context\state\pending-work.md
```

### 8. Update last-updated dates

Change the `last-updated` frontmatter field on every modified note to today's date.

### 9. Confirm

Report what was updated in the vault.
