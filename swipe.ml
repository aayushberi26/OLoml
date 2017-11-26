open Pool
open Yojson.Basic

module type Swipe = sig
  (* exposed so people can input decisions? *)

  type swipe_value

  type swipe_item

  type swipe_results

  val swipe : swipe_results -> swipe_item -> swipe_value option -> swipe_results

  val gen_swipe_results : swipe_results -> json

  val init_swipes : swipe_item list -> swipe_results
end

module MakeSwipe (T : TupleComparable) : Swipe
  with type swipe_item = T.value
  with type swipe_value = T.key
= struct

  type swipe_item = T.value

  type swipe_value = T.key
  (* identifying student + decision for each netid in class *)
  type swipe_results = (swipe_item * swipe_value option) list

  (* updates decision for a single (swipe_item, decision) tuple *)
  let updated_decision si d sid_tuple =
    if fst sid_tuple = si then (fst sid_tuple, d)
    else sid_tuple

  let swipe current_swipes si d =
    List.map (updated_decision si d) current_swipes

  let rec lst_to_string = function
    | [] -> ""
    | h::m::t -> (T.opt_key_to_string h)^"0,"^(lst_to_string (m::t))
    | h::t -> (T.opt_key_to_string h)^"0"^(lst_to_string (t))

  let gen_swipe_results s_results =
    let just_scores = List.map (fun (si,d) -> d) s_results in
    let str_lst = "["^(lst_to_string just_scores)^"]" in
    from_string str_lst

  let init_swipes s_lst =
    List.map (fun s -> (s, None)) s_lst

end

module SwipeStudentPool = MakeSwipe(StudentScores)
