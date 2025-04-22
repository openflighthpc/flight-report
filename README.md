# Overview

A CLI tool for users to report suspected issues with their HPC environment.

# Install

This is a script meant to be integrated with the Flight Environment. The scripts in this directory correspond to where they should go in relation to `$flight_ROOT` (e.g. `libexec/commands/report` should be placed at `/opt/flight/libexec/commands/report` in a default flight environment setup).

An example of putting the files in place and installing dependencies (as root):
```
git clone https://github.com/openflighthpc/flight-report /tmp/flight-report

cp -r /tmp/flight-report/opt $flight_ROOT/
cp -r /tmp/flight-report/libexec $flight_ROOT/
mkdir -p $flight_ROOT/var/reports

cd $flight_ROOT/opt/report/
$flight_ROOT/bin/bundle config set --local path vendor
$flight_ROOT/bin/bundle install
```


# File Structure

- `opt/report/etc/issues/`: Location of content for this command, this is where issues and specific diagnostics are defined
- `opt/report/etc/issues/general/*.bash`: These diagnostics are run for every issue (in alphanumeric order)

# Adding Content

The tool presents `Issues` to a user and these Issues can have related `Diagnostics`. This allows for different date to be collected in different circumstances.

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


# Using the CLI

## User

The CLI is interactive so the user simply needs to run `flight report` and answer the questions in order to complete a report.

## Admin

- Possibilities for collating and contrasting reports
- Admin command that can summarise what has been reported in past hour / 24 hours /

# To Do 

- Locate and compare this report to a previous one of the same type (by the same user?)

