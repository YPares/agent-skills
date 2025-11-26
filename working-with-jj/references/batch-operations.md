# Batch Operations on Multiple Revisions

## Problem

When you need to update descriptions for multiple revisions (e.g., replacing line number references with labels), bash syntax and piping can be tricky.

## Anti-Pattern

```bash
# ❌ This will fail with syntax errors
for rev in unxn mktt stnq; do
  jj log -r $rev | sed 's/L123/label/' | jj desc -r $rev --stdin
done

# Issues:
# 1. Missing -n1 --no-graph -T description (gets full log output)
# 2. Unquoted variables ($rev) can break with special chars
# 3. Complex pipes in one-liners are fragile
```

## Pattern 1: Intermediate Files (Recommended)

```bash
# ✅ Robust pattern using temporary files
for rev in unxn mktt stnq rwyq roww; do
  # Extract description to file
  jj log -r "$rev" -n1 --no-graph -T description > /tmp/desc_${rev}_old.txt

  # Transform using sed/awk/etc
  sed -f /tmp/replacements.sed /tmp/desc_${rev}_old.txt > /tmp/desc_${rev}_new.txt

  # Apply back to revision
  jj desc -r "$rev" --stdin < /tmp/desc_${rev}_new.txt
done

echo "✅ All descriptions updated"
```

**Benefits:**
- Each step is visible and debuggable
- Can inspect intermediate files if something goes wrong
- Easy to retry individual revisions
- Works with complex transformations

## Pattern 2: One Command at a Time

```bash
# ✅ Alternative: Sequential approach
jj log -r unxn -n1 --no-graph -T description | \
  sed 's/L123/@label/' > /tmp/desc_unxn.txt
jj desc -r unxn --stdin < /tmp/desc_unxn.txt

jj log -r mktt -n1 --no-graph -T description | \
  sed 's/L123/@label/' > /tmp/desc_mktt.txt
jj desc -r mktt --stdin < /tmp/desc_mktt.txt

# etc.
```

**Benefits:**
- Even more explicit
- Easy to stop/resume
- Perfect for copy-paste execution

## Pattern 3: Using sed Script File

```bash
# Create reusable sed script
cat > /tmp/replacements.sed << 'EOF'
s/L596-617/@types-de-cartes/g
s/L1242-1253/@carte-eglise/g
s/L659-665/@couts-marche/g
EOF

# Apply to all revisions
for rev in unxn mktt stnq; do
  jj log -r "$rev" -n1 --no-graph -T description | \
    sed -f /tmp/replacements.sed | \
    jj desc -r "$rev" --stdin
done
```

**Benefits:**
- Reusable transformation logic
- Easy to test sed script independently
- Cleaner loop body

## Common Mistakes

### 1. Missing Template Specification

```bash
# ❌ Wrong: gets formatted log output
jj log -r xyz | sed 's/old/new/'

# ✅ Correct: extract just description
jj log -r xyz -n1 --no-graph -T description | sed 's/old/new/'
```

### 2. Unquoted Variables

```bash
# ❌ Breaks with special characters in rev names
for rev in a b c; do
  jj log -r $rev  # Unquoted
done

# ✅ Always quote
for rev in a b c; do
  jj log -r "$rev"  # Quoted
done
```

### 3. Fragile One-Liners

```bash
# ❌ Hard to debug, fragile
for rev in a b c; do jj log -r $rev -n1 --no-graph -T description | sed 's/x/y/' | jj desc -r $rev --stdin; done

# ✅ Readable, debuggable
for rev in a b c; do
  jj log -r "$rev" -n1 --no-graph -T description | \
    sed 's/x/y/' > /tmp/desc_${rev}.txt
  jj desc -r "$rev" --stdin < /tmp/desc_${rev}.txt
done
```

## Real-World Example

Replacing all line number references with Typst labels across 10 revisions:

```bash
# 1. Create sed replacement script
cat > /tmp/sed_replacements.txt << 'EOF'
s/5F\.typ L596-617/5F.typ @types-de-cartes/g
s/5F\.typ L1242-1253/5F.typ @carte-eglise-en-pierre/g
s/5F\.typ L659-665/5F.typ @couts-marche/g
# ... etc
EOF

# 2. Process each revision
for rev in unxn mktt stnq rwyq roww wltq syun zkru mszz ovrv; do
  jj log -r "$rev" -n1 --no-graph -T description | \
    sed -f /tmp/sed_replacements.txt > "/tmp/desc_${rev}_new.txt"
  jj desc -r "$rev" --stdin < "/tmp/desc_${rev}_new.txt"
done

# 3. Verify one result
jj log -r mktt -n1 --no-graph -T description | head -5
```

## Verification

Always verify the results after batch operations:

```bash
# Quick check: first line of each description
for rev in unxn mktt stnq; do
  echo "=== $rev ==="
  jj log -r "$rev" -n1 --no-graph -T description | head -3
done

# Or use jj log with custom template
jj log -r 'unxn | mktt | stnq' -T 'change_id.shortest(4) ++ " " ++ description.first_line() ++ "\n"'
```
