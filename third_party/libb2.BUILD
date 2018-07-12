BLAKE2_COPTS = [
    "-Wno-unused-const-variable",
    "-Wno-unused-function",
]

genrule(
    name = "stub_config",
    srcs = ["src/blake2-config.h"],
    outs = ["src/config.h"],
    cmd = "cat $(location src/blake2-config.h) > $@",
)

cc_library(
    name = "com_github_blake2_libb2",
    srcs = ["src/blake2s.c", "src/blake2b.c", "src/config.h"] + glob(["src/*.h"]),
    hdrs = [
        "src/blake2.h",
    ],
    copts = BLAKE2_COPTS,
    includes = [
        "src",
    ],
    defines = ["SUFFIX="],
    visibility = ["//visibility:public"],
)
