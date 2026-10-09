
// Efinity Top-level template
// Version: 2025.1.110
// Date: 2025-05-07 23:42

// Copyright (C) 2013 - 2025 Efinix Inc. All rights reserved.

// This file may be used as a starting point for Efinity synthesis top-level target.
// The port list here matches what is expected by Efinity constraint files generated
// by the Efinity Interface Designer.

// To use this:
//     #1)  Save this file with a different name to a different directory, where source files are kept.
//              Example: you may wish to save as C:\swtools\MinGW\msys\1.0\home\jenkins\workspace\efx_CORE\install\project\pt_demo\pt_demo.v
//     #2)  Add the newly saved file into Efinity project as design file
//     #3)  Edit the top level entity in Efinity project to:  pt_demo
//     #4)  Insert design content.


module pt_demo
(
  (* syn_peri_port = 0 *) input pll_clkin,
  (* syn_peri_port = 0 *) input resetn,
  (* syn_peri_port = 0 *) input Fclk,
  (* syn_peri_port = 0 *) input Sclk,
  (* syn_peri_port = 0 *) input locked,
  (* syn_peri_port = 0 *) input Oclk,
  (* syn_peri_port = 0 *) output [3:0] Fled,
  (* syn_peri_port = 0 *) output [3:0] Oled,
  (* syn_peri_port = 0 *) output [3:0] Sled,
  (* syn_peri_port = 0 *) output [3:0] Sled_OE,
  (* syn_peri_port = 0 *) output pll_resetn
);


endmodule

