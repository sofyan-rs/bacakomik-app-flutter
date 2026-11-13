# Flutter 3.50.0's Linux engine draws each frame half a window down and to the
# left when it composites without glBlitFramebuffer: the app shows in the
# bottom-left quarter of its window, the rest is black, and taps land where
# the hidden layout is. https://github.com/flutter/flutter/issues/195885,
# fixed upstream in https://github.com/flutter/flutter/pull/196083 for 3.50.1.
#
# The engine skips glBlitFramebuffer for drivers whose GL vendor contains
# "NVIDIA" (a 2024 blocklist, https://github.com/flutter/flutter/issues/152099),
# so every NVIDIA proprietary driver hits that broken path. Correcting the
# path's offset in its shader isn't enough: the right offset depends on the
# desktop scale (fractional scales such as 133 % on GNOME or Hyprland come out
# wrong). Instead, the bundle's copy of exactly that engine (debug, profile and
# release, matched by SHA-256) has that blocklist entry renamed to a vendor no
# driver reports, a string of the same length so nothing else in the library
# moves, and blits like it does on Intel and AMD. Checked on an RTX 5060 with
# driver 615.78.08 (GNOME on Wayland, 133 %). Any other engine is left alone.
#
# Remove this file and its call in CMakeLists.txt when moving to Flutter 3.50.1,
# after checking 3.50.1 on NVIDIA at a fractional scale.
function(fix_flutter_3_50_0_engine library)
  file(SHA256 "${library}" hash)
  # Engine of Flutter 3.50.0: debug, profile, release.
  set(broken
    f38c8d6a0ef588b58daccdecaf2000f5cbdad267979369560c347a40af3eb258
    c31a78ca3aec4413815cb277b60ab4c1d42d4f00dd15bb3c1c21496f718e9786
    cb40d5867033badfa1a38072fab83f1c60ec1520c303a4810f49979f0ba5df04)
  # The same three after the correction.
  set(fixed
    0670e5e867807b2d07cffb30efacc23b2eb0c7e9b9abbf3334eebf6d10e6682e
    a11eeafeb542e1a2853b9c9a64708cf61a28466bcb0134c83e7260b61dccc267
    9d44e31942d73bcc26b1df6e1bd75235552792d58f0559e795c0608b13eb8c02)
  list(FIND broken "${hash}" index)
  if(index EQUAL -1)
    return()
  endif()
  list(GET fixed ${index} expected)
  # The entry is the only "NVIDIA" between NUL bytes in the library. Byte for
  # byte, whatever the locale.
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E env LC_ALL=C sed -i
      "s/\\x00NVIDIA\\x00/\\x00NOBLKL\\x00/"
      "${library}"
    RESULT_VARIABLE result)
  file(SHA256 "${library}" hash)
  if(NOT result EQUAL 0 OR NOT hash STREQUAL expected)
    message(FATAL_ERROR
      "Could not correct the Flutter 3.50.0 engine in ${library} (flutter_3_50_0_fix.cmake)")
  endif()
  message(STATUS "Let the Flutter 3.50.0 engine blit on NVIDIA: ${library}")
endfunction()
