# Contributing

IPDK uses GitHub to manage reviews of pull requests.

* If you are a new contributor see: [Steps to Contribute](#steps-to-contribute)

* If you have a trivial fix or improvement, go ahead and create a pull request,
  addressing (with `@...`) a suitable maintainer of this repository (see
  [MAINTAINERS.md](MAINTAINERS.md)) in the description of the pull request.

* Be sure to sign off on the [DCO](https://github.com/probot/dco#how-it-works).

## Issues

We use [GitHub Issues](https://github.com/ipdk-io/ipdk/issues) to track issues
for the IPDK project. If you come across a bug, please feel free to open issue.
Ideally, you would include as much information below in the issue:

* Clear title presenting the issue.
* A solid description with steps to reproduce the issue.
* Are you using the IPDK container, or running natively?
* Which supported version of the base OS are you running?

## Steps to Contribute

Should you wish to work on an issue, please claim it first by commenting on the
GitHub issue that you want to work on it. This is to prevent duplicated efforts
from contributors on the same issue.

## Pull Request Checklist

* Branch from the main branch and, if needed, rebase to the current main branch
  before submitting your pull request. If it doesn't merge cleanly with main
  you may be asked to rebase your changes.

* Make sure you write a good commit message. Commit messages matter, it's
  important for other developers to understand the context behind your commit.
  For help, [this artcile](https://cbea.ms/git-commit/) is a good place to
  start.

* Commits should be as small as possible, while ensuring that each commit is
  correct independently (i.e., each commit should compile and pass tests).
  *NOTE*: For a list of tests, see the existing GitHub Actions defined
  [here](https://github.com/ipdk-io/ipdk/blob/main/.github/workflows/makefile.yml).

* If your patch is not getting reviewed or you need a specific person to review
  it, you can @-reply a reviewer asking for a review in the pull request or a
  comment. You can also ping [maintainers](MAINTAINERS.md) on the
  [IPDK Slack](https://join.slack.com/t/ipdkworkspace/shared_invite/zt-xb97bi1d-Q0NY9YC3PYv3LTw~HngVbA).

* Add tests relevant to the fixed bug or new feature.

## Pull Request Merging

* Assuming you've followed the steps to [prepare your PR](#pull-request-checklist),
  reviewers will review you pull request. These could be general members of the
  community, as well as [maintainers](MAINTAINERS.md).

* Pull requests will be reviewed by one or more maintainers and merged when
  acceptable.
