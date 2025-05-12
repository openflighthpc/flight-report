# Overview

A CLI tool for users to report suspected issues with their HPC environment.

# Install

This is a script meant to be integrated with the Flight Environment. The scripts in this directory correspond to where they should go in relation to `$flight_ROOT` (e.g. `libexec/commands/report` should be placed at `/opt/flight/libexec/commands/report` in a default flight environment setup).

An example of putting the files in place and installing dependencies (as root):
```
# Clone repository
git clone https://github.com/openflighthpc/flight-report /tmp/flight-report

# Copy files into place
cp -r /tmp/flight-report/opt $flight_ROOT/
cp -r /tmp/flight-report/libexec $flight_ROOT/

# Configure CLI tool 
## Open and edit the file to change defaults
cp $flight_ROOT/opt/report/etc/config.yaml.example $flight_ROOT/opt/report/etc/config.yaml

# Ensure log directory is writeable by all users
chmod 777 $flight_ROOT/opt/report/var/reports

# Install ruby dependencies
cd $flight_ROOT/opt/report/
$flight_ROOT/bin/bundle config set --local path vendor
$flight_ROOT/bin/bundle install

# Remove git repo
rm -rf /tmp/flight-report
```

## [Optional] Add to "Flight Banner"

The Flight Environment can include messages in the banner program (when enabled), to add a banner message with a call-to-action for `flight report`, create the file `$flight_ROOT/etc/banner/banner.d/30-report.sh` containing the following:
```bash
(
  bold="$(tput bold)"
  clr="$(tput sgr0)"
  if [[ $TERM =~ "256color" ]]; then
    bgblue="$(tput setab 68)"
  fi
  echo -e "EXPERIENCING PROBLEMS?\n"
  printf "  ${bold}${bgblue}flight report${clr} to log your issue\n"
  echo
)
```

## [Optional] Add to "Flight Tips"

The Flight Environment can have a "Flight Tips" section which is displayed on login to the system. To add `flight report` to the tips list create file `$flight_ROOT/etc/banner/tips.d/50-report.rc` containing the following:
```bash
flight_TIP_command="flight report"
flight_TIP_synopsis="report issues with your HPC environment"
flight_TIP_root="false"
```

## Updating

To update the CLI tool simply clone the repository and copy the files into place again, overwriting the existing ones. 

# File Structure

- `opt/report/etc/issues/`: Location of content for this command, this is where issues and specific diagnostics are defined
- `opt/report/etc/issues/general/*.bash`: These diagnostics are run for every issue (in alphanumeric order)
- `opt/report/etc/issues/general/metrics.yaml`: These metrics are checked for every issue

# Adding Content

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
- Admin tools
    - Possibilities for collating and contrasting reports
    - Admin command that can summarise what has been reported in past hour / 24 hours / week
- Support General questions for setting env vars
