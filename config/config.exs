import Config

if Mix.env() != :prod,
  do:
    config(:git_hooks,
      verbose: true,
      hooks: [
        pre_commit: [
          tasks: [
            "mix clean",
            "mix compile --warnings-as-errors",
            "mix format --check-formatted",
            "mix credo --strict",
            "mix dialyzer",
            "mix doctor --summary",
            "mix test"
          ]
        ]
      ]
    )

import_config "#{Mix.env()}.exs"
