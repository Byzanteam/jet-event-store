[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:commanded, :ecto, :typed_struct],
  export: [
    locals_without_parens: [dispatch: 2]
  ]
]
