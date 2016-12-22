// RUN: %target-swiftc_driver %s -g -sanitize=thread -o %t_tsan-binary
// RUN: env TSAN_OPTIONS=abort_on_error=0:ignore_interceptors_accesses=1 %target-run %t_tsan-binary 2>&1 | %FileCheck %s
// REQUIRES: executable_test
// REQUIRES: objc_interop
// REQUIRES: CPU=x86_64
// REQUIRES: tsan_runtime
// XFAIL: linux

// Test that we do not report a race on deinit; the syncronization is guaranteed by runtime.
import Foundation

public class TestDeallocObject : NSObject {
  public var v : Int
  public override init() {
    v = 1
  }

  func accessMember() {
    var local : Int = v
    local += 1
  }

  deinit {
    v = 0
  }
}

if (true) {
  var tdo : TestDeallocObject = TestDeallocObject()
  tdo.accessMember()

  // Read the value from a different thread.
  let concurrentQueue = DispatchQueue(label: "queuename", attributes: .concurrent)
  concurrentQueue.async {
    tdo.accessMember()
  }
  // Read the value from this thread.
  tdo.accessMember()
  sleep(1)

  // Deinit the value.
}

print("Done.")

// CHECK: Done.
// CHECK-NOT: ThreadSanitizer: data race
