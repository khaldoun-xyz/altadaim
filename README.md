# Altadaim is a developer setup for data scientists

Install a fully-configured developer experience with one command.
[Omakub](https://omakub.org/) is the original inspiration for Altadaim.

Altadaim is designed for simplicity.

## How to install it

Altadaim is written for Fedora, our Linux distribution of choice.
You can install Fedora, following [this installation guide](https://guides.frame.work/Guide/Fedora+42+Installation+on+the+Framework+Laptop+13/419).

Then copy this command and run it in your terminal:

```bash
wget https://raw.githubusercontent.com/khaldoun-xyz/altadaim/main/install_altadaim.sh && sudo bash install_altadaim.sh
```

## How it works

If you run the script, Altadaim will do the rest by itself.
Here and there, you are asked for user input (e.g. to save your ssh key to Github).
In the end, you'll see instructions what to do next to finish the install.

### Logging

*Logging is not properly set up yet.*

The final version of Altadaim will create a folder `~/altadaim-logs`.
In this folder, the various config files will create a log file
with the same name as the original file with a creation timestamp in the end
(e.g. `install_altadaim-<TIMESTAMP>.log`).

## What you get with Altadaim

### Your Operating System: Fedora

Properly navigating your operating system is already a productivity boost.
Here are key commands:

- open search bar: `super`
- maximise current window: `super + arrow up`
- move current window to left/right screen section: `super + arrow left/right`
- move to next workspace: `super alt + arrow left/right`
- move app to next workspace: `shift super alt arrow + left/right`
- activate/deactivate full-screen mode: `f11`
- in your terminal, start Lazyvim with your current directory: `n .`

### Take editable screenshots with Flameshot

Screenshots are important for collaborative work.

- take an editable screenshot: `ctrl super + p`.
  Copy the screenshot into your clipboard with `ctrl + c`
  or save it with `ctrl + s`.

### Your terminal: Alacritty

To open Alacritty, hit `super`, write `alacritty` and hit enter

#### Bash

Being able to interact with a terminal console is helpful
to not be limited by GUI functionality.

- Jump into a directory: `cd ~/path_to_directory`
- Show all (also hidden) files in a directory: `ls -a`
- Create a directory: `mkdir name_of_directory`
- Copy/Move a file to a target location: `cp/mv file.md ~/target_directory/`
- See cpu usage (quit by hitting `q`): `htop`
- Open reverse-i-search: `ctrl + r (keyboard shortcut)`.
  Hit `ctrl +r` again to cycle through the history.

#### Zellij

Zellij lets you easily manipulate your terminal windows.

- open Zellij by entering `zellij` in your terminal
- create a new pane to the side/below: `ctrl p + r/d`
- increase/decrease the current pane size: `alt +/-`
- change focus to the next pane: `alt arrow keys`
- open a floating pane: `ctrp p + w`
- create a new tab: `ctrl t + n`

#### Lazyvim

Lazyvim is a modern vim-native GUI.
In Altadaim, it comes pre-configured with helpful things (e.g. Markdown linting).

If you want to practice vim, ...

- [this video series](https://www.youtube.com/watch?v=X6AR2RMB5tE&list=PLm323Lc7iSW_wuxqmKx_xxNtJC_hJbQ7R)
  gives you a good basic overview.
- [this cheatsheet](https://vim.rtorr.com/) contains many useful commands.

##### Lazyvim config

Your Lazyvim setup comes with the following ...

- language linting for Markdown and Python (see plugins/extras.lua)
- coding assistance with Avante (see plugins/avante.lua)
- show hidden files (see plugins/snacks.lua)
- auto-prettify json files (see config/autocmds.lua)

##### Lazyvim Commands

- start Lazyvim in your current directory by entering `n .` in your terminal
- open/close the file tree: `space + e`
  - `h` in file tree: show hidden files (.env files remain hidden)
  - `a` in file tree: create a file or folder (add / to create a folder)
  - `d` in file tree: delete a file or folder
- open the file finder: `space + space`
- move the cursor left/down/up/right: `h/j/k/l`
- copy/cut a line: `yy/dd`
- copy/cut 5 lines: `y5y/d5d`
- paste the previously copied/cut lines: `p`
- undo/repeat the previous command: `u/ctrl + r`
- jump ahead/back one word: `w/b`
- jump to top/bottom of file: `gg/G`
- search inside the current file: `/`
- close the current file: `space + b + d`
- close all files but the current one: `space + b + o`
- move to the next file on the left/right: `shift h/l`
- search all files: `space + s + g`
- open lazy git: `space + g + g`

#### Psql

Psql is a terminal-based frontend to a Postgresql database.

The easiest way to set up a database connection
for psql is to open your .bashrc and add a
line like this:
`alias psql_NAME='psql CONNECTION_STRING_TO_POSTGRES_DATABASE'`.
Save and close your .bashrc, restart your terminal
and type in `psql_NAME`. Et voilà.

### Git

During the Altadaim installation, you set up your GitHub ssh key.
Version control is a very basic and very useful tool.

- [This video series](https://www.youtube.com/watch?v=rH3zE7VlIMs)
  gives you a good basic overview.
- To test your git knowledge, [clone this repo](https://github.com/juanfresia/git-challenge)
  and complete the challenges.

#### Git commands

These are good case practices that we use at Khaldoun.

- When pushing a PR, rebase to the master branch with `git rebase master`
  (make sure you have the most recent master locally!)
  and resolve any merge conflict *before* asking for review.
- When your PR isn't ready for review yet (work in progress)
  but you still want to share it with others, open the PR as `draft`.
- Squash minor git commits into fewer more relevant commits.
  Set "Squash and merge" as default merge option of branches
  (this collapses a branch with many commits into one feature commit in master).
- Where helpful, use gitmojis in your commit messages (e.g. :bug:): <https://gitmoji.dev/>.
- Don't open PRs without descriptions.
  Make sure to minimise typos and formatting issues.
- PRs that are too large cannot be merged (extreme case: 5000+ files are too large).
- Once you dealt with a PR comment,
  click on "Resolve conversation" to indicate that you consider it resolved.
  Either resolve all comments or provide responses.
- Close open issues with a reference to the PRs
  in which they are resolved after you've resolved them.
- use at least these pre-commit hooks: end-of-file-fixer,
  trailing-whitespace, black, isort.
  Always make sure pre-commit hooks have run *before* asking for a review.

### Docker

Containerising applications with Docker removes
many of the headaches around server configuration.
If the docker runs on one system, it will run on another.

- `docker build -t NAME .`:
  build a container & give it the name NAME
- `docker run NAME`: run the NAME container
  (not additional parameters like `-p`, `-d`, `--env-file`, etc.)
- `docker ps`: see a list of running docker containers
- `docker exec -it INITIAL_DIGITS_OF_CONTAINER sh`:
  jump inside a container & get terminal access

## Error log

- If you encounter errors, you might find help here: [potential errors](/docs/potential_errors.md)
