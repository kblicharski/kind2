(* This file is part of the Kind 2 model checker.

   Copyright (c) 2014 by the Board of Trustees of the University of Iowa

   Licensed under the Apache License, Version 2.0 (the "License"); you
   may not use this file except in compliance with the License.  You
   may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0 

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
   implied. See the License for the specific language governing
   permissions and limitations under the License. 

*)

open Lib

type source = 
  | Lustre of LustreNode.t list 
  | Native 

(* Global is_init state var *)
let is_init_svar =
  StateVar.mk_state_var "x_is_init_x" [] Type.t_bool

(* Global is_init uf *)
let is_init_uf =
  StateVar.uf_symbol_of_state_var is_init_svar

(* Instantiate is_init at k *)
let is_init_var = Var.mk_state_var_instance is_init_svar

let _ = LustreExpr.set_state_var_source is_init_svar LustreExpr.Abstract


type pred_def = (UfSymbol.t * (Var.t list * Term.t)) 

type prop_status =

  (* Status of property is unknown *)
  | PropUnknown

  (* Property is true for at least k steps *)
  | PropKTrue of int

  (* Property is true in all reachable states *)
  | PropInvariant 

  (* Property is false at some step *)
  | PropFalse of (StateVar.t * Term.t list) list


(* Return the length of the counterexample *)
let length_of_cex = function 

  (* Empty counterexample has length zero *)
  | [] -> 0

  (* Length of counterexample from first state variable *)
  | (_, l) :: _ -> List.length l


let pp_print_prop_status_pt ppf = function 
  | PropUnknown -> Format.fprintf ppf "unknown"
  | PropKTrue k -> Format.fprintf ppf "true-for %d" k
  | PropInvariant -> Format.fprintf ppf "invariant"
  | PropFalse [] -> Format.fprintf ppf "false"
  | PropFalse cex -> Format.fprintf ppf "false-at %d" (length_of_cex cex)


(* Property status is known? *)
let prop_status_known = function 

  (* Property may become invariant or false *)
  | PropUnknown
  | PropKTrue _ -> false

  (* Property is invariant or false *)
  | PropInvariant
  | PropFalse _ -> true


(* Offset of state variables in initial state constraint *)
let init_base = Numeral.zero

(* Offset of primed state variables in transition relation *)
let trans_base = Numeral.one

(* Offset of primed state variables in properties and invariants *)
let prop_base = Numeral.zero


type t = {
  
  (* Scope of state variables *)
  scope: string list;

  (* Init and trans pairs of this system and its subsystems in
     topological order. *)
  uf_defs: (pred_def * pred_def) list ;

  (* State variables of top node *)
  state_vars: StateVar.t list ;

  (* Initial predicate of the system. *)
  init: pred_def ;

  (* Transition predicate of the system. *)
  trans: pred_def ;

  (* The subsystems of this system. *)
  subsystems: t list ;

  (* Properties to hopefully prove invariant. *)
  props: (string * Term.t) list ;

  (* The source which produced this system. *)
  source: source ;

  (* Invariants *)
  mutable invars: Term.t list ;

  (* Status of property *)
  mutable prop_status: (string * prop_status) list ;

  (* Associates a system instantiating this system with a map from the
     variables of this system to the argument of the instantiation in
     the over-system. *)
  mutable instantiation_maps: (t * ((StateVar.t * Term.t) list list)) list

}
           
           

(* Return the predicate for the initial state constraint *)
let init_uf_symbol { init = (s, _) } = s

(* Return the predicate for the transition relation *)
let trans_uf_symbol { trans = (s, _) } = s

(* Return the variables in the initial state constraint *)
let init_vars { init = (_, (v, _)) } = v

(* Return the variables in the transition relation *)
let trans_vars { trans = (_, (v, _)) } = v

(* Return the definition of the initial state constraint *)
let init_term { init = (_, (_, t)) } = t

(* Return the definition of the transition relation *)
let trans_term { trans = (_, (_, t)) } = t

(* Prints the instantiation maps of a transition system. *)
let print_instantiation_maps { instantiation_maps } =
  (* Turns a map from state vars to terms into a string. *)
  let string_of_map map =
    map
    |> List.map
         ( fun (v,t) ->
           Printf.sprintf "(%s -> %s)"
                          (StateVar.string_of_state_var v)
                          (Term.string_of_term t) )
    |> String.concat ", "
  in
  
  instantiation_maps
  |> List.map
       (fun (sub,maps) ->
        Printf.printf "  Mapping to [%s]:\n"
                      (String.concat "/" sub.scope) ;
        maps
        |> List.iter
             ( fun map ->
               Printf.printf "  > %s\n" (string_of_map map) ) ;
        Printf.printf "\n")

(* Adds an instantiation map (subsystem / var association pair) to a
   system. *)
let add_instantiation_map t (sys', map) =
  
  let rec loop prefix = function

    | (sys, maps) :: tail when sys.scope = sys'.scope ->
       (* Adding the new maps. *)
       (sys, map :: maps) :: tail
       |> List.rev_append prefix
         
    | head :: tail ->
       loop (head :: prefix) tail

    (* The new map was not in here, adding it. *)
    | [] -> (sys',[map]) :: prefix
  in

  t.instantiation_maps <- (loop [] t.instantiation_maps)


(* Instantiates a term for all systems instantiating the input
   system. *)
let instantiate_term { instantiation_maps } term =

  (* Gets the term corresponding to 'var' in 'map' and bumps it if
     'var' is not a constant. Raises Not_found if 'var' is not defined
     in 'map'. *)
  let term_of_var map var =
    
    (* Getting the state variable. *)
    let sv = Var.state_var_of_state_var_instance var in
    (* Getting corresponding term. *)
    let term = List.assq sv map in
    
    (* Checking if we need to bump. *)
    if Var.is_const_state_var var
    then (* We don't. *)
      term
    else ( (* We do. *)
      (* Bumping by the offset of 'var'. *)
      Term.bump_state
        (Var.offset_of_state_var_instance var)
        term
    )
  in

  (* Instantiates variables according to map. *)
  let substitute_fun_of_map map =
    (* This function is for Term.map. The first argument is the de
       Bruijn index and is ignored. *)
    ( fun _ term ->

      (* Is the term a free variable?. *)
      if Term.is_free_var term
                          
      then
        
        try
          (* Extracting state variable. *)
          Term.free_var_of_term term
          (* Getting corresponding term, bumping if
                           necessary. *)
          |> term_of_var map

        with
          (* Variable is not in map, nothing to do. *)
          Not_found -> term

      else
        (* Term is not a var, nothing to do. *)
        term )
  in

  instantiation_maps
  |> List.map
       ( fun (sys, maps) ->
         
         (* Building one new term per instantiation mapping for
            sys. *)
         let terms =
           maps
           |> List.map
                (* For each map of this over-system, substitute the
                   variables of term according to map. *)
                ( fun map ->
                  Term.map
                    (substitute_fun_of_map map)
                    term )
         in

         sys, terms )


(* Instantiates a term for the top system by going up the system
   hierarchy, for all instantiations of the input system. *)
let instantiate_term_top t term =

  let rec loop at_top = function
      
    | (sys, ((term :: term_tail) as list)) :: tail ->
       
       (* Instantiating this term upward. *)
       ( match instantiate_term sys term with
           
         | [] ->
            (* Nothing, so sys is the top node. *)
            loop (List.rev_append list at_top)
                 tail

         | list' ->
            (* Sys is not the top node. *)
            loop at_top
                 (List.rev_append
                    (* Looping on the new (sys,terms) pairs... *)
                    list'
                    (* ...and the (sys,terms) pairs we haven't looked
                       at yet. *)
                    ((sys, term_tail)
                     :: tail)) )
         
    | (sys, []) :: tail -> loop at_top tail
                                
    | [] -> at_top
  in

  loop [] (instantiate_term t term)


(* Returns the subsystems of a system. *)
let get_subsystems { subsystems } = subsystems


let pp_print_state_var ppf state_var = 

  Format.fprintf ppf
    "@[<hv 1>(%a %a)@]" 
    StateVar.pp_print_state_var state_var
    Type.pp_print_type (StateVar.type_of_state_var state_var)

  
let pp_print_var ppf var = 

  Format.fprintf ppf
    "@[<hv 1>(%a %a)@]" 
    Var.pp_print_var var
    Type.pp_print_type (Var.type_of_var var)
  

let pp_print_uf_def ppf (uf_symbol, (vars, term)) =

  Format.fprintf 
    ppf   
    "@[<hv 1>(%a@ @[<hv 1>(%a)@]@ %a)@]"
    UfSymbol.pp_print_uf_symbol uf_symbol
    (pp_print_list pp_print_var "@ ") vars
    Term.pp_print_term term

let pp_print_uf_defs 
    ppf
    ((init_uf_symbol, (init_vars, init_term)), 
     (trans_uf_symbol, (trans_vars, trans_term))) = 

  Format.fprintf ppf
    "@[<hv 2>(define-pred-init@ %a@ @[<hv 2>(%a)@]@ %a)@]@,\
     @[<hv 2>(define-pred-trans@ %a@ @[<hv 2>(%a)@]@ %a)@]"
    UfSymbol.pp_print_uf_symbol init_uf_symbol
    (pp_print_list pp_print_var "@ ") init_vars
    Term.pp_print_term init_term
    UfSymbol.pp_print_uf_symbol trans_uf_symbol
    (pp_print_list pp_print_var "@ ") trans_vars
    Term.pp_print_term trans_term


let pp_print_prop ppf (prop_name, prop_term) = 

  Format.fprintf 
    ppf
    "@[<hv 1>(%s@ %a)@]"
    prop_name
    Term.pp_print_term prop_term

let pp_print_prop_status ppf (p, s) =
  Format.fprintf ppf "@[<hv 2>(%s %a)@]" p pp_print_prop_status_pt s


(* Determine the required logic for the SMT solver 

   TODO: Fix this to QF_UFLIA for now, dynamically determine later *)
let get_logic _ = ((Flags.smtlogic ()) :> SMTExpr.logic)


(* Return the state variables of the transition system *)
let state_vars t = t.state_vars

(* Return the input used to create the transition system *)
let get_source t = t.source

(* Return the input used to create the transition system *)
let get_scope t = t.scope

(* Create a transition system *)
let mk_trans_sys scope state_vars init trans subsystems props source = 

  (* Create constraints for integer ranges *)
  let invars_of_types = 
    
    List.fold_left 
      (fun accum state_var -> 

         (* Type of state variable *)
         match StateVar.type_of_state_var state_var with
           
           (* Type is a bounded integer *)
           | sv_type when Type.is_int_range sv_type -> 
             
             (* Get lower and upper bounds *)
             let l, u = Type.bounds_of_int_range sv_type in

             (* Add equation l <= v[0] <= u to invariants *)
             Term.mk_leq 
               [Term.mk_num l; 
                Term.mk_var
                  (Var.mk_state_var_instance state_var Numeral.zero); 
                Term.mk_num u] :: 
             accum
           | _ -> accum)
      []
      state_vars
  in

  (* Goes through the subsystems and constructs the list of
     uf_defs. *)
  let rec get_uf_defs result = function
    | { uf_defs } :: tail ->

       (* Removing uf_defs of the subsystem from the result to ensure
          topological order. *)
       let result' =
         result
         |> List.filter
              ( fun pair ->
                not (List.mem pair uf_defs) )
       in

       get_uf_defs
         (* Adding uf_defs of the subsystem to the result. *)
         (List.concat [ uf_defs ; result' ])
         tail

    | [] -> result
  in

  (* Looks in the subsystems for one such that 'f' applied to the
     subsys is uf. *)
  let find_subsystem f uf =
    List.find (fun subsys -> uf = f subsys) subsystems
  in

  (* Checks if a flat term is an application of a uf such that 'f' on
     a subsystem. Returns Some of the subsystem if yes, None
     otherwise. *)
  let is_flat_uf_such_that f = function
      
    | Term.T.App (sym,params) when Symbol.is_uf sym ->
       ( try Some (Symbol.uf_of_symbol sym |> find_subsystem f,
                   params)
         with Not_found -> None )
         
    | Term.T.Const sym when Symbol.is_uf sym ->
       ( try Some (Symbol.uf_of_symbol sym |> find_subsystem f,
                   [])
         with Not_found -> None )

    | _ -> None
  in

  (* Builds a mapping from vars@0 to terms. Inputs 'vars' and 'terms'
     come from init and trans and therefore need to be bumped. *)
  let build_mapping vars terms =
    (* Making sure both lists are the same length. *)
    assert ( (List.length vars) = (List.length terms) ) ;

    let rec loop map = function
        
      | v :: v_tail, t :: t_tail ->
         (* Bump value necessary to get the var to 0. *)
         let bump_val =
           if Var.is_const_state_var v then Numeral.zero
           else
             Numeral.(~- (Var.offset_of_state_var_instance v))
         in

         (* Getting the statevar and bumping the term. *)
         let state_var, bumped_t =
           Var.state_var_of_state_var_instance v,
           Term.bump_state bump_val t
         in

         (* Building the new map. *)
         let map' =
           try
             (* If the var is already mapped to a term... *)
             let mapped_to = List.assoc state_var map in
             (* ... then it should be the same term... *)
             assert ( mapped_to == bumped_t ) ;
             (* ... and we leave the map as it is. *)
             map
           with
             Not_found ->
             (* If the var is not mapped then we add the mapping. *)
             (state_var, bumped_t) :: map
         in

         loop map' (v_tail, t_tail)
           
      | [], [] -> map
                    
      | _ -> failwith "The universe is collapsing."
    in

    loop [] (vars, terms)
  in

  let print_map =
    (* Turns a map from state vars to terms into a string. *)
    let string_of_map map =
      map
      |> List.map
           ( fun (v,t) ->
             Printf.sprintf "(%s -> %s)"
                            (StateVar.string_of_state_var v)
                            (Term.string_of_term t) )
      |> String.concat ", "
    in
    
    List.map
      (fun (sub,map) ->
       Printf.printf "  Mapping to [%s]:\n"
                     (String.concat "/" sub.scope) ;
       Printf.printf "  > %s\n\n" (string_of_map map) )
  in

  (* Going through init to find instantiations of subsystems. *)
  let init_maps = match init with
    | (_, (_, init_term)) ->
       init_term
       |> Term.eval_t
            ( fun op maps ->
              match is_flat_uf_such_that init_uf_symbol op with
              | None ->  List.concat maps
              | Some (sub,params) ->
                 (sub, build_mapping (init_vars sub) params)
                 :: (List.concat maps) )
  in

  (* Going through trans to find instantiations of subsystems. *)
  let trans_maps = match trans with
    | (_, (_, trans_term)) ->
       trans_term
       |> Term.eval_t
            ( fun op maps ->
              match is_flat_uf_such_that trans_uf_symbol op with
              | None ->  List.concat maps
              | Some (sub,params) ->
                 (sub, build_mapping (trans_vars sub) params)
                 :: (List.concat maps) )
  in

  (* Crashes if two maps are not the same. *)
  let rec map_eq = function
    | (var, term) :: tail, (var', term') :: tail' ->
       assert (var == var') ;
       assert (term == term') ;
       map_eq (tail,tail')
    | [], [] -> ()
    | _ -> assert false
  in

  (* Crashes if two association lists between subsystems and mappings
     are not the same. *)
  let rec maps_eq = function
    | (sub, map) :: tail, (sub', map') :: tail' ->
       assert ( (sub.scope) = (sub'.scope) ) ;
       map_eq (map, map') ;
       maps_eq (tail, tail')
    | [], [] -> ()
    | [], map ->
       Printf.printf "Trans map is not []:\n" ;
       print_map map ;
       assert false
    | map, [] ->
       Printf.printf "Init map is not []:\n" ;
       print_map map ;
       assert false
  in

  (* Making sure init and trans mappings are the same. *)
  maps_eq (init_maps, trans_maps) ;

  let system =
    { scope = scope;
      uf_defs = get_uf_defs [ (init, trans) ] subsystems ;
      state_vars =
        is_init_svar :: state_vars
        |> List.sort StateVar.compare_state_vars ;
      init = init ;
      trans = trans ;
      props = props ;
      subsystems = subsystems ;
      source = source ;
      prop_status = List.map (fun (n, _) -> (n, PropUnknown)) props ;
      invars = invars_of_types ;
      instantiation_maps = [] }
  in

  (* Adding instantiation maps to subsystems. *)
  init_maps
  |> List.iter
       ( fun (sub,map) -> add_instantiation_map sub (system,map) ) ;
  system

(* Return the variables of the transition system between given instants *)
let rec vars_of_bounds' trans_sys lbound ubound accum = 

  (* Return when upper bound below lower bound *)
  if Numeral.(ubound < lbound)
  then accum
  else
    trans_sys.state_vars

    (* Add state variables at upper bound instant  *)
    |> List.fold_left
         ( fun accum sv -> 
           Var.mk_state_var_instance sv ubound :: accum )
         accum

    (* Recurse to next lower bound *)
    |> vars_of_bounds' trans_sys lbound (Numeral.pred ubound)

let vars_of_bounds trans_sys lbound ubound = 
  vars_of_bounds' trans_sys lbound ubound []



(* Instantiate the initial state constraint to the bound *)
let init_of_bound t i = 

  let init_term =
    Term.mk_and [
        (* Get term of initial state constraint *)
        init_term t ;
        (* Adding is_init. *)
        Term.mk_var (is_init_var Numeral.zero) ]
  in

  (* Bump bound if greater than zero *)
  if Numeral.(i = zero)
  then init_term
  else Term.bump_state i init_term


(* Instantiate the transition relation to the bound. *)
let trans_of_bound t i = 

  let trans_term =
    Term.mk_and [
        (* Get term of transition predicate. *)
        trans_term t ;
        (* The next state cannot be initial. *)
        (is_init_var Numeral.one |> Term.mk_var |> Term.mk_not) ]
  in

  (* Bump bound if greater than zero *)
  if Numeral.(i = one)
  then trans_term 
  else Term.bump_state (Numeral.(i - one)) trans_term


(* Instantiate the initial state constraint to the bound *)
let invars_of_bound t i = 

  (* Create conjunction of property terms *)
  let invars_0 = Term.mk_and t.invars in 

  (* Bump bound if greater than zero *)
  if Numeral.(i = zero) then invars_0 else Term.bump_state i invars_0


(* Instantiate terms in association list to the bound *)
let named_terms_list_of_bound l i = 

  (* Bump bound if greater than zero *)
  if
    Numeral.(i = zero)
  then
    l
  else
    List.map (fun (n, t) -> (n, Term.bump_state i t)) l


(* Instantiate all properties to the bound *)
let props_list_of_bound t i = 
  named_terms_list_of_bound t.props i


(* Instantiate all properties to the bound *)
let props_of_bound t i = 
  Term.mk_and (List.map snd (props_list_of_bound t i))

(* Get property by name *)
let prop_of_name t name =
  List.assoc name t.props 

(* Add an invariant to the transition system *)
let add_invariant t invar = t.invars <- invar :: t.invars


(* Return current status of all properties *)
let get_prop_status_all t = t.prop_status

(* Return current status of all properties *)
let get_prop_status_all_unknown t = 

  List.filter
    (fun (_, s) -> not (prop_status_known s))
    t.prop_status


(* Return current status of property *)
let get_prop_status trans_sys p = 

  try 

    List.assoc p trans_sys.prop_status

  with Not_found -> PropUnknown


(* Mark property as invariant *)
let set_prop_invariant t prop =

  t.prop_status <- 
    
    List.map 

      (fun (n, s) -> if n = prop then 

          match s with
            
            (* Mark property as invariant if it was unknown, k-true or
               invariant *)
            | PropUnknown
            | PropKTrue _
            | PropInvariant -> (n, PropInvariant) 
                               
            (* Fail if property was false or k-false *)
            | PropFalse _ -> raise (Failure "prop_invariant") 

        else (n, s))

      t.prop_status


(* Mark property as k-false *)
let set_prop_false t prop cex =

  t.prop_status <- 

    List.map 

      (fun (n, s) -> if n = prop then 

          match s with

            (* Mark property as k-false if it was unknown, l-true for l <
               k or invariant *)
            | PropUnknown -> (n, PropFalse cex)

            (* Fail if property was invariant *)
            | PropInvariant -> 
              raise (Failure "prop_false")

            (* Fail if property was l-true for l >= k *)
            | PropKTrue l when l > (length_of_cex cex) -> 
              raise (Failure "prop_false")

            (* Mark property as false if it was l-true for l < k *)
            | PropKTrue _ -> (n, PropFalse cex)

            (* Keep if property was l-false for l <= k *)
            | PropFalse cex' when (length_of_cex cex') <= (length_of_cex cex) -> 
              (n, s)

            (* Mark property as k-false *)
            | PropFalse _ -> (n, PropFalse cex) 

        else (n, s))

      t.prop_status


(* Mark property as k-true *)
let set_prop_ktrue t k prop =

  t.prop_status <- 

    List.map 

      (fun (n, s) -> if n = prop then 

          match s with

            (* Mark as k-true if it was unknown *)
            | PropUnknown -> (n, PropKTrue k)

            (* Keep if it was l-true for l > k *)
            | PropKTrue l when l > k -> (n, s)

            (* Mark as k-true if it was l-true for l <= k *)
            | PropKTrue _ -> (n, PropKTrue k)

            (* Keep if it was invariant *)
            | PropInvariant -> (n, s)

            (* Keep if property was l-false for l > k *)
            | PropFalse cex when (length_of_cex cex) > k -> (n, s)

            (* Fail if property was l-false for l <= k *)
            | PropFalse _ -> 
              raise (Failure "prop_kfalse") 

        else (n, s))

      t.prop_status


(* Mark property status *)
let set_prop_status t p = function

  | PropUnknown -> ()

  | PropKTrue k -> set_prop_ktrue t k p

  | PropInvariant -> set_prop_invariant t p

  | PropFalse c -> set_prop_false t p c


(* Return true if the property is proved invariant *)
let is_proved t prop = 

  try 
    ( match List.assoc prop t.prop_status with
      | PropInvariant -> true
      | _ -> false )
        
  with
    Not_found -> false


(* Return true if the property is proved not invariant *)
let is_disproved t prop = 

  try 
    ( match List.assoc prop t.prop_status with
      | PropFalse _ -> true
      | _ -> false )
        
  with
    Not_found -> false



(* Return true if all properties are either valid or invalid *)
let all_props_proved t =

  List.for_all
    (fun (p, _) -> 
       try 
         (match List.assoc p t.prop_status with
           | PropUnknown
           | PropKTrue _ -> false
           | PropInvariant
           | PropFalse _ -> true)
       with Not_found -> false)
    t.props

(* Return declarations for uninterpreted symbols *)
let uf_symbols_of_trans_sys { state_vars } = 
  List.map StateVar.uf_symbol_of_state_var state_vars

(* Return uninterpreted function symbol definitions sorted by
   topological order. *)
let uf_defs { uf_defs } =
  uf_defs
  |> List.fold_left
       ( fun list (init,trans) ->
         (* We'll reverse for topological order, so trans is first. *)
         trans :: init :: list )
       []
  (* Reversing for topological order. *)
  |> List.rev

(* Return uninterpreted function symbol definitions as pairs of
   initial state and transition relation definitions sorted by
   topological order. *)
let uf_defs_pairs { uf_defs } = uf_defs
         
  


let pp_print_trans_sys 
    ppf
    ({ uf_defs;
       state_vars;
       props;
       invars;
       prop_status; 
       source } as trans_sys) = 

  Format.fprintf 
    ppf
    "@[<v>@[<hv 2>(state-vars@ (@[<v>%a@]))@]@,\
          %a@,\
          @[<hv 2>(init@ (@[<v>%a@]))@]@,\
          @[<hv 2>(trans@ (@[<v>%a@]))@]@,\
          @[<hv 2>(props@ (@[<v>%a@]))@]@,\
          @[<hv 2>(invar@ (@[<v>%a@]))@]@,\
          @[<hv 2>(status@ (@[<v>%a@]))@]@,\
          @[<hv 2>;; (source@ (@[<v>%a@]))@]@."
    (pp_print_list pp_print_state_var "@ ") state_vars
    (pp_print_list pp_print_uf_defs "@ ") (uf_defs)
    Term.pp_print_term (init_term trans_sys)
    Term.pp_print_term (trans_term trans_sys)
    (pp_print_list pp_print_prop "@ ") props
    (pp_print_list Term.pp_print_term "@ ") invars
    (pp_print_list pp_print_prop_status "@ ") prop_status
    (pp_print_list (fun ppf { LustreNode.name } -> LustreIdent.pp_print_ident false ppf name) "@ ") (match source with Lustre l -> l | _ -> [])

 

(* Return [true] if the uninterpreted symbol is an initial state constraint *)
let is_init_uf_def { uf_defs } uf_symbol = 

  uf_defs
  |> List.exists
       (function ((i, _), _) ->
                 UfSymbol.equal_uf_symbols uf_symbol i)

(* Return [true] if the uninterpreted symbol is a transition relation *)
let is_trans_uf_def { uf_defs } uf_symbol = 

  uf_defs
  |> List.exists
       (function (_, (t, _)) ->
                 UfSymbol.equal_uf_symbols uf_symbol t)
 

(* Apply [f] to all uninterpreted function symbols of the transition
   system *)
let iter_state_var_declarations { state_vars } f = 
  List.iter (fun sv -> f (StateVar.uf_symbol_of_state_var sv)) state_vars
  
(* Apply [f] to all function definitions of the transition system *)
let iter_uf_definitions t f = 
  uf_defs_pairs t
  |> List.iter 
       (fun ((ui, (vi, ti)), (ut, (vt, tt))) -> f ui vi ti; f ut vt tt)
  

(* Extract a path in the transition system, return an association list
   of state variables to a list of their values *)
let path_from_model trans_sys get_model k =

  let rec path_from_model' accum state_vars = function 

    (* Terminate after the base instant *)
    | i when Numeral.(i < zero) -> accum

    | i -> 

      (* Get a model for the variables at instant [i] *)
      let model =
        get_model
          (List.map (fun sv -> Var.mk_state_var_instance sv i) state_vars)
      in

      (* Turn variable instances to state variables and sort list 

         TODO: It is not necessary to sort the list, if the SMT solver
         returns the list in the order it was input. *)
      let model' =
        List.sort
          (fun (sv1, _) (sv2, _) -> StateVar.compare_state_vars sv1 sv2)
          (List.map
             (fun (v, t) -> (Var.state_var_of_state_var_instance v, t))
             model)
      in

      (* Join values of model at current instant to result *)
      let accum' = 
        list_join
          StateVar.equal_state_vars
          model'
          accum
      in

      (* Recurse for remaining instants  *)
      path_from_model'
        accum'
        state_vars
        (Numeral.pred i)

  in

  path_from_model'
    (List.map (fun sv -> (sv, [])) (state_vars trans_sys))
    (state_vars trans_sys)
    k


(* Return true if the value of the term in some instant satisfies [pred] *)
let rec exists_eval_on_path' uf_defs p term k path =

  try 

    (* Create model for current state, shrink path *)
    let model, path' = 
      List.fold_left 
        (function (model, path) -> function 

           (* No more values for one state variable *)
           | (_, []) -> raise Exit

           (* Take the first value for state variable *)
           | (sv, h :: tl) -> 

             let v = Var.mk_state_var_instance sv Numeral.zero in

             debug transSys 
                 "exists_eval_on_path' at k=%a: %a is %a"
                 Numeral.pp_print_numeral k
                 StateVar.pp_print_state_var sv
                 Term.pp_print_term h
             in

             (* Add pair of state variable and value to model, continue
                with remaining value for variable on path *)
             ((v, h) :: model, (sv, tl) :: path)

        )
        ([], [])
        path
    in

    (* Evaluate term in model *)
    let term_eval = Eval.eval_term uf_defs model term in

    debug transSys 
        "exists_eval_on_path' at k=%a: %a is %a"
        Numeral.pp_print_numeral k
        Term.pp_print_term term
        Eval.pp_print_value term_eval
    in

    (* Return true if predicate holds *)
    if p term_eval then true else

      (* Increment instant *)
      let k' = Numeral.succ k in

      (* Continue checking predicate on path *)
      exists_eval_on_path' uf_defs p term k' path'

  (* Predicate has never been true *)
  with Exit -> false 


(* Return true if the value of the term in some instant satisfies [pred] *)
let exists_eval_on_path uf_defs pred term path = 
  exists_eval_on_path' uf_defs pred term Numeral.zero path 


(* 
   Local Variables:
   compile-command: "make -C .. -k"
   tuareg-interactive-program: "./kind2.top -I ./_build -I ./_build/SExpr"
   indent-tabs-mode: nil
   End: 
*)
  
