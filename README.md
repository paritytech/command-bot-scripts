# Commands & Scripts implementation for [command-bot](https://github.com/paritytech/command-bot/)

## How to add command?
⚠️ Please, _do not fork_, instead create a dev branch in scope of current repo. This will allow you to test your branch before merging. 

For now just copy existing command and modify. Later there will be more ways to do this easier from the bot itself or here via CLI. 
- clone scripts & bot into the same folder
  - `git clone https://github.com/paritytech/command-bot.git`
  - `git clone https://github.com/paritytech/command-bot-scripts.git`
  - `cd ./command-bot-scripts`
- Run `yarn --immutable` to install `command-bot` dependency, which includes the actual supported schema for commands validation.
  If you develop in parallel with `command-bot` then use something like `yarn link`
- Copy any existing command which looks the most similar.
- Change the name of command. The structure should be `/commands/<command_name>/<command_name>.cmd.json` and `/commands/<command_name>/<command_name>.sh`, because the `command_name` will be used to build a path from command to script.
- Test it in your PR:
  - when running a new command - add specific flag (-v PIPELINE_SCRIPTS_REF=your-branch) to test it before merge.  
  Example: `bot new-command -v PIPELINE_SCRIPTS_REF=your-branch $ some arguments`
- In PR with your new command - add test evidence links to your PR with the result of your command and merge after approval.
- That's it

## How does it work with companion PRs ?

To make a context of companion you need to specify it with special env variable `-v PATCH_<repo_name>=<repo_PR_number>`, for example: `-v PATCH_substrate=11649`

Example:
`bot try-runtime -v PATCH_substrate=11649 $ polkadot`


## Some command might automatically refresh (merge) from "master"
To disable this, add `-v UPSTREAM_MERGE=n`, example: "bot bench-vm -v UPSTREAM_MERGE=n $ all"
