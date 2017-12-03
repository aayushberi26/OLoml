open Yojson.Basic
open Mysql
module P = Mysql.Prepared
open Printf

let db = quick_connect ~host:("localhost") ~port:(3306) ~database:("test") ~user:("root") ~password:("admin123") ()

(*Table names
let stu_tbl = "students"
let match_tbl = "matches"
let creds_tbl = "credentials"
let periods_tbl = "periods"
*)

let check_cred_query netid pwd =
  let select = P.create db ("SELECT password FROM credentials WHERE netid = ?") in
  let t1 = P.execute_null select [|Some netid|] in
    match P.fetch t1 with
    | Some arr ->
      begin match Array.get arr 0 with
        |Some n -> n = pwd
        |None -> false
      end
    | None -> false

let check_period_set =
  let select = P.create db ("SELECT * FROM periods") in
  let t1 = P.execute_null select [||] in
  match (P.fetch t1) with
  | Some arr ->
    if Array.mem None arr then false else true
  | None -> false
  (*
  if ((PGSQL(dbh) "SELECT Update FROM $periods_tbl") != None
      ||  (PGSQL(dbh) "SELECT Swipe FROM $periods_tbl") != None
      ||  (PGSQL(dbh) "SELECT Match FROM $periods_tbl") != None) then true
  else false
*)

let set_period_query periods =
  let jsn = from_string periods in
  let update_dt = jsn |> Util.member "update" |> Util.to_float_option in
  let swipe_dt = jsn |> Util.member "swipe" |> Util.to_float_option in
  let match_dt = jsn |> Util.member "match" |> Util.to_float_option in
  match (update_dt, swipe_dt, match_dt) with
  |(Some u , Some s , Some m) ->
    if check_period_set = false then
      let insert = P.create db ( "INSERT INTO periods VALUES (?,?,?)") in
        ignore (P.execute insert [|ml2float u;ml2float s;ml2float m|])
    else ()
  |_ -> ()

  (*
      PGSQL(dbh) "INSERT INTO $periods_tbl (Update, Swipe, Match)
      VALUES ($update_dt, $swipe_dt, $match_dt)" *)

let get_period_query =
  let select = P.create db ("SELECT * FROM periods") in
  let t1 = P.execute_null select [||] in
    match P.fetch t1 with
    | Some arr ->
      begin match (Array.get arr 0, Array.get arr 1, Array.get arr 2) with
        |(Some u, Some s, Some m) ->
          let upd = ("update", `String u) in
          let mat = ("match", `String m) in
          let swi = ("swipe", `String s) in
          let jsonobj = `Assoc[upd;swi;mat] in Yojson.Basic.to_string jsonobj
        |_ ->
          let upd = ("update", `Null) in
          let mat = ("match", `Null) in
          let swi = ("swipe", `Null) in
          let jsonobj = `Assoc[upd;swi;mat] in Yojson.Basic.to_string jsonobj
      end
    | None ->
      let upd = ("update", `Null) in
      let mat = ("match", `Null) in
      let swi = ("swipe", `Null) in
      let jsonobj = `Assoc[upd;swi;mat] in Yojson.Basic.to_string jsonobj

let get_student_query netid =
  let select = P.create db ("SELECT * FROM students WHERE netid = ?") in
  let t1 = P.execute_null select [|Some netid|] in
    match P.fetch t1 with
    | Some arr ->
      begin match (Array.get arr 0, Array.get arr 1, Array.get arr 2,
                   Array.get arr 3, Array.get arr 4, Array.get arr 5,
                   Array.get arr 6,Array.get arr 7) with
      |(Some jnetid,Some jname,Some jyr,Some jsched,Some jcourses,
        Some jhrs,Some jprof,Some jloc) ->
          let name = ("name", `String jname) in
          let netid = ("netid", `String jnetid) in
          let year = ("year", `String jyr) in
          let sched = ("schedule", `String jsched) in
          let courses = ("courses_taken", `String jcourses) in
          let hrs = ("hours_to_spend", `String jhrs) in
          let prof = ("profile_text", `String jprof) in
          let loc = ("location", `String jloc) in
          let jsonobj = `Assoc[name;netid;year;sched;courses;hrs;prof;loc] in
          Yojson.Basic.to_string jsonobj
        |_ ->
          let name = ("name", `Null) in
          let netid = ("netid", `Null) in
          let year = ("year", `Null) in
          let sched = ("schedule", `Null) in
          let courses = ("courses_taken", `Null) in
          let hrs = ("hours_to_spend", `Null) in
          let prof = ("profile_text", `Null) in
          let loc = ("location", `Null) in
          let jsonobj = `Assoc[name;netid;year;sched;courses;hrs;prof;loc] in
          Yojson.Basic.to_string jsonobj
      end
  | None ->
    let name = ("name", `Null) in
    let netid = ("netid", `Null) in
    let year = ("year", `Null) in
    let sched = ("schedule", `Null) in
    let courses = ("courses_taken", `Null) in
    let hrs = ("hours_to_spend", `Null) in
    let prof = ("profile_text", `Null) in
    let loc = ("location", `Null) in
    let jsonobj = `Assoc[name;netid;year;sched;courses;hrs;prof;loc] in
    Yojson.Basic.to_string jsonobj

let get_stu_match_query netid =
  let select = P.create db ("SELECT stu2 FROM matches WHERE netid = ?") in
  let t1 = P.execute_null select [|Some netid|] in
    match P.fetch t1 with
    | Some arr ->
      begin match Array.get arr 0 with
        |Some n ->
          if n = "UNMATCHED" then
            let name = ("name", `Null) in
            let netid = ("netid", `String "UNMATCHED") in
            let year = ("year", `Null) in
            let sched = ("schedule", `Null) in
            let courses = ("courses_taken", `Null) in
            let hrs = ("hours_to_spend", `Null) in
            let prof = ("profile_text", `Null) in
            let loc = ("location", `Null) in
            let jsonobj = `Assoc[name;netid;year;sched;courses;hrs;prof;loc] in
            Yojson.Basic.to_string jsonobj
          else get_student_query n
        |None ->
          let name = ("name", `Null) in
          let netid = ("netid", `Null) in
          let year = ("year", `Null) in
          let sched = ("schedule", `Null) in
          let courses = ("courses_taken", `Null) in
          let hrs = ("hours_to_spend", `Null) in
          let prof = ("profile_text", `Null) in
          let loc = ("location", `Null) in
          let jsonobj = `Assoc[name;netid;year;sched;courses;hrs;prof;loc] in
          Yojson.Basic.to_string jsonobj
      end
    | None ->
      let name = ("name", `Null) in
      let netid = ("netid", `Null) in
      let year = ("year", `Null) in
      let sched = ("schedule", `Null) in
      let courses = ("courses_taken", `Null) in
      let hrs = ("hours_to_spend", `Null) in
      let prof = ("profile_text", `Null) in
      let loc = ("location", `Null) in
      let jsonobj = `Assoc[name;netid;year;sched;courses;hrs;prof;loc] in
      Yojson.Basic.to_string jsonobj

(*helper functions that change each specific field if the field exists in the
 * json *)
let change_sched net info =
  let jsn = from_string info in
  begin match jsn |> Util.member "schedule" |> Util.to_string_option with
    |None -> ()
    |i -> PGSQL(dbh) "INSERT INTO students (schedule) VALUES ($i)
                WHERE Netid = $net"
  end

  let change_courses net info =
    let jsn = from_string info in
    begin match jsn |> Util.member "classes_taken" |> Util.to_string_option with
      |None -> ()
      |i -> PGSQL(dbh) "UPDATE $stu_tbl SET Courses = $i WHERE Netid = $net"
    end

  let change_hours net info =
    let jsn = from_string info in
    begin match jsn |> Util.member "hours_to_spend" |> Util.to_int_option with
      |None -> ()
      |i -> PGSQL(dbh) "UPDATE $stu_tbl SET Hours = $i WHERE Netid = $net"
    end

  let change_prof net info =
    let jsn = from_string info in
    begin match jsn |> Util.member "profile_text" |> Util.to_string_option with
      |None -> ()
      |i -> PGSQL(dbh) "UPDATE $stu_tbl SET Profile = $i WHERE Netid = $net"
    end

  let change_loc net info =
    let jsn = from_string info in
    begin match jsn |> Util.member "location" |> Util.to_string_option with
      |None -> ()
      |i -> PGSQL(dbh) "UPDATE $stu_tbl SET Location = $i WHERE Netid = $net"
    end

let change_stu_query net info =
  let a = change_sched dbh net info in
  let b = change_courses dbh net info in
  let c = change_hours dbh net info in
  let d = change_prof dbh net info in
  let e = change_loc dbh net info in
  match [a;b;c;d;e] with
  |_ -> ()

let admin_change_query info =
  let jsn = from_string info in
  let new_name = jsn |> Util.member "name" |> Util.to_string_option in
  let new_id = jsn |> Util.member "netid" |> Util.to_string_option in
  let new_year = jsn |> Util.member "year" |> Util.to_string_option in
  PGSQL(dbh) "INSERT INTO $stu_tbl (Netid, Name, Year) VALUES
    ($new_id, $new_name, $new_year) ON DUPLICATE KEY UPDATE
    Name = $new_name, Year = $new_year"

let reset_class =
  PGSQL(dbh) "TRUNCATE $stu_tbl, $match_tbl, $creds_tbl, $periods_tbl"
