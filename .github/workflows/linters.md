name: Linters

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

  workflow_dispatch:

jobs:
  markdown-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: avto-dev/markdown-lint@v1.5.0
        with:
          args: './*.md'

  docker-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hadolint/hadolint-action@v2.0.0
        with:
          recursive: true
          ignore: DL3041
