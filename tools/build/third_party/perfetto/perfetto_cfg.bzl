# Copyright (C) 2019 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@gapid//tools/build/rules:cc.bzl", "cc_stripped_binary")

_ALWAYS_OPTIMIZE_COPTS = [
  "-O2",
  "-DNDEBUG",
]
_STD_MACROS_COPTS = [
  "-D__STDC_FORMAT_MACROS",
]

def _always_optimize_cc_library(**kwargs):
  copts = kwargs.pop("copts", default = []) + _ALWAYS_OPTIMIZE_COPTS + _STD_MACROS_COPTS
  # Override the linkopts from Perfetto (see below to what we add). This is only needed
  # because Perfetto uses the newer OS config rules, which do not currently work with
  # bazel & Android.
  # TODO(pmuetschard): remove once bazel supports the new config rules for Android.
  kwargs.pop("linkopts", default = [])
  native.cc_library(
    copts = copts,
    linkopts = select({
      "@gapid//tools/build:linux": ["-ldl", "-lrt", "-lpthread"],
      "@gapid//tools/build:darwin": [],
      "@gapid//tools/build:darwin_arm64": [],
      "@gapid//tools/build:windows": [],
      # Android.
      "//conditions:default": ["-ldl"],
    }),
    **kwargs
  )

def _always_optimize_cc_binary(**kwargs):
  copts = kwargs.pop("copts", default = []) + _ALWAYS_OPTIMIZE_COPTS
  # Remove the linkopts from Perfetto. This is only needed because Perfetto uses
  # the newer OS config rules, which do not currently work with  bazel & Android.
  # TODO(pmuetschard): remove once bazel supports the new config rules for Android.
  kwargs.pop("linkopts", default = [])
  visibility = kwargs.pop("visibility", default = ["//visibility:private"])
  cc_stripped_binary(
    copts = copts,
    visibility = visibility,
    **kwargs
  )

PERFETTO_CONFIG = struct(
  root = "//",
  deps = struct(
    build_config = ["@gapid//tools/build/third_party/perfetto:build_config"],
    demangle_wrapper = ["@perfetto//:src_trace_processor_demangle"],
    jsoncpp = [],
    linenoise = [],
    llvm_demangle = [],
    protobuf_descriptor_proto = ["@com_google_protobuf//:descriptor_proto"],
    protobuf_lite = ["@com_google_protobuf//:protobuf_lite"],
    protobuf_full = ["@com_google_protobuf//:protobuf"],
    protoc = ["@com_google_protobuf//:protoc"],
    protoc_lib = ["@com_google_protobuf//:protoc_lib"],
    sqlite = ["@sqlite//:sqlite"],
    sqlite_ext_percentile = ["@sqlite_src//:percentile_ext"],
    version_header = [],
    # MSLEE: Add missing field 'base_platform'
    # Target exposing platform-specific functionality for base. This is
    # overriden in Google internal builds.
    base_platform = ["//:perfetto_base_default_platform"],
    zlib = ["@net_zlib//:zlib"],
    # MSLEE: Add missing fields for python
    # The Python targets are empty on the standalone build because we assume
    # any relevant deps are installed on the system or are not applicable.
    protobuf_py = [],
    pandas_py = [],
    tp_vendor_py = [],
    tp_resolvers_py = [],
  ),
  
  public_visibility = [
      "//visibility:public",
  ],
  proto_library_visibility = "//visibility:public",
  go_proto_library_visibility = "//visibility:public",
  deps_copts = struct(
    zlib = [],
    jsoncpp = [],
    linenoise = [],
    sqlite = _ALWAYS_OPTIMIZE_COPTS,
    llvm_demangle = [],
  ),
  rule_overrides = struct(
    cc_library =_always_optimize_cc_library,
    cc_binary = _always_optimize_cc_binary,
  ),
  # MSLEE: Add missing field 'default_copts'
  # The default copts which we use to compile C++ code.
  default_copts = [
	"-std=c++14",
  ]
)
