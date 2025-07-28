# Overview

A CLI tool for users to report and understand suspected issues with their HPC environment.

# Install

**FOR LEGACY REASONS THIS TOOL CURRENTLY MUST SUPPORT RUBY 2.6+**

This is a application meant to be integrated with the Flight Environment. The scripts in this directory correspond to where they should go in relation to `$flight_ROOT` (e.g. `libexec/commands/report` should be placed at `/opt/flight/libexec/commands/report` in a default flight environment setup).

An example of putting the files in place and installing dependencies (as root):
```
# Clone repository
git clone https://github.com/openflighthpc/flight-report /tmp/flight-report

# Copy files into place
cp -ru /tmp/flight-report/opt $flight_ROOT/
cp -ru /tmp/flight-report/libexec $flight_ROOT/

# Optional: Configure CLI tool (otherwise will use default settings)
## Open and edit the file to change defaults
cp $flight_ROOT/opt/report/etc/config.yaml.example $flight_ROOT/opt/report/etc/config.yaml

# Ensure log directories are writeable by all users
chmod 777 $flight_ROOT/opt/report/var/{accesslogs,check-results,ratings,reports}

# Install ruby dependencies
cd $flight_ROOT/opt/report/
$flight_ROOT/bin/bundle config set --local path vendor
$flight_ROOT/bin/bundle install

# Remove git repo
rm -rf /tmp/flight-report
```

## Reporting Tool Extras 

_Note: These example alias the `report` script to be accessed via the keyword `assist`_

### [Optional] Add to "Flight Banner"

The Flight Environment can include messages in the banner program (when enabled), to add a banner message with a call-to-action for `flight assist`, create the file `$flight_ROOT/etc/banner/banner.d/30-assist.sh` containing the following:
```bash
(
  bold="$(tput bold)"
  clr="$(tput sgr0)"
  if [[ $TERM =~ "256color" ]]; then
    bgblue="$(tput setab 68)"
  fi
  echo -e "HOW HAS YOUR HPC EXPERIENCE BEEN TODAY? LET US KNOW!"
  printf "  ${bold}${bgblue}flight assist${clr} to get in touch\n"
  echo
)
```

### [Optional] Add to "Flight Tips"

The Flight Environment can have a "Flight Tips" section which is displayed on login to the system. To add `flight assist` to the tips list create file `$flight_ROOT/etc/banner/tips.d/50-assist.rc` containing the following:
```bash
flight_TIP_command="flight assist"
flight_TIP_synopsis="Let us know how your experience with the HPC environment is"
flight_TIP_root="false"
```

## Summary Tool

_Note: These example alias the `summary` script to be accessed via the keyword `status`_

### [Optional] Add to "Flight Banner"

The Flight Environment can include messages in the banner program (when enabled), to add a banner message with a call-to-action for `flight status`, create the file `$flight_ROOT/etc/banner/banner.d/25-status.sh` containing the following:
```bash
(
  bold="$(tput bold)"
  clr="$(tput sgr0)"
  if [[ $TERM =~ "256color" ]]; then
    bgblue="$(tput setab 68)"
  fi
  echo -e "SEE THE STATUS OF YOUR HPC ENVIRONMENT!"
  printf "  ${bold}${bgblue}flight status${clr} for more information\n"
  echo
)
```

### [Optional] Add to "Flight Tips"

The Flight Environment can have a "Flight Tips" section which is displayed on login to the system. To add `flight assist` to the tips list create file `$flight_ROOT/etc/banner/tips.d/45-status.rc` containing the following:
```bash
flight_TIP_command="flight status"
flight_TIP_synopsis="See the current status of the HPC environment (including any known issues)"
flight_TIP_root="false"
```

## Updating

To update the CLI tool simply clone the repository and copy the files into place again, overwriting the existing ones.

Can only overwrite files that have changed with:
```bash
cp -r /tmp/flight-report/opt $flight_ROOT/
cp -r /tmp/flight-report/libexec $flight_ROOT/
```

# File Structure

- `opt/report/etc/issues/`: Location of content for this command, this is where issues and specific diagnostics are defined
- `opt/report/etc/issues/general/*.bash`: These diagnostics are run for every issue (in alphanumeric order)
- `opt/report/etc/issues/general/metrics.yaml`: These metrics are checked for every issue

# Adding Content

## Checks

`Checks` are scripts used to check & identify issues within a HPC environment. These `Checks` can then be used to create `Statuses`.

Each check script must:
- Be created in `etc/checks/` and end with `.sh`
- Contain a line starting `# Description:` followed by a brief description of what the script does
- Be a BASH script

For a user to have access to encrypted checks and have their checks automatically saved to a report file they will need to be in the privileged users list in the config file.

### Encrypted Checks

Encrypted checks are useful for allowing only certain users entrusted with a decryption password to be able to execute the tests (without exposing the content of the scripts to unauthorised users). 

Each encrypted check must:
- Be created in `etc/checks/` and end with `.sh.gpg`
- Must be decrypted by the same password (across an installation of this tool)

This has been tested by creating an encrypted script as follows: 
```bash
# Create source script
echo -e "# Description: Run an encrypted check\necho 'Encrypted script test'" > /tmp/encrypted_example.sh.source

# Encrypt with password (will prompt for input)
gpg -c --no-symkey-cache --armour -o etc/checks/encrypted_example.sh.gpg /tmp/encrypted_example.sh.source
```

### Site Checks

A configurable "site" directory can be specified in config.yaml which provides an extra source of check scripts.

These scripts also have to stick to the "musts" specified at the beginning of this section (except the location must be in the location specified by `sitechecksdir` in `config.yaml`)

## Statuses

`Statuses` provide information about the system to a user describing the state of the system. 

To add a status: 
- Create a file named after the status in `opt/report/etc/statuses`, for example, `network.yaml`:
    ```yaml
    type: warning
    message: "Network: We are aware of a network performance degradation which we are investigating"
    ```
    - Type determines the emoji that's displayed next to the message, it can be:
        - `working`: ✅
        - `warning`: ⚠️ 
        - Anything else: ℹ️

## Issues

The tool presents `Issues` to a user. These Issues can have related `Diagnostics` and `Metrics`. This allows for different data to be collected in different circumstances.

To add an issue:
- Create a directory for the issue in `opt/report/etc/issues/`
- Create file `metadata.yaml`
    ```yaml
    title: 'Short Issue Name'
    desc: 'Brief description of the issue'
    ```
- Create file `questions.yaml` if any additional questions/data are wanted
    ```yaml
    - question: 'Do you want to answer a question?'
      type: text 
      var: MY_ENV_VAR # exported to environment where diagnostic script is run
    - question: 'Did you like answering that question?'
      type: boolean
      var: MY_OTHER_ENV_VAR
    - question: 'How many questions would you ideally like to answer?'
      type: number
      var: MY_NUMBER
    - question: 'How would you rate your answering experience?'
      type: list
      options:
        - good
        - bad
        - ugly
      var: MY_FINAL_VAR
    ```
- Create file `diagnostics.bash` for any additional diagnostics to be run
    - The answers to questions for this issue will be available to the script by their corresponding `var:` value
- Create file `metrics.yaml` to execute commands that are compared to values to determine if metric is okay or not
    ```yaml
    - id: output-less-than
      name: "Output Less Than"
      cmd: "uptime |sed 's/.*load averages: //g;s/ .*//g'"
      value: 1.0
      type: 'lt'
    - id: output-greater-than
      name: "Output Greater Than"
      cmd: "uptime |sed 's/.*load averages: //g;s/ .*//g'"
      value: 1.0
      type: 'gt'
    - id: output-equals
      name: "Output Equals"
      cmd: "uptime |sed 's/.*load averages: //g;s/ .*//g'"
      value: 1.0
      type: 'equals'
    - id: string-check
      name: "Comparing Strings"
      cmd: "grep '^VERSION=' /etc/os-release"
      value: 'VERSION="9.3 (Blue Onyx)"'
      type: 'matches'
    ```
    - The answers to questions for this issue will be available to the commands by their corresponding `var:` value
    - Notes on restrictions:
        - `gt`, `lt` and `equals` convert the output to a floating point number to compare with `value`
        - `matches` compares the output to a string
            - Multiline values will almost definitely not work

# Outputs

## Access Logs

To see if anyone accesses the command, when they initially run `bin/report` a line will be added to a file named after the user under `var/accesslogs` with the time they launched the command.

## Ratings

The first thing the command asks for is a rating, this is from 0-2 but is represented in smilies. This rating is output to a file under `var/ratings`.

## Reports

This tool generates a report which can be used to track, compare and understand issues within the environment. A report is a YAML file structured as follows:
```yaml
meta: 
  issue_id: ISSUE_ID
  user: USERNAAME
  reported_at: DATE_AND_TIME_COMMAND_RUN
  issue_at: DATE_AND_TIME_OF_ISSUE
diagnostics:
  general: 
    SCRIPT_NAME:
      script_md5: MD5SUM_OF_SCRIPT # to ensure that the outputs can be compared because script structure hasn't changed
      output: |
        Multiline output
        from the script
  issue: 
    script_md5: MD5SUM_OF_SCRIPT # to ensure that the outputs can be compared because script structure hasn't changed
    answers: 
      VAR: ANSWER
      VAR: ANSWER
      VAR: ANSWER
    output: |
      Multiline output
      from the script
metrics:
  METRIC_ID: # Entire metric metadata including name, command, output, comparison type, success true/false
  METRIC_ID: # Entire metric metadata including name, command, output, comparison type, success true/false
  METRIC_ID: # Entire metric metadata including name, command, output, comparison type, success true/false
```

# Using the CLI

## User

The CLI is interactive so the user simply needs to run `flight report` and answer the questions in order to complete a report.

# To Do 

- User report management
    - See what issues they've reported, how often, etc
    - Let them view whatever previous reports of theirs they want (and compare 2 for an issue type) 
- Safely handle report saving such that users cannot delete existing reports
    - Separate the reporting CLI and the diagnostic execution+saving (pinging to an API server) 
    - Input validation to ensure text fields can't be used for injection attacks
- Alces & Site Admin tools
    - Possibilities for collating and contrasting reports
    - Admin command that can summarise what has been reported in past hour / 24 hours / week
- Support 'General' questions for setting env vars
- Other
    - Report historic issue (e.g. not experiencing right now)
    - Allow questions with assisted answers (e.g. using commands to populate selection)
    - Advisory actions for users based on the problems they're experiencing ("sometimes high disk usage can impact performance, especially with network arrays, if the usage is high due to many workloads running try transferring your workload to scratch before executing it")
    - AI chatbot?? 
