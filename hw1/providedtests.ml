open Assert
open Hellocaml

(* These tests are provided by you -- they will be graded manually *)

(* You should also add additional test cases here to help you   *)
(* debug your program.                                          *)

let provided_tests : suite = [
  Test ("Student-Provided Tests For Problem 1-3", [
    ("case1", assert_eqf (fun () -> 42) prob3_ans );
    ("case2", assert_eqf (fun () -> 25) (prob3_case2 17) );
    ("case3", assert_eqf (fun () -> prob3_case3) 64);
  ]);

  Test ("Provided Test For Problem 4-4", [
    ("case1", assert_eqf (fun () -> interpret [("x", 1L); ("y", 2L)] (
      Mult (
        Var "x",
        Var "y"
      )
    )) 2L);
    ("case2", assert_eqf (fun () -> interpret ctxt2 (
      Mult (
        Var "x",
        Var "y"
      )
    )) 14L);
    ("case3", assert_eqf (fun () -> interpret ctxt2 (
      Mult (
        Add (
          Var "x",
          Var "y"
        ),
        Add (
          Const 10L,
          Const 1L
        )
      )
    )) 99L);
    ("case4", assert_eqf (fun () -> interpret [("x", 1L); ("y", 2L); ("x", 5L)] (
      Mult (
        Mult (
          Var "x",
          Var "x"
        ),
        Mult(
          Var "x",
          Var "x"
        )
      )
    )) 1L);
    ("case5", assert_eqf (fun () -> interpret [("x", 2L)] (
      Mult (
        Neg (
          Var "x"
        ),
        Neg (
          Var "x"
        )
      )
    )) 4L);
  ]);

  Test ("Provided Test For Problem 4-5", [
    ("case1", assert_eqf (fun () -> optimize (
      Add (
        Const 0L,
        Const 1L
      )
    )) (Const 1L));
    ("case2", assert_eqf (fun () -> optimize (
      Mult (
        Const 0L,
        Var "x"
      )
    )) (Const 0L));
    ("case3", assert_eqf (fun () -> optimize (
      Mult (
        Const 1L,
        Var "x"
      )
    )) (Var "x"));
    ("case4", assert_eqf (fun () -> optimize (
      Mult (
        (
          Add (
            (
              Neg (
                Neg (
                  Const 1L
                )
              )
            ),
            (Neg (
              Const 1L
            )
          )
        )
      ),
      Var "x")
    )) (Const 0L));
    ("case5", assert_eqf (fun () -> optimize (
      Add (
        Var "x",
        (
          Neg (
            Var "x"
          )
        )
      )
    )) (Const 0L));
    (*("case5", assert_eqf (fun () -> optimize (Add (Var "x", (Neg (Add (Var "x", (Neg (Const 1L)))))))) (Const 0L));*)
  ]);

  Test ("Provided Test For Problem 5", [
    ("case1", assert_eqf (fun () -> compile e1) p1);
    ("case2", assert_eqf (fun () -> (run ctxt1 (compile e1))) 6L);
    ("case3", assert_eqf (fun () -> (run ctxt1 (compile e2))) 4L);
    ("case4", assert_eqf (fun () -> (run [("x", 1L); ("y", 2L); ("x", 5L)] (compile (
      Mult (
        Mult (
          Var "x",
          Var "x"
          ),
        Mult(
          Var "x",
          Var "x"
        )
      )
    )))) 1L);
    ("case5", assert_eqf (fun () -> (run ctxt2 (compile (
      Mult (
        Add (
          Var "x",
          Var "y"
        ),
        Add (
          Const 10L,
          Const 1L
        )
      )
    )))) 99L);
    ("case6", assert_eqf (fun () -> (run ctxt1 (compile (
      Mult (
        (
          Add (
            (
              Neg (
                Neg (
                  Const 1L
                )
              )
            ),
            (
              Neg (
                Const 1L
              )
            )
          )
        ),
        Var "x"
      )
    )))) 0L);
    ("case3", assert_eqf (fun () -> (run ctxt2 (compile (
      Mult (
        Var "x",
        Var "y"
      )
    )))) 14L);
    ("case3", assert_eqf (fun () -> (run [("x", 1L); ("y", 2L)] (compile (
      Mult (
        Var "x",
        Var "y"
      )
    )))) 2L);
  ])
]

