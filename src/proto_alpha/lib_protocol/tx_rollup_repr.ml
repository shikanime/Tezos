(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

type error += Invalid_rollup_notation of string (* `Permanent *)

let () =
  let open Data_encoding in
  register_error_kind
    `Permanent
    ~id:"rollup.invalid_contract_notation"
    ~title:"Invalid rollup notation"
    ~pp:(fun ppf x -> Format.fprintf ppf "Invalid rollup notation %S" x)
    ~description:
      "A malformed rollup notation was given to an RPC or in a script."
    (obj1 (req "notation" string))
    (function Invalid_rollup_notation loc -> Some loc | _ -> None)
    (fun loc -> Invalid_rollup_notation loc)

(* 20 *)

module Hash = struct
  let rollup_hash = "\002\090\121" (* KT1(36) *)

  include
    Blake2B.Make
      (Base58)
      (struct
        let name = "Rollup_hash"

        let title = "A rollup ID"

        let b58check_prefix = rollup_hash

        let size = Some 20
      end)

  let () = Base58.check_encoded_prefix b58check_encoding "KT1" 36

  include Path_encoding.Make_hex (struct
    type nonrec t = t

    let to_bytes = to_bytes

    let of_bytes_opt = of_bytes_opt
  end)
end

type t = Hash.t

type tx_rollup = t

include Compare.Make (struct
  type nonrec t = t

  let compare r1 r2 = Hash.compare r1 r2
end)

let to_b58check rollup = Hash.to_b58check rollup

let of_b58check s =
  match Base58.decode s with
  | Some (Hash.Data hash) -> ok hash
  | _ -> error (Invalid_rollup_notation s)

let pp ppf hash = Hash.pp ppf hash

let encoding =
  let open Data_encoding in
  def
    "rollup_id"
    ~title:"A rollup handle"
    ~description:
      "A rollup notation as given to an RPC or inside scripts, is a base58 \
       rollup hash"
    (conv
       to_b58check
       (fun s ->
         match of_b58check s with
         | Ok s -> s
         | Error _ -> Json.cannot_destruct "Invalid contract notation.")
       string)

type creation_nonce = {
  operation_hash : Operation_hash.t;
  creation_index : int32;
}

let creation_nonce_encoding =
  let open Data_encoding in
  conv
    (fun {operation_hash; creation_index} -> (operation_hash, creation_index))
    (fun (operation_hash, creation_index) -> {operation_hash; creation_index})
  @@ obj2 (req "operation" Operation_hash.encoding) (dft "index" int32 0l)

let created_tx_rollup nonce =
  let data = Data_encoding.Binary.to_bytes_exn creation_nonce_encoding nonce in
  Hash.hash_bytes [data]

let initial_creation_nonce operation_hash =
  {operation_hash; creation_index = 0l}

let incr_creation_nonce nonce =
  let creation_index = Int32.succ nonce.creation_index in
  {nonce with creation_index}

let rpc_arg =
  let construct = to_b58check in
  let destruct hash =
    Result.map_error (fun _ -> "Cannot parse rollup id") (of_b58check hash)
  in
  RPC_arg.make
    ~descr:"A rollup identifier encoded in b58check."
    ~name:"rollup_id"
    ~construct
    ~destruct
    ()

module Index = struct
  type t = tx_rollup

  let path_length = 1

  let to_path c l =
    let raw_key = Data_encoding.Binary.to_bytes_exn encoding c in
    let (`Hex key) = Hex.of_bytes raw_key in
    key :: l

  let of_path = function
    | [key] ->
        Option.bind
          (Hex.to_bytes (`Hex key))
          (Data_encoding.Binary.of_bytes_opt encoding)
    | _ -> None

  let rpc_arg = rpc_arg

  let encoding = encoding

  let compare = compare
end

type pending_inbox = unit

let pending_inbox_encoding =
  Data_encoding.(obj1 (req "pending_inbox" Data_encoding.unit))

let empty_pending_inbox = ()
