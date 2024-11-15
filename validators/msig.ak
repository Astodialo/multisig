use aiken/collection/list
use cardano/address.{from_script}
use cardano/assets.{PolicyId}
use cardano/transaction.{
  InlineDatum, Input, Mint, Output, OutputReference, Spend, Transaction,
}

// Type of the signers datum
pub type Signers {
  addrs: List<address.Credential>,
}

// Type of the scripts redeemer
pub type Action {
  Mintin
  Update
}

// Type of the proposal-x datum
pub type Metadatum {
  proposal: ByteArray,
  state: ByteArray,
  amount: Int,
}

validator msig(utxo_ref: OutputReference) {
  mint(redeemer: Action, pid: PolicyId, ctx: Transaction) {
    let Transaction { inputs, outputs, mint, .. } = ctx

    when redeemer is {
      Mintin -> {
        // Check if the utxo, that the validator is parametrized with, is an input of the transaction. After the utxo is consumed no other utxo with the same ref will exist, proving that no other unApxn token is minted. 
        expect
          list.any(inputs, fn(input) { input.output_reference == utxo_ref })?

        // Check if there is a single output in the validator address
        expect [Output { datum: InlineDatum(output_datum), .. }] =
          list.filter(
            outputs,
            fn(output) { output.address == from_script(pid) },
          )
        todo
      }
      Update -> todo
    }
  }

  else(_) {
    fail
  }
}
