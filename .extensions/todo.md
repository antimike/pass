* env
    * Support local .passenv files
* select
    * Eliminate dependencies
    * Simplify markup rules
        * TS "toy" grammar?
* keyring
    * Figure out GNOME API / locate docs
* Larger project ideas:
    * "pass-json"
        * Allow encrypting of directory structures as well as credentials: granular control over how much structure is hidden
    * "cryptree"
        * Encrypted / partially-encrypted AST / CST
        * Grammar spec is part of config; queries specify how to retrieve data from encrypted files
            * "TS-lite" for markup-spec "toy" languages?
    * "TS-lite" / "TS-OOP"

```
alias (context 0) pass_file
context
    |   NULL
    | + context $.prev
      +
pass_file
    | NULL
    | + pass_file
      + context 0
context n <- context (n-1)
    + root n
    + | NULL
      | context (n+1)

node { n := len prefix; prefix <- /(?<prefix>\s*)\w/ }
    =>


```
