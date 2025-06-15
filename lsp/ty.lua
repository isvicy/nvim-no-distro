return {
  capabilities = {
    general = {
      positionEncodings = {
        'utf-16', -- ty by default use utf-8, but utf-16 is more compatible with other LSPs like copilot
      },
    },
  },
}
