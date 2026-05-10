; This value is replaced by the release pipeline with the git tag (without the "v" prefix).
; Keep "0.0.0-dev" as the literal placeholder so a regex replace in CI finds it.
global APP_VERSION := "0.0.0-dev"
