# Contributing to ActsAsRetired

We welcome contributions to ActsAsRetired. Please follow the guidelines below to help the
process of handling issues and pull requests go smoothly.

## Issues

When creating an issue, please provide as much information as possible, and
follow the guidelines below to make it easier for us to figure out what's going
on. If you miss any of these points we will probably ask you to improve the
ticket.

- Include a clear title describing the problem
- Describe what you are trying to achieve
- Describe what you did, preferably including relevant code
- Describe what you expected to happen
- Describe what happened instead. Include relevant output if possible
- State the version of ActsAsRetired you are using
- Use [code blocks](https://github.github.com/gfm/#fenced-code-blocks) to
  format any code and output in your ticket to make it readable.

## Pull Requests

If you have an idea for a particular feature, it's probably best to create a
GitHub issue for it before trying to implement it yourself. That way, we can
discuss the feature and whether it makes sense to include in ActsAsRetired itself
before putting in the work to implement it.

When sending a pull request, please follow **all of** the instructions below:

- Make sure `bundle exec rake` runs without reporting any failures. See
  *Testing your changes* below for more details.
- Add tests for your feature. Otherwise, we can't see if it works or if
  we break it later.
- Create a separate branch for your feature based off of latest master.
- Write [good commit messages](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).
- Do not include changes that are irrelevant to your feature in the same
  commit.
- Keep an eye on the build results in GitHub Actions. If the build fails and it
  seems due to your changes, please update your pull request with a fix.

If you're not sure how to test the problem, or what the best solution is, or
get stuck on something else, please open an issue first so that we can discuss
the best approach.

### Testing your changes

You can run the test suite with the latest version of all dependencies by running the following:

- Run `bundle install` if you haven't done so already, or `bundle update` to update the dependencies
- Run `bundle exec rake` to run the tests

To run the tests suite for a particular version of ActiveRecord use
[appraisal](https://github.com/thoughtbot/appraisal). For example, to run the
specs with ActiveRecord 6.1, run `appraisal active_record_61 rake`. See appraisal's
documentation for details.

### The review process

- We will try to review your pull request as soon as possible but we can make no
  guarantees. Feel free to ping us now and again.
- We will probably ask you to rebase your branch on current master at some point
  during the review process.
  If you are unsure how to do this,
  [this in-depth guide](https://git-rebase.io/) should help out.
- If you have any unclear commit messages, work-in-progress commits, or commits
  that just fix a mistake in a previous commits, we will ask you to clean up
  the history.
  Again, [the git-rebase guide](https://git-rebase.io/) should help out.
  Note that we will not squash-merge pull requests, since that results in a loss of history.
- **At the end of the review process we may still choose not to merge your pull
  request.** For example, this could happen if we decide the proposed feature
  should not be part of ActsAsRetired, or if the technical implementation does not
  match where we want to go with the architecture of the project.
- We will generally not merge any pull requests that make the build fail, unless
  it's very clearly not related to the changes in the pull request.
