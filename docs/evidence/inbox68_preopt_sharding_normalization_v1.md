# INBOX-68 preopt-sharding normalization v1

status: frozen for INBOX-68 validation
schema: 1
authority: `tools/normalize_preopt_sharding_output.zig`

The canonical comparison preserves every input byte except for complete lines
whose exact prefix is:

```text
preopt-sharding schema=1 
```

Those lines are removed in full. They are the sole shard-bookkeeping records
and contain only fields authorized as volatile by INBOX-68: run identity,
runner-owned temporary/cache paths, concurrency/partition bookkeeping,
durations, resource samples, headroom samples, and system load.

No canonical header, per-case record, aggregate summary, case identity,
ordering, counter, diagnostic, validation classification, expected-failure
information, `local_fail`, exit status, or artifact identity is rewritten or
removed. Blank lines and terminal-newline state are preserved byte-for-byte.
A `preopt-sharding` record with any schema other than `schema=1` fails closed.
