## What

<!-- Bullet-point summary of what changed. Stay factual; reasoning goes under "Why". -->
- 

## Why

<!-- The motivation: what problem this solves, and why this approach over alternatives. -->


<!-- If this PR resolves a tracked issue, link it here, e.g.: -->
<!-- Closes #19 -->

## Checklist

### Required

- [ ] `lute run ./scripts/checker.luau -- ./src ./tests ./scripts` passes
- [ ] `lute run ./scripts/tester.luau` passes
- [ ] I linked the related issue if one exists (for example: `Closes #19`)

### Functional Validation

- [ ] Tests cover the changed behavior (`.spec.luau` and/or `.check.luau` added or updated)
- [ ] Both happy and edge paths verified where applicable

### Configuration & Docs

- [ ] User-facing docs were updated where applicable (`README.md` / `README.ko.md` / `CLAUDE.md`)
- [ ] New dependencies / configuration are reflected in `pesde.toml` / `mise.toml`
- [ ] No sensitive values or credentials were introduced

### If Applicable

- [ ] Breaking type-surface or API changes are clearly described in this PR
