<pre>
<font color="#AAAAAA">• Yes. Internet sources confirm your suspicion partly: </font><b>LLVM is one blocker, but not the whole problem</b>.

Official Zig docs say async functions “regressed with the release of 0.11.0” and the current plan is to reintroduce them as a 
<b>lower-level primitive for I/O implementations</b>, not necessarily
the old <font color="#2AA1B3">async</font>/<font color="#2AA1B3">await</font> model. Source: Zig master language reference, 
“Async Functions” section: https://ziglang.org/documentation/master/#Async-Functions

The older docs list the original problems more explicitly:

- LLVM did not optimize Zig async frames/state machines well.
- Third-party debuggers could not debug them well.
- Cancellation semantics were unresolved.
- Async function pointers made stack/frame size hard or impossible to know statically.

Source: Zig 0.15.2 docs: https://ziglang.org/documentation/0.15.2/#Async-Functions

The cancellation problem is especially concrete. Andrew Kelley’s old <font color="#2AA1B3">cancelawait</font> issue shows that naïve 
async usage can leave an in-flight frame using invalid memory if an earlier <font color="#2AA1B3">try</font>
<font color="#2AA1B3">await</font> returns an error. That is not just ergonomics; it is a correctness and memory-safety design problem. 
Source: https://github.com/ziglang/zig/issues/5913

The newer direction appears to be: avoid restoring old high-level async directly, and instead provide lower-level stackless coroutine 
primitives that can power <font color="#2AA1B3">std.Io</font>. The current proposal
says Zig maintainers were exploring async/await in userland based on the new <font color="#2AA1B3">Io</font> interface, allowing 
different execution models: blocking, thread-pool, green-thread/fiber, or stackless
coroutine implementations. Source: https://github.com/ziglang/zig/issues/23446

So the pragmatic summary:

<font color="#2AA1B3">LLVM made the old async implementation unattractive, but the deeper blockers are semantics: cancellation, 
frame lifetime, known frame size, debugger behavior, target support, and choosing</font>
<font color="#2AA1B3">an execution model without forcing a runtime.</font>

This reinforces the earlier point: removing/reducing LLVM helps, but it does not by itself solve Zig async.
</pre>

<pre>
<font color="#AAAAAA">• The new plan is </font><b>not “restore old Zig </b><font color="#2AA1B3">async</font><b>/</b><font color="#2AA1B3">await</font><b> exactly.”</b> It is a two-layer design:

<font color="#2A7BDE">1. </font><b>Library-level async through </b><font color="#2AA1B3">std.Io</font>

   Zig 0.16 moves I/O behind an explicit <font color="#2AA1B3">std.Io</font> interface. Code that may block or depend on nondeterminism 
   receives an <font color="#2AA1B3">Io</font> value, similar to how allocator-aware code receives an allocator.
   The application’s <font color="#2AA1B3">main</font> chooses the implementation.

   Official release notes: https://ziglang.org/download/0.16.0/release-notes.html#I/O-as-an-Interface

<font color="#2A7BDE">2. </font><b>Execution model selected by the </b><font color="#2AA1B3">Io</font><b> implementation</b>

   The same code can run on different backends:
    - <font color="#2AA1B3">Io.Threaded</font>: thread-based, feature-complete in 0.16.
    - <font color="#2AA1B3">Io.Evented</font>: experimental green-thread / M:N / stack-switching backend.
    - <font color="#2AA1B3">Io.Uring</font>, <font color="#2AA1B3">Io.Kqueue</font>, <font color="#2AA1B3">Io.Dispatch</font>: backend work/proofs 
    for specific OS facilities.
    - <font color="#2AA1B3">Io.failing</font>: for systems with no supported operations.

<font color="#2A7BDE">3. </font><b>Tasks are represented as </b><font color="#2AA1B3">Future(T)</font>

   <font color="#2AA1B3">io.async(fn, args)</font> returns a <font color="#2AA1B3">Future(T)</font>. It means “this function call is independent from other logic,” 
   but it does <b>not guarantee parallelism</b>. An implementation is allowed to run it
   synchronously.

   <font color="#2AA1B3">io.concurrent(fn, args)</font> means “this must actually run concurrently for correctness,” and can fail with <font color="#2AA1B3">error.ConcurrencyUnavailable</font>.

   A future has:
    - <font color="#2AA1B3">await(io)</font>
    - <font color="#2AA1B3">cancel(io)</font>

   This directly addresses the old cancellation/resource-lifetime problem.

<font color="#2A7BDE">4. </font><b>Groups, queues, select, batch</b>

   For many tasks, <font color="#2AA1B3">Io.Group</font> manages shared lifetime. <font color="#2AA1B3">Queue</font>, <font color="#2AA1B3">Select</font>, and lower-level <font color="#2AA1B3">Batch</font> cover other concurrency patterns. 
   The release notes say <font color="#2AA1B3">Batch</font> is the lower-level/efficient
   operation-based path, while <font color="#2AA1B3">Future</font> is the more ergonomic function-based path.

<font color="#2A7BDE">5. </font><b>Future compiler work: low-level stackless coroutine primitives</b>

   The compiler-side proposal is to add low-level primitives like <font color="#2AA1B3">@asyncFrameSize</font>, <font color="#2AA1B3">@asyncInit</font>, <font color="#2AA1B3">@asyncResume</font>, <font color="#2AA1B3">@asyncSuspend</font>, 
   and <font color="#2AA1B3">@asyncFrame</font>, instead of bringing back the old high-level
   <font color="#2AA1B3">async</font> / <font color="#2AA1B3">await</font> / <font color="#2AA1B3">anyframe</font> model as-is.

   Proposal: https://github.com/ziglang/zig/issues/23446

The key design idea: <b>async becomes mostly userland/std.Io policy, with minimal compiler primitives only where stackless suspension is required.</b> 
That lets Zig support blocking, threaded,
green-threaded, and eventually stackless/event-loop implementations without forcing one runtime model into the language.
</pre>
