#!/usr/bin/env bash

# Create an isolated, dependency-free Agentennetzwerk coding benchmark.
# The generated project intentionally starts with failing tests.

set -eu

SCENARIO="${1:-}"
DEST="${2:-}"

case "$SCENARIO" in
  quick|standard|deep) ;;
  *)
    echo "usage: eval-fixture.sh <quick|standard|deep> [destination]" >&2
    exit 2
    ;;
esac

if [ -z "$DEST" ]; then
  BASE="${TMPDIR:-/tmp}"
  DEST="$BASE/agentennetzwerk-eval-${SCENARIO}-$(date +%s)-$$"
fi

mkdir -p "$DEST/src" "$DEST/test"

cat > "$DEST/package.json" <<'EOF'
{
  "name": "agentennetzwerk-eval-fixture",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF

case "$SCENARIO" in
  quick)
    cat > "$DEST/TASK.md" <<'EOF'
# Quick benchmark task

Fix `normalizeTag` in `src/normalize.js`.

Acceptance criteria:
- trim leading/trailing whitespace
- lowercase the result
- treat one or more spaces or underscores as a single `-`
- collapse repeated `-`
- remove a leading or trailing `-`
- do not change the tests, package.json, or TASK.md
- keep the patch local and dependency-free
EOF
    cat > "$DEST/src/normalize.js" <<'EOF'
export function normalizeTag(value) {
  return String(value).trim().toLowerCase().replace(/\s+/g, "-");
}
EOF
    cat > "$DEST/test/normalize.test.js" <<'EOF'
import test from "node:test";
import assert from "node:assert/strict";
import { normalizeTag } from "../src/normalize.js";

test("normalizes spaces and case", () => {
  assert.equal(normalizeTag("  Hello World  "), "hello-world");
});

test("treats underscores and repeated separators uniformly", () => {
  assert.equal(normalizeTag("__Hello__  World---Again__"), "hello-world-again");
});

test("removes edge separators", () => {
  assert.equal(normalizeTag("---alpha---"), "alpha");
});
EOF
    ;;

  standard)
    cat > "$DEST/TASK.md" <<'EOF'
# Standard benchmark task

Implement safe configuration merging in `src/config.js`.

Acceptance criteria:
- `mergeConfig(defaults, user)` returns a new object and never mutates either input
- top-level unknown user keys are preserved
- the known nested objects `sync` and `ui` are merged one level deep instead of being replaced wholesale
- arrays and primitive values replace the default value normally
- `null` or `undefined` user config behaves like an empty object
- if `sync: null` or `ui: null` is explicitly supplied, preserve that explicit `null`
- do not change tests, package.json, or TASK.md
- add no dependencies
EOF
    cat > "$DEST/src/config.js" <<'EOF'
export function mergeConfig(defaults, user) {
  return { ...defaults, ...user };
}
EOF
    cat > "$DEST/test/config.test.js" <<'EOF'
import test from "node:test";
import assert from "node:assert/strict";
import { mergeConfig } from "../src/config.js";

const defaults = {
  sync: { enabled: true, interval: 30 },
  ui: { compact: false, theme: "system" },
  tags: ["default"],
  retries: 3,
};

test("merges known nested objects without losing defaults", () => {
  const result = mergeConfig(defaults, {
    sync: { interval: 10 },
    ui: { compact: true },
  });
  assert.deepEqual(result.sync, { enabled: true, interval: 10 });
  assert.deepEqual(result.ui, { compact: true, theme: "system" });
});

test("preserves unknown keys and replaces arrays", () => {
  const result = mergeConfig(defaults, { tags: ["x"], experimental: true });
  assert.deepEqual(result.tags, ["x"]);
  assert.equal(result.experimental, true);
});

test("does not mutate either input", () => {
  const a = structuredClone(defaults);
  const user = { sync: { interval: 5 } };
  const b = structuredClone(user);
  const result = mergeConfig(defaults, user);
  result.sync.interval = 99;
  assert.deepEqual(defaults, a);
  assert.deepEqual(user, b);
});

test("handles absent and explicit null config", () => {
  assert.deepEqual(mergeConfig(defaults, null), defaults);
  const result = mergeConfig(defaults, { sync: null });
  assert.equal(result.sync, null);
});
EOF
    ;;

  deep)
    cat > "$DEST/TASK.md" <<'EOF'
# Deep benchmark task

Make the small persistence layer safely migrate schema-v1 records to schema v2.

Files: `src/migrate.js`, `src/store.js`.

Contract:
- schema v1 record `{ schemaVersion: 1, id, name, tags, ...extra }` migrates to v2
- v2 uses `displayName` instead of `name`
- v1 `tags` may be an array or comma-separated string; v2 must contain a trimmed array with empty entries removed
- unknown top-level fields must survive migration
- v2 input must be accepted idempotently without losing fields
- neither the input record nor nested arrays/objects may be mutated or aliased into the returned record
- missing/unsupported schema versions must throw
- `loadRecords(json)` parses a JSON array, migrates every record, rejects duplicate ids, and returns no partial result when any record is invalid
- malformed JSON or a non-array root must throw
- do not change tests, package.json, or TASK.md
- add no dependencies and do not weaken validation
EOF
    cat > "$DEST/src/migrate.js" <<'EOF'
export function migrateRecord(record) {
  if (record.schemaVersion === 2) return record;
  if (record.schemaVersion !== 1) throw new Error("unsupported schema");

  return {
    schemaVersion: 2,
    id: record.id,
    displayName: record.name,
    tags: record.tags || [],
  };
}
EOF
    cat > "$DEST/src/store.js" <<'EOF'
import { migrateRecord } from "./migrate.js";

export function loadRecords(json) {
  const parsed = JSON.parse(json);
  return parsed.map(migrateRecord);
}
EOF
    cat > "$DEST/test/store.test.js" <<'EOF'
import test from "node:test";
import assert from "node:assert/strict";
import { migrateRecord } from "../src/migrate.js";
import { loadRecords } from "../src/store.js";

test("migrates v1 while preserving extra fields and normalizing tags", () => {
  const input = {
    schemaVersion: 1,
    id: "a",
    name: "Alpha",
    tags: " one, two ,, three ",
    meta: { source: "old" },
    custom: 42,
  };
  const before = structuredClone(input);
  const result = migrateRecord(input);
  assert.deepEqual(result, {
    schemaVersion: 2,
    id: "a",
    displayName: "Alpha",
    tags: ["one", "two", "three"],
    meta: { source: "old" },
    custom: 42,
  });
  assert.deepEqual(input, before);
  assert.notEqual(result.meta, input.meta);
});

test("v2 is idempotent and deeply detached", () => {
  const input = {
    schemaVersion: 2,
    id: "b",
    displayName: "Beta",
    tags: ["x"],
    meta: { nested: { ok: true } },
  };
  const result = migrateRecord(input);
  assert.deepEqual(result, input);
  assert.notEqual(result, input);
  assert.notEqual(result.tags, input.tags);
  assert.notEqual(result.meta, input.meta);
  assert.notEqual(result.meta.nested, input.meta.nested);
});

test("rejects unsupported or missing schemas", () => {
  assert.throws(() => migrateRecord({ id: "x" }));
  assert.throws(() => migrateRecord({ schemaVersion: 9, id: "x" }));
});

test("loads and migrates a valid array", () => {
  const result = loadRecords(JSON.stringify([
    { schemaVersion: 1, id: "a", name: "A", tags: ["x", " y "] },
    { schemaVersion: 2, id: "b", displayName: "B", tags: [] },
  ]));
  assert.equal(result.length, 2);
  assert.deepEqual(result[0].tags, ["x", "y"]);
});

test("rejects malformed roots and duplicate ids", () => {
  assert.throws(() => loadRecords("{}"));
  assert.throws(() => loadRecords("not-json"));
  assert.throws(() => loadRecords(JSON.stringify([
    { schemaVersion: 2, id: "dup", displayName: "A", tags: [] },
    { schemaVersion: 2, id: "dup", displayName: "B", tags: [] },
  ])));
});

test("does not return a partial result when a later record is invalid", () => {
  assert.throws(() => loadRecords(JSON.stringify([
    { schemaVersion: 2, id: "good", displayName: "Good", tags: [] },
    { schemaVersion: 99, id: "bad" },
  ])));
});
EOF
    ;;
esac

# Create a local baseline so the grader can detect test/task tampering and patch size.
(
  cd "$DEST"
  git init -q
  git add .
  git -c user.name='Agentennetzwerk Eval' -c user.email='eval@local.invalid' commit -qm baseline
)

printf 'WORKSPACE=%s\n' "$DEST"
printf 'TASK_FILE=%s/TASK.md\n' "$DEST"
printf 'TEST_COMMAND=npm test\n'
