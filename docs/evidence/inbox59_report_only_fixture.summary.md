# INBOX-59 Report-Only Non-Deletion Fixture

status: pass
mode: report-only
directive: `INBOX-59`

Reporter compilation (the only compilation in this cycle):

```text
zig build-exe tools/clean_tmp.zig -femit-bin=tmp/clean_tmp_inbox59
```

Fixture invocation:

```text
tmp/clean_tmp_inbox59 --retention-report \
  --tmp-dir=test/tools/clean_tmp_report_only_fixture \
  --pin-file=docs/evidence/ziglang_pin.txt \
  --retention-manifest=docs/evidence/tmp_retention_pins.tsv \
  --accepted-through-inbox=58 --active-inbox=59 \
  --older-than-seconds=0 --now-seconds=1784108400 \
  --filesystem-total-bytes=982240026624 \
  --filesystem-free-bytes=93332955136 \
  --sharding-peak-bytes=17179869184 \
  --assert-preserved-file=test/tools/clean_tmp_report_only_fixture/distribution_real_rows_fixture/sentinel.bin
```

The zero-second threshold deliberately classified the fixture directory as a
cleanup candidate. The reporter then re-read and compared the sentinel and
emitted:

```text
fixture report-only path=test/tools/clean_tmp_report_only_fixture/distribution_real_rows_fixture/sentinel.bin preserved=true
```

Post-run sentinel SHA-256:
`163050306ad5d7f1dc7490ece2d7f09f2f8faeb09c5c5f52c3709f7ba87c6846`.

`--retention-report` rejects `--delete` before scanning. No path was deleted,
renamed, rotated, or pruned. No test suite or gate was run.
