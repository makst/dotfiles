AWS
===

The AWS CLI on every Mac, signing in through IAM Identity Center (SSO), so no access keys are stored on disk.
Claude Code can look around an account but not change it.

What it is
---
- **The tool** is `aws` from the `awscli` formula in the Brewfile; it updates with `brew upgrade` and brings
  its own zsh completion.
- **Profiles** live only in `~/.aws/config` on each Mac, outside the repo: which accounts you have is your own
  business, so the repo ships none. `aws configure sso` writes them.
- **Logins** go through an `sso-session` block: `aws sso login` opens the browser once, and the CLI renews
  the short-lived role credentials by itself until the access portal session ends. The token and the role
  credentials are cached in `~/.aws/sso/cache` and `~/.aws/cli/cache`.
- **No profile is the default.** Each command names its account with `--profile`, so nothing goes to an
  account by accident.

### What Claude Code can do

Claude's `Read` tool can't open `~/.aws/credentials` or the two caches, and `aws` commands that change things
are denied, on every Mac (`config/claude/settings.json`):

| Denied | Why |
|---|---|
| `aws … create-* / delete-* / put-* / update-* / modify-* / terminate-* / run-* / start-* / stop-* / …` | changes resources (the full list is in `settings.json`) |
| `aws … attach-* / detach-* / authorize-* / revoke-* / add-* / remove-* / set-* / tag-*` | changes access and settings |
| `aws … invoke / publish / deploy / send-*` | runs code or sends something |
| `aws s3 rm / rb / mb / mv / cp / sync` | changes buckets |
| `aws configure set / sso` | would rewrite `~/.aws/config` |
| `cdk deploy / destroy / bootstrap / import / watch / rollback`, also through `npx` | changes stacks |

When you want Claude to make a change, run the command it suggests yourself.

Once per Mac
---
`setup_brew` installs `awscli`. Then add each account you use ([Adding an account with
SSO](#adding-an-account-with-sso)) and sign in ([Signing in](#signing-in)).

Adding an account with SSO
---
Once per AWS account, in the console, signed in as the root user or an admin. `<profile>` below is the name
you pick for the account.

1. **Pick the region first.** In the region menu at the top right, choose the region you want Identity
   Center in, for example Europe (Frankfurt), `eu-central-1`. Identity Center stays in the region you enable
   it in.
2. **Enable IAM Identity Center.** Search for "IAM Identity Center", then **Enable**. Choose the organization
   instance (**Enable with AWS Organizations**): only that one can give access to AWS accounts. It makes an
   AWS Organization with this account as its management account, if there isn't one. The identity source
   is the built-in Identity Center directory unless you change it.
3. **Create your user.** **Users** → **Add user**: a username, your email, first and last name, "Send an
   email to this user with password setup instructions" → **Next** → skip groups → **Add user**.
4. **Accept the invite.** In the email "Invitation to join AWS IAM Identity Center", **Accept invitation**
   (it expires after 7 days), set a password, sign in and register an MFA device (a passkey, a security key or
   an authenticator app).
5. **Create the permission set.** **Permission sets** → **Create permission set** → **Predefined permission
   set** → `AdministratorAccess` → **Next**. The session duration (1 hour by default) is how long one set of
   role credentials lasts; the CLI renews them, so the default is fine → **Next** → **Create**.
6. **Give your user access to the account.** **AWS accounts** → tick the account → **Assign users or
   groups** → **Users** → your user → **Next** → `AdministratorAccess` → **Next** → **Submit**.
7. **Copy the start URL.** The **AWS access portal URL** on the Identity Center **Dashboard** (`https://
   d-xxxxxxxxxx.awsapps.com/start`).
8. **Write the profile** on each Mac, in a terminal: `aws configure sso`. Session name: `<profile>`; start
   URL: the one from step 7; region: the one from step 1; scopes: the default. It opens the browser, lists
   the accounts and roles you can reach, and writes an `sso-session` and a `profile` block into
   `~/.aws/config`. When it asks for the default client region and output, give the region and `json`; for
   the profile name, `<profile>`.

Signing in
---
In a terminal (it opens the browser and asks for your Identity Center password and MFA):

```zsh
aws sso login --profile <profile>
aws sts get-caller-identity --profile <profile>   # the account, and the role as …/AWSReservedSSO_AdministratorAccess_…
```

Sign in again when a command says the token has expired: the access portal session lasts 8 hours by
default (Identity Center → **Settings** → **Authentication** → **Session duration**, up to 90 days). One
`aws sso login` covers every profile that shares the same `sso-session`.

Commands
---
| Command | Does |
|---|---|
| `aws configure sso` | adds a profile to `~/.aws/config` through the browser |
| `aws sso login --profile <p>` | signs in through the browser; once per access portal session |
| `aws sso logout` | ends the session and clears the cached tokens |
| `aws sts get-caller-identity --profile <p>` | which account and role a profile reaches |
| `aws configure list-profiles` | the profiles in `~/.aws/config` |
| `cdk <command> --profile <p>` | AWS CDK in a project's repo, with the same login |

Config
---
| Part | Where | What it does |
|---|---|---|
| `awscli` formula | `Brewfile` | `aws` and its zsh completion |
| Profiles | `~/.aws/config`, outside the repo | one `sso-session` and `profile` block per account, from `aws configure sso` |
| Claude Code | `config/claude/settings.json` | `deny` rules for the credentials, the caches and commands that change things ([What Claude Code can do](#what-claude-code-can-do)) |

To look out for
---
- Keep account names out of the repo: put a private project's name in `~/.config/dotfiles/forbidden`, and
  `check_dotfiles` fails if it turns up in a file or an unpushed commit.
- The deny rules match words anywhere after `aws`, so a read whose arguments contain ` delete-` is denied
  too; run that one yourself with `!`.
- `aws` runs outside Claude Code's sandbox (`excludedCommands` in `settings.json`), because the sandbox
  takes the `Read` deny rules on the caches as its own and would stop `aws` from using your login. The deny
  rules on commands still apply there. `cdk` isn't excluded, so a `cdk diff` or `cdk synth` that looks
  something up in the account fails inside the sandbox; run it yourself with `!`.
- The user and permission set sit in the organization's management account. That's fine for one personal
  account; with more, put workloads in member accounts and keep the management account for Identity Center
  and billing.

Decisions
---
- **SSO, not access keys**: nothing long-lived on disk; a stolen laptop's token expires with the session.
- **No profiles in the repo**: the accounts are private projects or work, and the repo names neither. With
  nothing shared, a setup step copying profiles would have nothing to copy, so `aws configure sso` writes
  `~/.aws/config` directly.
- **No default profile**: a command without `--profile` fails rather than going to some account by accident.
