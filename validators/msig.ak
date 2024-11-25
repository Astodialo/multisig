use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{from_script}
use cardano/assets.{PolicyId, quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction,
}
use unlearn

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
  signatories: List<VerificationKeyHash>,
}

validator msig(utxo_ref: OutputReference) {
  mint(redeemer: Action, pid: PolicyId, self: Transaction) {
    let Transaction { inputs, outputs, mint, .. } = self

    when redeemer is {
      Mintin -> {
        // Check if the utxo, that the validator is parametrized with, is an input of the transaction. After the utxo is consumed no other utxo with the same ref will exist, proving that no other unApxn token is minted. 
        expect
          list.any(inputs, fn(input) { input.output_reference == utxo_ref })?

        // Check if there is a single output in the validator address
        expect [Output { datum: InlineDatum(output_datum), .. }] =
          list.filter(
            outputs,
            fn(output) {
              output.address == from_script(pid) && quantity_of(
                output.value,
                pid,
                unlearn.mtn,
              ) == 1
            },
          )

        // Check that only one unApxn token is minted
        expect unlearn.value_contains_master_token(mint, pid)

        // Check that the list of signatories, has more than 0 signatories
        expect Metadatum { signatories }: Metadatum = output_datum
        (list.length(signatories) > 0)?
      }

      Update -> todo
    }
  }

  spend(
    datum_opt: Option<Metadatum>,
    redeemer: Action,
    utxo: OutputReference,
    self: Transaction,
  ) {
    let Transaction { inputs, outputs, extra_signatories, .. } = self
    expect Some(datum) = datum_opt

    when redeemer is {
      Mintin -> todo
      Update ->
        if list.length(extra_signatories) == list.length(datum.signatories) {
          expect [] = list.difference(extra_signatories, datum.signatories)
          todo
        } else {
          fail
        }
    }
  }

  else(_) {
    fail
  }
}
