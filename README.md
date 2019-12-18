[![Gem](https://img.shields.io/gem/v/cici.svg)](https://rubygems.org/gems/cici)
[![Travis (.com)](https://travis-ci.com/levibostian/cici.svg?branch=master)](https://travis-ci.com/levibostian/cici)
[![GitHub](https://img.shields.io/github/license/levibostian/cici.svg)](https://github.com/levibostian/cici)

# cici

*Confidential Information for Continuous Integration (CICI)*

When environment variables are not enough and you need to store secrets within files, `cici` is your friend. Store secret files in your source code repository with ease. 

*Note: Can be used without a CI server, but tool is primarily designed for your CI server to decrypt your secret files for deployment.*

# What is cici?

`cici` is a CLI program where you can encrypt a directory of confidential files on your local machine, then decrypt that directory of files on a CI server with great ease and flexibility. Store secrets in your source code, easily without checking those secrets into source control. 

# Why use cici?

`cici` was inspired by Travis-CI's ability to encrypt files, but it's only limited to encrypting 1 file, per Travis repository. We can get around the 1 file limitation because we can just compress a directory of files into 1 compressed file using `zip` or `tar`. Well, that's great, but what about when we get to the CI server and we need to decrypt those secret files and then copy them from their original source to their final destination? It can start to get complex. 

It would be awesome if we could simply write 1 command on the CI server: `cici decrypt` and automatically for us, the secret files our project depends on will be decrypted and then each secret file is copied to their destination in the source code. Nice! 

But what if we have a production and a staging server? Easy. `cici decrypt --set production` or `cici decrypt --set staging`. `cici` can be configured with any number of sets of files. 

Besides this simplicity and power, `cici` provides some nice features:
1. Use `cici` with any CI service or git hosting service. It's not opinionated. You don't even need to use a CI service, really, if you just want to store private files in source code. 
2. `cici` will add entries to your `.gitignore` file for you to make sure you don't accidentally add secrets to your git repo. 
3. Full flexibility of where your secrets are stored with a configuration file you check into source control. 

# Getting started 

* Install this tool:

```
gem install cici
```

* Config. Let's use an example to explain the rest of the guide on getting started. 

Let's say that you're building an app with the following secret files required to compile your project:
1. `.env`
2. `src/firebase/firebase-secrets.json`
3. `App/GoogleService-Info.plist`

Let's also say that we have a production and a beta app. 2 separate environments that require the same 3 files for each environment. 

All you need to do is...
1. Create a `secrets/` directory in your project source code with this file structure:
```
secrets/
  .env
  src/
    firebase/
      firebase-secrets.json
  App/
    GoogleService-Info.plist
  beta/
    .env
    src/
      firebase/
        firebase-secrets.json
    App/
      GoogleService-Info.plist
```

2. Create a `.cici.yml` config file in the root of your project with the following:

```yml
default:
  secrets:
    - ".env"
    - "src/firebase/firebase-secrets.json"
    - "App/GoogleService-Info.plist"
sets:
  beta:
```

This config file here defines a default set of files that are secrets and also states that we have a set of files besides the default for "beta". `cici` requires you state a default set of secret files. It's up to you to decide what that default is. In this example, we decided that production should be the default set. You can have a development environment be your default. Then all other sets you need, define those in `sets` in the config. 

* Time to encrypt!

On your local development machine, run the command: `cici encrypt`. You will know the command ran successfully when you see "Success!" with further instructions of what to do next. 

Make sure to follow the instructions printed out after the command so you can successfully decrypt. This includes setting *secret* environment variables on your CI machine (or whatever machine you're decrypting the data). Note: Make sure to keep these environment variables a secret. Follow the instructions for your given CI service to create environment variables that are not publicly viewable.

Here are some instructions for some CI providers. Add yours if you don't see it below:
* [Travis-CI](https://docs.travis-ci.com/user/environment-variables/#defining-encrypted-variables-in-travisyml)

* Now, it's time to decrypt. After you add the secret environment variables above, you need to run one of the following commands on the CI server:

```
cici decrypt 
```

...for the default production environment...

or,

```
cici decrypt --set beta 
```

...for the beta environment. 

Done! What `cici` has done is (1) decrypted the encrypted file you made with the encryption step, (2) taken the production set of files or the beta set of files and copied them from the "secrets" directory into your project's source code where they belong. 

So, if you have the following configuration file:

```yml
default:
  secrets:
    - ".env"
    - "src/firebase/firebase-secrets.json"
```

and you run `cici decrypt`, `cici` will perform the following copy operations for you:

1. `secrets/.env` -> `.env`
2. `secrets/src/firebase/firebase-secrets.json` -> `src/firebase/firebase-secrets.json`

and if you run `cici decrypt --set beta`, `cici` will perform the following copy operations for you:

1. `secrets/beta/.env` -> `.env`
2. `secrets/beta/src/firebase/firebase-secrets.json` -> `src/firebase/firebase-secrets.json`

You're all done! I hope you enjoy `cici`. 

# Advanced configuration 

Here is a more advanced configuration file including all options the config file has to offer:

```yml
path: "_secrets"
default:
  secrets:
    - "file.txt"
    - "path/file2.txt"
sets:
  production:
    path: "_production"
  staging:
    secrets:
      - "file3.txt"
output: "secrets_cici"
skip_gitignore: false
```

Here is a breakdown of this file:

```yml
path: (optional, default 'secrets') - the name of the directory your secrets are stored.
default: (required) - specifies a default set of files you want to encrypt/decrypt
  secrets:
    - "file.txt"
    - "path/file2.txt"
sets: (optional) - specify a unique collection of files to encrypt/decrypt
  production: name of a set used as CLI argument to decrypt
    path: (optional, default name of set) - subdirectory within "path" to store files for this set 
  staging: another set
    secrets: (optional, default is default secrets within subdirectory) set of files to encrypt/decrypt.
      - "file3.txt"
output: "secrets_cici" (optional, default, "secrets") - output file name when secrets compressed
skip_gitignore: (optional, default true) - have cici add rules to .gitignore automatically or not for you. 
```

## Development 

```bash
$> bundle install
```

You're ready to start developing! 

##### Lint

```
bundle exec rake lint
```

##### Build/install

```
bundle exec rake install
bundle exec cici # You're running cici!
```

Or, 

```
bundle exec rake build; gem install cici*.gem
cici # you have installed cici to your whole machine!
```

## Deployment 

This gem is setup automatically to deploy to RubyGems on a git tag deployment. 

* Add `RUBYGEMS_KEY` secret to Travis-CI's settings. 
* Make a new git tag, push it up to GitHub. Travis will deploy for you. 

## Author

* Levi Bostian - [GitHub](https://github.com/levibostian), [Twitter](https://twitter.com/levibostian), [Website/blog](http://levibostian.com)

![Levi Bostian image](https://gravatar.com/avatar/22355580305146b21508c74ff6b44bc5?s=250)

## Contribute

cici is open for pull requests. Check out the [list of issues](https://github.com/levibostian/cici/issues) for tasks I am planning on working on. Check them out if you wish to contribute in that way.

**Want to add features?** Before you decide to take a bunch of time and add functionality to the library, please, [create an issue]
(https://github.com/levibostian/cici/issues/new) stating what you wish to add. This might save you some time in case your purpose does not fit well in the use cases of this project.
