#!/usr/bin/env bash
set -euo pipefail
recovery_cli=$(realpath "$1")
recovery_snapshot=$(realpath "$2")
recovery_fixture_cli=$(realpath "$3")
recovery_cases=$ZLLVM_TEMP_ROOT/recovery-cases
mkdir -p "$recovery_cases"
recovery_hash() { sha256sum "$1" | cut -d ' ' -f1; }
recovery_compiler_sha=$(recovery_hash "$recovery_cli")
recovery_invoke() {
 env -u ZLLVM_RUN_ROOT -u ZLLVM_TEMP_ROOT -u ZLLVM_STORAGE_ROOT -u ZLLVM_SOURCE_ROOT -u ZIG_LOCAL_CACHE_DIR -u ZIG_GLOBAL_CACHE_DIR -u TMPDIR ZLLVM_REQUIRE_MANAGED_STORAGE=0 ZLLVM_PROJECT_ROOT="$recovery_fixture" "$recovery_cli" "$@"
}
recovery_plan() {
 "$recovery_snapshot" "$recovery_fixture/$recovery_work" > "$recovery_fixture/$recovery_run/tree.json"
 jqz -n --arg run "$recovery_run" --arg layout_hash "$(recovery_hash "$recovery_fixture/$recovery_run/checks.storage-layout.json")" --arg receipt_hash "$(recovery_hash "$recovery_fixture/$recovery_run/checks.json")" --arg job_hash "$(recovery_hash "$recovery_fixture/local-state/storage-cleanup/jobs/17-99999992.json")" --arg outer_hash "$(recovery_hash "$recovery_fixture/$recovery_run/outer.json")" --arg build_hash "$(recovery_hash "$recovery_fixture/$recovery_run/build.json")" --arg admission_hash "$(recovery_hash "$recovery_fixture/$recovery_run/admission.json")" --arg diagnosis_hash "$(recovery_hash "$recovery_fixture/$recovery_run/diagnosis.md")" --arg tree_hash "$(recovery_hash "$recovery_fixture/$recovery_run/tree.json")" --arg observation_hash "$(recovery_hash "$recovery_fixture/$recovery_run/processes.txt")" --arg review_hash "$(recovery_hash "$recovery_fixture/$recovery_run/review.md")" --argjson pids "$recovery_pids" --argjson groups "$recovery_groups" --argjson sessions "$recovery_sessions" '{schema:"zllvm-interrupted-workspace-recovery-v1",case:"lost-monitor-completed-compiler-build",review:{path:"local-state/validations/orphan-fixture/batch-01/owners/owner/review.md",sha256:$review_hash},records:[{layout:{path:"local-state/validations/orphan-fixture/batch-01/owners/owner/checks.storage-layout.json",sha256:$layout_hash},original_receipt:{path:"local-state/validations/orphan-fixture/batch-01/owners/owner/checks.json",sha256:$receipt_hash},original_job:{path:"local-state/storage-cleanup/jobs/17-99999992.json",sha256:$job_hash},original_monitor_outcome:"unknown",outer_observation:{path:"local-state/validations/orphan-fixture/batch-01/owners/owner/outer.json",sha256:$outer_hash},child_build:{path:"local-state/validations/orphan-fixture/batch-01/owners/owner/build.json",sha256:$build_hash},admission:{path:"local-state/validations/orphan-fixture/batch-01/owners/owner/admission.json",sha256:$admission_hash},diagnosis:{path:"local-state/validations/orphan-fixture/batch-01/owners/owner/diagnosis.md",sha256:$diagnosis_hash},tree:{path:"local-state/validations/orphan-fixture/batch-01/owners/owner/tree.json",sha256:$tree_hash},processes:{observation:{path:"local-state/validations/orphan-fixture/batch-01/owners/owner/processes.txt",sha256:$observation_hash},pids:$pids,groups:$groups,sessions:$sessions},consumers_closed:true,disposal_authorized:true,reason:"Synthetic isolated recovery fixture; original monitor outcome stays unknown"}]}' > "$recovery_fixture/$recovery_run/recovery.json"
}
recovery_make() {
 recovery_fixture=$recovery_cases/$1
 recovery_run=local-state/validations/orphan-fixture/batch-01/owners/owner
 recovery_work=local-state/tmp/validations/orphan-fixture/batch-01/owners/owner/.workspaces/checks
 recovery_pids='[99999991,99999992]'
 recovery_groups='[99999993]'
 recovery_sessions='[99999994]'
 mkdir -p "$recovery_fixture/src" "$recovery_fixture/docs" "$recovery_fixture/local-state/storage-cleanup/jobs" "$recovery_fixture/$recovery_run" "$recovery_fixture/$recovery_work/local-cache/o" "$recovery_fixture/$recovery_work/global-cache/o"
 printf '0.17.0\n' > "$recovery_fixture/.zigversion"
 printf 'pub fn main() void {}\n' > "$recovery_fixture/src/main.zig"
 printf 'interrupted-recovery-fixture\n' > "$recovery_fixture/fixture-only.marker"
 printf '{"schema":1,"minimum_idle_hours":0}\n' > "$recovery_fixture/docs/storage_cleanup_policy.json"
 printf '{"schema":1,"paths":[]}\n' > "$recovery_fixture/local-state/storage-cleanup/holds.json"
 printf 'private compiled cache fixture\n' > "$recovery_fixture/$recovery_work/local-cache/o/cache"
 printf 'private global cache fixture\n' > "$recovery_fixture/$recovery_work/global-cache/o/cache"
 jqz -n --arg run "$recovery_run" --arg work "$recovery_work" '{schema:"zllvm-storage-workspace-v1",evidence_root:$run,temporary_root:$work,key:"checks",state:"active",lifetime:"validation",result:null,diagnostics:[]}' > "$recovery_fixture/$recovery_run/checks.storage-layout.json"
 jqz -n --arg cwd "$recovery_fixture" --arg run "$recovery_fixture/$recovery_run" --arg work "$recovery_fixture/$recovery_work" --arg layout "$recovery_fixture/$recovery_run/checks.storage-layout.json" '{status:"running",actual_returncode:null,returncode:null,pid:99999991,started_ns:17,cwd:$cwd,storage:{layout:$layout,evidence_root:$run,temporary_root:$work,lifetime:"validation"}}' > "$recovery_fixture/$recovery_run/checks.json"
 jqz -n --arg run "$recovery_run" --arg receipt "$recovery_run/checks.json" '{schema:"zllvm-storage-job-v1",state:"running",run_root:$run,working_directory:".",external_working_directory:null,producer:{path:$receipt,sha256:""},started_ns:17}' > "$recovery_fixture/local-state/storage-cleanup/jobs/17-99999992.json"
 printf '{"observed_outer_session_returncode":143,"original_managed_final_exit_available":false}\n' > "$recovery_fixture/$recovery_run/outer.json"
 jqz -n --arg compiler "$recovery_compiler_sha" --arg cwd "$recovery_fixture" --arg local "$recovery_fixture/$recovery_work/local-cache" --arg global "$recovery_fixture/$recovery_work/global-cache" '{schema:"zllvm-compiler-build-v1",compiler_sha256:$compiler,environment:{ZIG_LOCAL_CACHE_DIR:$local,ZIG_GLOBAL_CACHE_DIR:$global},command:{actual_returncode:0,returncode:0,outcome:"completed",cwd:$cwd}}' > "$recovery_fixture/$recovery_run/build.json"
 jqz -n --arg compiler "$recovery_compiler_sha" '{status:"passed",exact_completed_child_build_adopted:true,actual_sdk_build_returncode:0,original_monitor_terminal_exit_available:false,backend_sha256:$compiler}' > "$recovery_fixture/$recovery_run/admission.json"
 printf 'Isolated fixture diagnosis; original monitor exit is unknown.\n' > "$recovery_fixture/$recovery_run/diagnosis.md"
 printf 'Synthetic test process topology; no project producer claim.\n' > "$recovery_fixture/$recovery_run/processes.txt"
 printf 'Fixture-only explicit storage disposal review, no producer completion.\n' > "$recovery_fixture/$recovery_run/review.md"
 recovery_plan
 recovery_other=local-state/validations/orphan-fixture/batch-01/unrelated
 recovery_other_work=local-state/tmp/validations/orphan-fixture/batch-01/unrelated/.workspaces/checks
 mkdir -p "$recovery_fixture/$recovery_other" "$recovery_fixture/$recovery_other_work"
 printf 'unrelated disposable workspace must survive explicit recovery\n' > "$recovery_fixture/$recovery_other_work/retained"
 printf '{"status":"passed"}\n' > "$recovery_fixture/$recovery_other/checks.json"
 jqz -n --arg root "$recovery_other" --arg work "$recovery_other_work" --arg result "$recovery_other/checks.json" --arg sha "$(recovery_hash "$recovery_fixture/$recovery_other/checks.json")" '{schema:"zllvm-storage-workspace-v1",evidence_root:$root,temporary_root:$work,key:"checks",state:"disposable",lifetime:"validation",result:{path:$result,sha256:$sha},diagnostics:[]}' > "$recovery_fixture/$recovery_other/checks.storage-layout.json"
}
recovery_preserve() {
 sha256sum "$recovery_fixture/$recovery_run/checks.json" "$recovery_fixture/$recovery_run/checks.storage-layout.json" "$recovery_fixture/local-state/storage-cleanup/jobs/17-99999992.json" > "$recovery_fixture/original-identities.txt"
}
recovery_check_original() {
 sha256sum --check --quiet "$recovery_fixture/original-identities.txt"
 test "$(cat "$recovery_fixture/$recovery_other_work/retained")" = 'unrelated disposable workspace must survive explicit recovery'
}
recovery_deny() {
 local recovery_policy_args=()
 if test "${recovery_fixture##*/}" = weaker-policy; then recovery_policy_args=(--policy docs/weaker-policy.json); fi
 recovery_preserve
 "$recovery_snapshot" "$recovery_fixture/$recovery_work" > "$recovery_fixture/refusal-tree.json"
 recovery_code=0
 recovery_invoke recover-interrupted-workspace --review "$recovery_run/recovery.json" --minimal --apply "${recovery_policy_args[@]}" > "$recovery_fixture/action.log" 2>&1 || recovery_code=$?
 if test "$recovery_code" -eq 0; then
  recovery_refusal_report=$(sed -n 's/^Cleanup complete: //p' "$recovery_fixture/action.log" | tail -n 1)
  test -n "$recovery_refusal_report"
  jqz -e --arg path "$recovery_work" '.ready==0 and .removed==0 and length(.actions)==1 and .actions[0].path==$path and .actions[0].status=="skipped"' "$recovery_fixture/$recovery_refusal_report" > /dev/null
  cp "$recovery_fixture/$recovery_refusal_report" "$recovery_fixture/refusal-report.json"
 fi
 test -f "$recovery_fixture/$recovery_work/local-cache/o/cache"
 test ! -e "$recovery_fixture/local-state/storage-cleanup/pending.json"
 recovery_check_original
 "$recovery_snapshot" --verify "$recovery_fixture/refusal-tree.json"
 printf '%s %s\n' "$(basename "$recovery_fixture")" "$recovery_code" >> "$ZLLVM_RUN_ROOT/denied.txt"
}

recovery_make ordinary
recovery_preserve
if recovery_invoke release-workspace --layout "$recovery_run/checks.storage-layout.json" --reason 'Cannot close an unfinished producer' > "$recovery_fixture/action.log" 2>&1; then exit 1; fi
test -f "$recovery_fixture/$recovery_work/local-cache/o/cache"
recovery_check_original
recovery_make positive
recovery_preserve
recovery_invoke recover-interrupted-workspace --review "$recovery_run/recovery.json" --minimal > "$recovery_fixture/dry.log" 2>&1
recovery_review=$(sed -n 's/^Review complete: //p' "$recovery_fixture/dry.log" | tail -n 1)
jqz -e '.ready==1 and .removed==0 and .actions[0].original_monitor_outcome=="unknown"' "$recovery_fixture/$recovery_review" > /dev/null
test -f "$recovery_fixture/$recovery_work/local-cache/o/cache"
recovery_invoke recover-interrupted-workspace --review "$recovery_run/recovery.json" --minimal --apply > "$recovery_fixture/apply.log" 2>&1
test ! -e "$recovery_fixture/$recovery_work"
test ! -e "$recovery_fixture/$recovery_run/checks.workspace-release.json"
recovery_check_original
cp "$recovery_fixture/apply.log" "$ZLLVM_RUN_ROOT/positive.log"

for recovery_case in changed-receipt changed-layout changed-job changed-tree changed-diagnosis pin hold other-job raw excluded-tree known-monitor missing-child denied-authorization wrong-receipt-path symlink external-hardlink held-release-owner held-release-ancestor retained-member fifo readonly-directory weaker-policy equal-null-digests equal-malformed-digests; do
 recovery_make "$recovery_case"
 case "$recovery_case" in
  changed-receipt) printf '\n' >> "$recovery_fixture/$recovery_run/checks.json" ;;
  changed-layout) printf '\n' >> "$recovery_fixture/$recovery_run/checks.storage-layout.json" ;;
  changed-job) printf '\n' >> "$recovery_fixture/local-state/storage-cleanup/jobs/17-99999992.json" ;;
  changed-tree) printf 'changed\n' >> "$recovery_fixture/$recovery_work/local-cache/o/cache" ;;
  changed-diagnosis) printf 'changed\n' >> "$recovery_fixture/$recovery_run/diagnosis.md" ;;
  pin)
   (cd "$recovery_fixture" && sha256sum "$recovery_work/local-cache/o/cache") > "$recovery_fixture/current.sha256"
   printf '{"schema":1,"minimum_idle_hours":0,"current_manifests":["current.sha256"]}\n' > "$recovery_fixture/docs/storage_cleanup_policy.json" ;;
  hold) jqz -n --arg run "$recovery_run" '{schema:1,paths:[$run]}' > "$recovery_fixture/local-state/storage-cleanup/holds.json" ;;
  other-job) cp "$recovery_fixture/local-state/storage-cleanup/jobs/17-99999992.json" "$recovery_fixture/local-state/storage-cleanup/jobs/17-99999995.json" ;;
  raw) printf 'raw fixture detail\n' > "$recovery_fixture/$recovery_work/profile.events.jsonl"; recovery_plan ;;
  excluded-tree)
   jqz 'update(.,.options.exclude_paths,["local-cache"])' "$recovery_fixture/$recovery_run/tree.json" > "$recovery_fixture/edited.json"
   mv "$recovery_fixture/edited.json" "$recovery_fixture/$recovery_run/tree.json"
   recovery_tree_hash=$(recovery_hash "$recovery_fixture/$recovery_run/tree.json")
   jqz --arg sha "$recovery_tree_hash" 'update(.,.records[0].tree.sha256,$sha)' "$recovery_fixture/$recovery_run/recovery.json" > "$recovery_fixture/edited.json"
   mv "$recovery_fixture/edited.json" "$recovery_fixture/$recovery_run/recovery.json" ;;
  known-monitor)
   jqz 'update(update(update(.,.status,"finished"),.actual_returncode,0),.returncode,0)' "$recovery_fixture/$recovery_run/checks.json" > "$recovery_fixture/edited.json"
   mv "$recovery_fixture/edited.json" "$recovery_fixture/$recovery_run/checks.json"
   recovery_plan ;;
  missing-child) rm "$recovery_fixture/$recovery_run/build.json" ;;
  denied-authorization)
   jqz 'update(.,.records[0].disposal_authorized,false)' "$recovery_fixture/$recovery_run/recovery.json" > "$recovery_fixture/edited.json"
   mv "$recovery_fixture/edited.json" "$recovery_fixture/$recovery_run/recovery.json" ;;
  wrong-receipt-path)
   cp "$recovery_fixture/$recovery_run/checks.json" "$recovery_fixture/$recovery_run/other.json"
   jqz --arg path "$recovery_run/other.json" 'update(.,.records[0].original_receipt.path,$path)' "$recovery_fixture/$recovery_run/recovery.json" > "$recovery_fixture/edited.json"
   mv "$recovery_fixture/edited.json" "$recovery_fixture/$recovery_run/recovery.json" ;;
  symlink)
   printf 'outside fixture cache\n' > "$recovery_fixture/retained.txt"
   ln -s "$recovery_fixture/retained.txt" "$recovery_fixture/$recovery_work/link"
   recovery_plan ;;
  external-hardlink)
   ln "$recovery_fixture/$recovery_work/local-cache/o/cache" "$recovery_fixture/retained-link"
   recovery_plan ;;
  held-release-owner|held-release-ancestor)
   recovery_release_root=$recovery_run
   if test "$recovery_case" = held-release-ancestor; then recovery_release_root=${recovery_run%/owner}; fi
   jqz -n --arg root "$recovery_release_root" --arg producer "$recovery_run/checks.json" --arg sha "$(recovery_hash "$recovery_fixture/$recovery_run/checks.json")" '{schema:"zllvm-storage-release-v1",state:"held",run_root:$root,reason:"Independent held release",producer:{path:$producer,sha256:$sha},retained:[],artifacts:[]}' > "$recovery_fixture/$recovery_release_root/storage-release.json" ;;
  retained-member)
   printf 'independent extant detail\n' > "$recovery_fixture/$recovery_other/old.log"
   jqz -n --arg root "$recovery_other" --arg producer "$recovery_run/checks.json" --arg producer_sha "$(recovery_hash "$recovery_fixture/$recovery_run/checks.json")" --arg member "$recovery_work/local-cache/o/cache" --arg member_sha "$(recovery_hash "$recovery_fixture/$recovery_work/local-cache/o/cache")" --arg old "$recovery_other/old.log" --arg old_sha "$(recovery_hash "$recovery_fixture/$recovery_other/old.log")" '{schema:"zllvm-storage-release-v1",state:"disposable",run_root:$root,reason:"Independent retained member",producer:{path:$producer,sha256:$producer_sha},retained:[{path:$member,sha256:$member_sha,role:"input"}],artifacts:[{path:$old,sha256:$old_sha,kind:"log"}]}' > "$recovery_fixture/$recovery_other/storage-release.json" ;;
  fifo) mkfifo "$recovery_fixture/$recovery_work/fifo"; recovery_plan ;;
  readonly-directory) chmod 500 "$recovery_fixture/$recovery_work/local-cache/o"; recovery_plan ;;
  weaker-policy)
   jqz -n --arg run "$recovery_run" '{schema:1,paths:[$run]}' > "$recovery_fixture/local-state/storage-cleanup/holds.json"
   (cd "$recovery_fixture" && sha256sum "$recovery_work/local-cache/o/cache") > "$recovery_fixture/canonical.sha256"
   printf '{"schema":1,"minimum_idle_hours":0,"current_manifests":["canonical.sha256"]}\n' > "$recovery_fixture/docs/storage_cleanup_policy.json"
   printf '{"schema":1,"paths":[]}\n' > "$recovery_fixture/local-state/storage-cleanup/weaker-holds.json"
   printf '{"schema":1,"minimum_idle_hours":0,"current_manifests":[],"holds_file":"local-state/storage-cleanup/weaker-holds.json"}\n' > "$recovery_fixture/docs/weaker-policy.json" ;;
  equal-null-digests|equal-malformed-digests)
   recovery_digest_value=null
   if test "$recovery_case" = equal-malformed-digests; then recovery_digest_value='"not-a-canonical-sha256"'; fi
   jqz --argjson digest "$recovery_digest_value" 'update(.,.compiler_sha256,$digest)' "$recovery_fixture/$recovery_run/build.json" > "$recovery_fixture/edited.json"
   mv "$recovery_fixture/edited.json" "$recovery_fixture/$recovery_run/build.json"
   jqz --argjson digest "$recovery_digest_value" 'update(.,.backend_sha256,$digest)' "$recovery_fixture/$recovery_run/admission.json" > "$recovery_fixture/edited.json"
   mv "$recovery_fixture/edited.json" "$recovery_fixture/$recovery_run/admission.json"
   recovery_plan ;;
 esac
 recovery_deny
 case "$recovery_case" in
  held-release-owner|held-release-ancestor)
   test "$recovery_code" -eq 0
   jqz -e --arg reason "protected by hold: $recovery_release_root" '.actions[0].reason==$reason' "$recovery_fixture/refusal-report.json" > /dev/null ;;
  retained-member)
   test "$recovery_code" -eq 0
   jqz -e '.actions[0].reason=="retained evidence of another candidate"' "$recovery_fixture/refusal-report.json" > /dev/null ;;
  weaker-policy)
   test "$recovery_code" -ne 0
   zigrep --no-config -q -F 'InterruptedWorkspaceRequiresOwnerPolicy' "$recovery_fixture/action.log" ;;
  equal-null-digests)
   test "$recovery_code" -ne 0
   zigrep --no-config -q -F 'ExpectedString' "$recovery_fixture/action.log" ;;
  equal-malformed-digests)
   test "$recovery_code" -ne 0
   zigrep --no-config -q -F 'ChildCompilerAdmissionMismatch' "$recovery_fixture/action.log" ;;
 esac
done

for recovery_case in live-pid live-family; do
 recovery_make "$recovery_case"
 setsid sleep 300 < /dev/null > "$recovery_fixture/sleep.log" 2>&1 &
 recovery_live=$!
 if test "$recovery_case" = live-pid; then
  jqz --argjson pid "$recovery_live" 'update(.,.pid,$pid)' "$recovery_fixture/$recovery_run/checks.json" > "$recovery_fixture/edited.json"
  mv "$recovery_fixture/edited.json" "$recovery_fixture/$recovery_run/checks.json"
  recovery_pids="[$recovery_live,99999992]"
 else
  recovery_groups="[$recovery_live]"
  recovery_sessions="[$recovery_live]"
 fi
 recovery_plan
 recovery_deny
 kill "$recovery_live"
 wait "$recovery_live" || true
done

recovery_make pending
printf '{"schema":1,"status":"pending","fixture":true}\n' > "$recovery_fixture/local-state/storage-cleanup/pending.json"
recovery_preserve
if recovery_invoke recover-interrupted-workspace --review "$recovery_run/recovery.json" --minimal --apply > "$recovery_fixture/action.log" 2>&1; then exit 1; fi
zigrep --no-config -q -F 'An interrupted cleanup needs review' "$recovery_fixture/action.log"
test -f "$recovery_fixture/$recovery_work/local-cache/o/cache"
recovery_check_original

for recovery_reader_kind in command descriptor; do
 recovery_make "rollback-$recovery_reader_kind"
 recovery_preserve
 "$recovery_snapshot" "$recovery_fixture/$recovery_work" > "$recovery_fixture/before-rollback.json"
 recovery_rollback_status=0
 env -u ZLLVM_RUN_ROOT -u ZLLVM_TEMP_ROOT -u ZLLVM_STORAGE_ROOT -u ZLLVM_SOURCE_ROOT -u ZIG_LOCAL_CACHE_DIR -u ZIG_GLOBAL_CACHE_DIR -u TMPDIR ZLLVM_REQUIRE_MANAGED_STORAGE=0 ZLLVM_PROJECT_ROOT="$recovery_fixture" RECOVERY_ROLLBACK_READER="$recovery_reader_kind" "$recovery_fixture_cli" recover-interrupted-workspace --review "$recovery_run/recovery.json" --minimal --apply > "$recovery_fixture/action.log" 2>&1 || recovery_rollback_status=$?
 test "$recovery_rollback_status" -ne 0
 if test "$recovery_reader_kind" = command; then recovery_error=InterruptedWorkspaceQuarantineCommand; else recovery_error=InterruptedWorkspaceQuarantineReader; fi
 zigrep --no-config -q -F "$recovery_error" "$recovery_fixture/action.log"
 test ! -e "$recovery_fixture/local-state/storage-cleanup/pending.json"
 "$recovery_fixture_cli" __compare-rollback "$recovery_fixture/before-rollback.json" "$recovery_fixture/$recovery_work"
 "$recovery_snapshot" "$recovery_fixture/$recovery_work" > "$recovery_fixture/after-rollback.json"
 recovery_check_original
done

recovery_make interrupted-application
for recovery_index in {1..4096}; do
 printf 'owned interruption fixture %s\n' "$recovery_index" > "$recovery_fixture/$recovery_work/local-cache/o/item-$recovery_index"
done
recovery_plan
recovery_preserve
setsid env -u ZLLVM_RUN_ROOT -u ZLLVM_TEMP_ROOT -u ZLLVM_STORAGE_ROOT -u ZLLVM_SOURCE_ROOT -u ZIG_LOCAL_CACHE_DIR -u ZIG_GLOBAL_CACHE_DIR -u TMPDIR ZLLVM_REQUIRE_MANAGED_STORAGE=0 ZLLVM_PROJECT_ROOT="$recovery_fixture" "$recovery_cli" recover-interrupted-workspace --review "$recovery_run/recovery.json" --minimal --apply > "$recovery_fixture/interrupted.log" 2>&1 < /dev/null &
recovery_apply_pid=$!
recovery_pending=false
for recovery_poll in {1..3000}; do
 if test -f "$recovery_fixture/local-state/storage-cleanup/pending.json"; then recovery_pending=true; break; fi
 if ! kill -0 "$recovery_apply_pid" 2>/dev/null; then break; fi
 sleep 0.01
done
test "$recovery_pending" = true
kill -STOP "$recovery_apply_pid"
cp "$recovery_fixture/local-state/storage-cleanup/pending.json" "$ZLLVM_RUN_ROOT/interrupted-pending.json"
kill -KILL -- "-$recovery_apply_pid"
recovery_interrupted_status=0
wait "$recovery_apply_pid" || recovery_interrupted_status=$?
test "$recovery_interrupted_status" -ne 0
printf '%s\n' "$recovery_interrupted_status" > "$ZLLVM_RUN_ROOT/interrupted-actual-status.txt"
recovery_check_original
test -f "$recovery_fixture/local-state/storage-cleanup/pending.json"
recovery_retry_guard=false
for recovery_retry in {1..20}; do
 recovery_retry_status=0
 recovery_invoke recover-interrupted-workspace --review "$recovery_run/recovery.json" --minimal --apply > "$recovery_fixture/retry.log" 2>&1 || recovery_retry_status=$?
 test "$recovery_retry_status" -ne 0
 if zigrep --no-config -q -F 'An interrupted cleanup needs review' "$recovery_fixture/retry.log"; then recovery_retry_guard=true; break; fi
 sleep 0.1
done
test "$recovery_retry_guard" = true
cp "$recovery_fixture/retry.log" "$ZLLVM_RUN_ROOT/interrupted-retry.log"
recovery_check_original

mkdir -p "$ZLLVM_RUN_ROOT/cases"
for recovery_saved in "$recovery_cases"/*; do
 recovery_name=${recovery_saved##*/}
 mkdir -p "$ZLLVM_RUN_ROOT/cases/$recovery_name"
 for recovery_leaf in action.log dry.log apply.log interrupted.log retry.log original-identities.txt refusal-report.json refusal-tree.json before-rollback.json after-rollback.json; do
  if test -f "$recovery_saved/$recovery_leaf"; then cp "$recovery_saved/$recovery_leaf" "$ZLLVM_RUN_ROOT/cases/$recovery_name/$recovery_leaf"; fi
 done
 cp "$recovery_saved/local-state/storage-cleanup/jobs/17-99999992.json" "$ZLLVM_RUN_ROOT/cases/$recovery_name/source-job.json.record"
 for recovery_leaf in checks.json checks.storage-layout.json recovery.json; do
  cp "$recovery_saved/$recovery_run/$recovery_leaf" "$ZLLVM_RUN_ROOT/cases/$recovery_name/$recovery_leaf.record"
 done
done
case "$recovery_cases" in "$ZLLVM_TEMP_ROOT"/recovery-cases) ;; *) exit 2 ;; esac
chmod -R u+w "$recovery_cases"
rm -r -- "$recovery_cases"

printf '{"status":"passed","positive_dry_and_apply":true,"original_monitor_layout_and_job_unchanged":true,"ordinary_unfinished_release_refused":true,"negative_cases":26,"canonical_policy_required":true,"equal_null_and_malformed_compiler_digests_refused":true,"quarantine_reader_rollback_cases":2,"all_original_membership_content_inodes_modes_preserved_before_unlink":true,"root_ctime_change_due_only_to_rename_and_restore":true,"unrelated_candidates_untouched":true,"pending_journal_refused":true,"actual_interrupted_fixture_apply_retained_journal":true,"subsequent_deletion_refused":true,"real_project_mutation":false}\n' > "$ZLLVM_RUN_ROOT/report.json"
