use aiken/collection/dict
use aiken/collection/list
use aiken/primitive/bytearray
use cardano/address.{Address, Credential, from_script}
use cardano/assets
use cardano/transaction.{Input, Output, OutputReference, find_input}

pub const mtn: ByteArray = "unApxn"

pub fn valEq(
  ending: ByteArray,
  ass: (assets.PolicyId, assets.AssetName, Int),
  val: List<(assets.PolicyId, assets.AssetName, Int)>,
) -> Bool {
  list.any(
    val,
    fn(ref_ass: (assets.PolicyId, assets.AssetName, Int)) {
      let (policy, name, _) = ass
      let (ref_policy, ref_name, _) = ref_ass

      let equality =
        ref_name
          |> bytearray.concat(ending)
          |> bytearray.compare(name)

      equality == Equal && policy == ref_policy
    },
  )
}

pub fn correct_amount(outputs: List<Output>, ref_amount: Int) -> Bool {
  expect Some(output) = list.head(outputs)

  let Output { value: val, .. } = output

  assets.lovelace_of(val) == ref_amount && //&&
  list.length(assets.flatten(assets.without_lovelace(val))) == 0
}

pub fn own_validator_input_utxo(
  inputs: List<Input>,
  output_reference: OutputReference,
) -> Output {
  expect Some(input) =
    list.find(inputs, fn(input) { input.output_reference == output_reference })

  input.output
}

pub fn named_correct(
  values: List<(assets.PolicyId, assets.AssetName, Int)>,
  name: ByteArray,
  own_policy: ByteArray,
) -> Bool {
  list.length(values) == 3 && list.all(
    values,
    fn(value) -> Bool {
      let (pid, asset, amt) = value

      pid == own_policy && (
        asset == bytearray.concat(name, "_R") || asset == bytearray.concat(
          name,
          "_Claim",
        ) || asset == name
      ) && amt == 1
    },
  )
}

pub fn value_contains_master_token(
  val: assets.Value,
  own_policy: assets.PolicyId,
) -> Bool {
  expect [Pair(token_name, quantity)] =
    val
      |> assets.tokens(own_policy)
      |> dict.to_pairs()

  token_name == mtn && quantity == 1
}

pub fn value_has_only_master_and_lovelace(
  val: assets.Value,
  own_policy: assets.PolicyId,
) -> Bool {
  expect [Pair(policy1, amount1),
    Pair(policy2, amount2)] =
    val
      |> assets.to_dict
      |> dict.to_pairs()

  if policy1 == assets.ada_policy_id {
    expect [Pair(token_name, quantity)] = amount2 |> dict.to_pairs()

    policy2 == own_policy && quantity == 1 && token_name == mtn
  } else {
    expect [Pair(token_name, quantity)] = amount1 |> dict.to_pairs()

    policy1 == own_policy && quantity == 1 && token_name == mtn
  }
}
