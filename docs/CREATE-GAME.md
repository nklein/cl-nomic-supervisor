# How to start a new game

## Preparing GitHub

### Prepare the GitHub repository

Go to https://projectcodename.com to find a unique name for the new game.

Go to one of the GitHub repository templates:

* https://github.com/nklein/cl-nomic-game -- Common Lisp
* https://github.com/nklein/js-nomic-game -- Javascript
* https://github.com/nklein/py-nomic-game -- Python

Select the *Use this template* button near the top right.
When prompted for a name for the new repository, use the name of the project you cloned replacing the `game`
part with the code name.
For example, if you are starting from the `py-nomic-game` and `projectcodename.com` chose **Draconic Snow** for your project, then make your new repository `py-nomic-draconic-snow`.

### Set up branch access protection on the main branch

Go to the repository page on GitHub and select the *Settings* tab.
Select *Rules* in the left menu and then *Rulesets* below that when it expands.

Press the *New ruleset* drop-down button and select *Import a ruleset*.
Import the `GITHUB-BRANCH-PROTECT.json` file in this directory and press the `Create` button at the bottom of the page.

Go back to the rulesets, press the *New ruleset* drop-down button and select *Import a ruleset*.
Import the `GITHUB-GAME-OVER-PROTECT.json` file in this directory and press the `Create` button at the bottom of the page.

### Create an access token

Click on your avatar icon in the extreme top-right of GitHub and choose *Settings* from the drop-down menu.
Then, select *Developer settings* from the left-menu.

Now, select *Personal access tokens* from the left-menu and select *Fine-grained tokens* from there.

Use the green *Generate new token* button to create a token.

Name the token after your repository (e.g. `py-nomic-draconic-snow` for our above example).
Choose an expiration for it.
Choose *Only selected repositories* from the **Repository access** section, and select your new repository from the drop-down list selector.

In the *Permissions* section, add the following:

* **Metadata** -- Read-only
* **Contents** -- Read and write
* **Pull requests** -- Read and write

Then, press the **Generate token** button.
Go through all of its confirmations.
Make sure you capture the token when it shows it to you.
It will not show it again.

## Preparing on machine which will run the supervisor

### Create a .env file

Now, create a `.env` file.
It is probably easiest to name the `.env` file after your repository (e.g. `.env.draconic-snow`).
It should contain:

    # note to self about expiration date of token?
    GITHUB_SUPERVISOR_TOKEN=<the-token-from-above>
    GITHUB_REPO_OWNER=nklein
    GITHUB_REPO_NAME=py-nomic-draconic-snow

Obviously, correct the name of your repository and fill in your token.

### Manually running it

Using the `./run.sh` script here, for our example above, do:

    ./run.sh --image py-nomic-supervisor --env .env.draconic-snow

### Set up a cron job?

Maybe want to set up a cron job to run that once a day or every hour.
This will be


## Maintenance

Certainly, until it the supervisor is capable of cutting off long-running children and reverting in response to errors, you will have to keep a close eye on the output and manually revert when needed.

Also, you should regenerate the personal access token and place the new one
in the `.env` file **before** the old one expires.

## Starting the game

The initial players list will only approve pull requests from the GitHub user `nklein`.
The best way to get the game started is to create a pull-request that modifies the players list to the real players,
leave a review comment that is just the text `ACCEPT`,
and then run the new game to have that pull request merged.
