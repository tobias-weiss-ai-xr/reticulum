%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Warning.LazyLogging, false},
        {Credo.Check.Consistency.SpaceAroundOperators, false},
        {Credo.Check.Consistency.SpaceInParentheses, false}
      ]
    }
  ]
}
