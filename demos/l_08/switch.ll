
; ret = 5
; switch (s)
;   case 1:
;     ret = 2
;
;   case 2:
;     ret = 42
;      break;
;
;  return ret

define i32 @switch(i32 %s) {
  %ret_ptr = alloca i32
  store i32 5, i32* %ret_ptr

  ; if s == 1
  %is_s_eq_one = icmp eq i32 %s, 1
  br i1 %is_s_eq_one, label %case_one, label %try_two

  ; if s == 2
try_two:
  %is_s_eq_two = icmp eq i32 %s, 2
  br i1 %is_s_eq_two, label %case_two, label %exit

case_one:
  store i32 2, i32* %ret_ptr
  br label %case_two

case_two:
  store i32 42, i32* %ret_ptr
  br label %exit

exit:
  ret i32 0
}
