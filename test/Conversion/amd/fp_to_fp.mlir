// RUN: triton-opt %s --split-input-file --convert-triton-amdgpu-to-llvm=arch=gfx942 | FileCheck %s
// RUN: triton-opt %s --split-input-file --convert-triton-amdgpu-to-llvm=arch=gfx950 | FileCheck --check-prefix=CHECK-GFX950 %s

//  CHECK-LABEL: f16_to_f32
#blocked = #ttg.blocked<{sizePerThread = [1, 8], threadsPerWarp = [4, 8], warpsPerCTA = [4, 1], order = [1, 0]}>
module attributes {"ttg.num-ctas" = 1 : i32, "ttg.num-warps" = 4 : i32, "ttg.threads-per-warp" = 32 : i32} {
  tt.func @f16_to_f32(%arg0: tensor<8x8xf16, #ttg.dot_op<{opIdx = 0, parent = #blocked}>>) {
    // CHECK-COUNT-8: llvm.fpext %{{.+}} : f16 to f32
    %0 = tt.fp_to_fp %arg0 : tensor<8x8xf16, #ttg.dot_op<{opIdx = 0, parent = #blocked}>> -> tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked}>>
    tt.return
  }
}

// -----

//  CHECK-LABEL: bf16_to_f32
#blocked2 = #ttg.blocked<{sizePerThread = [1, 8], threadsPerWarp = [4, 8], warpsPerCTA = [4, 1], order = [1, 0]}>
module attributes {"ttg.num-ctas" = 1 : i32, "ttg.num-warps" = 4 : i32, "ttg.threads-per-warp" = 32 : i32} {
  tt.func @bf16_to_f32(%arg0: tensor<8x8xbf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>) {
    // CHECK-COUNT-8: llvm.bitcast
    %0 = tt.fp_to_fp %arg0 : tensor<8x8xbf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>
    tt.return
  }
}

// -----

//  CHECK-LABEL: f32_to_f16
#blocked2 = #ttg.blocked<{sizePerThread = [1, 8], threadsPerWarp = [4, 8], warpsPerCTA = [4, 1], order = [1, 0]}>
module attributes {"ttg.num-ctas" = 1 : i32, "ttg.num-warps" = 4 : i32, "ttg.threads-per-warp" = 32 : i32} {
  tt.func @f32_to_f16(%arg0: tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>) {
    // CHECK-COUNT-8: llvm.intr.experimental.constrained.fptrunc %{{.+}} tonearest ignore : f32 to f16
    %0 = tt.fp_to_fp %arg0, rounding = rtne : tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>
    // CHECK-COUNT-4: rocdl.cvt.pkrtz
    %1 = tt.fp_to_fp %arg0, rounding = rtz : tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>
    tt.return
  }
}

// -----

//  CHECK-LABEL: downcast_to_f8
#blocked2 = #ttg.blocked<{sizePerThread = [1, 8], threadsPerWarp = [4, 8], warpsPerCTA = [4, 1], order = [1, 0]}>
module attributes {"ttg.num-ctas" = 1 : i32, "ttg.num-warps" = 4 : i32, "ttg.threads-per-warp" = 32 : i32} {
  tt.func @downcast_to_f8(%arg0: tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>,
                     %arg1: tensor<8x8xf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>,
                     %arg2: tensor<8x8xbf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>) {
    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.bf8.f32
    %0 = tt.fp_to_fp %arg0, rounding = rtne : tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf8E5M2, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.bf8.f16
    %1 = tt.fp_to_fp %arg1, rounding = rtne : tensor<8x8xf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf8E5M2, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.bf8.bf16
    %2 = tt.fp_to_fp %arg2, rounding = rtne : tensor<8x8xbf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf8E5M2, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.fp8.f32
    %3 = tt.fp_to_fp %arg0, rounding = rtne : tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf8E4M3FN, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.fp8.f16
    %4 = tt.fp_to_fp %arg1, rounding = rtne : tensor<8x8xf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf8E4M3FN, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.fp8.bf16
    %5 = tt.fp_to_fp %arg2, rounding = rtne : tensor<8x8xbf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf8E4M3FN, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-COUNT-4: rocdl.cvt.pk.bf8.f32
    %6 = tt.fp_to_fp %arg0, rounding = rtne : tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf8E5M2FNUZ, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-COUNT-4: rocdl.cvt.pk.fp8.f32
    %7 = tt.fp_to_fp %arg0, rounding = rtne : tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf8E4M3FNUZ, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>
    tt.return
  }
}

// -----

//  CHECK-LABEL: upcast_from_f8
#blocked2 = #ttg.blocked<{sizePerThread = [1, 8], threadsPerWarp = [4, 8], warpsPerCTA = [4, 1], order = [1, 0]}>
module attributes {"ttg.num-ctas" = 1 : i32, "ttg.num-warps" = 4 : i32, "ttg.threads-per-warp" = 32 : i32} {
  tt.func @upcast_from_f8(%arg0: tensor<8x8xf8E5M2, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>,
                     %arg1: tensor<8x8xf8E4M3FN, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>,
                     %arg2: tensor<8x8xf8E5M2FNUZ, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>,
                     %arg3: tensor<8x8xf8E4M3FNUZ, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>) {
    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.f32.bf8
    %0 = tt.fp_to_fp %arg0 : tensor<8x8xf8E5M2, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.f16.bf8
    %1 = tt.fp_to_fp %arg0 : tensor<8x8xf8E5M2, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.bf16.bf8
    %2 = tt.fp_to_fp %arg0 : tensor<8x8xf8E5M2, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xbf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.f32.fp8
    %3 = tt.fp_to_fp %arg1 : tensor<8x8xf8E4M3FN, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.f16.fp8
    %4 = tt.fp_to_fp %arg1 : tensor<8x8xf8E4M3FN, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-GFX950-COUNT-4: rocdl.cvt.scalef32.pk.bf16.fp8
    %5 = tt.fp_to_fp %arg1 : tensor<8x8xf8E4M3FN, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xbf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-COUNT-4: rocdl.cvt.pk.f32.bf8
    %6 = tt.fp_to_fp %arg2 : tensor<8x8xf8E5M2FNUZ, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>

    // CHECK-COUNT-4: rocdl.cvt.pk.f32.fp8
    %7 = tt.fp_to_fp %arg3 : tensor<8x8xf8E4M3FNUZ, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>
    tt.return
  }
}

// -----

//  CHECK-LABEL: f8_rtz
#blocked2 = #ttg.blocked<{sizePerThread = [1, 8], threadsPerWarp = [4, 8], warpsPerCTA = [4, 1], order = [1, 0]}>
module attributes {"ttg.num-ctas" = 1 : i32, "ttg.num-warps" = 4 : i32, "ttg.threads-per-warp" = 32 : i32} {
  tt.func @f8_rtz(%arg0: tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>,
                     %arg1: tensor<8x8xf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>) {
    // CHECK-GFX950-NOT: rocdl.cvt.scalef32.pk.f32.bf8
    // CHECK-GFX950-COUNT-4: rocdl.cvt.pkrtz
    %1 = tt.fp_to_fp %arg0, rounding = rtz : tensor<8x8xf32, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf8E5M2, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>
    // CHECK-GFX950-NOT: rocdl.cvt.scalef32.pk.f16.bf8
    %2 = tt.fp_to_fp %arg1, rounding = rtz : tensor<8x8xf16, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>> -> tensor<8x8xf8E5M2, #ttg.dot_op<{opIdx = 0, parent = #blocked2}>>
    tt.return
  }
}
