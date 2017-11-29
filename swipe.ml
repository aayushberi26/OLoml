open Pool
open Yojson.Basic

module type Swipe = sig
  type swipe_value
  type swipe_item
  type swipe_results
  val swipe : swipe_results -> swipe_item -> swipe_value option -> swipe_results
  val gen_swipe_results : swipe_results -> json
  val init_swipes : swipe_item list -> swipe_results
  val write_swipes : string -> string -> swipe_results -> bool
end

module MakeSwipe (T : TupleComparable) : Swipe
  with type swipe_item = T.item
  with type swipe_value = T.rank
= struct

  type swipe_item = T.item
  type swipe_value = T.rank
  type swipe_results = (swipe_item * swipe_value option) list

(* [updated_decision si d sid_tuple] gives the tuple (si,d) if
 * the first element of sid_tuple = si, or sid_tuple if it does not. *)
  let updated_decision si d sid_tuple =
    if fst sid_tuple = si then (si, d)
    else sid_tuple

  let swipe current_swipes si d =
    List.map (updated_decision si d) current_swipes

(* [lst_to_string lst] gives the string representation of lst.
 * each element is converted to a string using T's method for that type.
 * elements are separated by commas, and the list is surrounded by brackets. *)
  let rec lst_to_string = function
    | [] -> ""
    | h::m::t -> (T.opt_key_to_string h)^","^(lst_to_string (m::t))
    | h::t -> (T.opt_key_to_string h)^(lst_to_string (t))

  let gen_swipe_results s_results =
    let just_scores = List.map (fun (si,d) -> d) s_results in
    let str_lst = "["^(lst_to_string just_scores)^"]" in
    from_string str_lst

  let init_swipes s_lst =
    List.map (fun s -> (s, None)) s_lst

  let write_swipes net pwd s_results =
    let res_str = s_results |> gen_swipe_results |> to_string in
    match Loml_client.student_post net pwd res_str with
    | (`No_response, str) -> false
    | (`OK, str) -> true
    | _ -> failwith "impossible"

end

module SwipeStudentPool = MakeSwipe(StudentScores)
