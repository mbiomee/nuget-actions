#!/bin/bash
set -o pipefail
set -eu

# Check required parameters has a value
if [ -z "$INPUT_SONARPROJECTKEY" ]; then
    echo "Input parameter sonarProjectKey is required"
    exit 1
fi
if [ -z "$INPUT_SONARPROJECTNAME" ]; then
    echo "Input parameter sonarProjectName is required"
    exit 1
fi
if [ -z "$SONAR_TOKEN" ]; then
    echo "Environment parameter SONAR_TOKEN is required"
    exit 1
fi

# List Environment variables that's set by Github Action input parameters (defined by user)
echo "Github Action input parameters"
echo "INPUT_SONARPROJECTKEY: $INPUT_SONARPROJECTKEY"
echo "INPUT_SONARPROJECTNAME: $INPUT_SONARPROJECTNAME"
echo "INPUT_SONARORGANIZATION: $INPUT_SONARORGANIZATION"
echo "INPUT_DOTNETBUILDARGUMENTS: $INPUT_DOTNETBUILDARGUMENTS"
echo "INPUT_DOTNETTESTARGUMENTS: $INPUT_DOTNETTESTARGUMENTS"
echo "INPUT_DOTNETDISABLETESTS: $INPUT_DOTNETDISABLETESTS"
echo "INPUT_SONARBEGINARGUMENTS: $INPUT_SONARBEGINARGUMENTS"
echo "INPUT_SONARHOSTNAME: $INPUT_SONARHOSTNAME"


#-----------------------------------
# Build Sonarscanner begin command
#-----------------------------------
sonar_begin_cmd="/dotnet-sonarscanner begin /k:\"${INPUT_SONARPROJECTKEY}\" /n:\"${INPUT_SONARPROJECTNAME}\" /d:sonar.login=\"${SONAR_TOKEN}\" /d:sonar.host.url=\"${INPUT_SONARHOSTNAME}\""
if [ -n "$INPUT_SONARORGANIZATION" ]; then
    sonar_begin_cmd="$sonar_begin_cmd /o:\"${INPUT_SONARORGANIZATION}\""
fi
if [ -n "$INPUT_SONARBEGINARGUMENTS" ]; then
    sonar_begin_cmd="$sonar_begin_cmd $INPUT_SONARBEGINARGUMENTS"
fi
# Check Github environment variable GITHUB_EVENT_NAME to determine if this is a pull request or not. 
if [[ $GITHUB_EVENT_NAME == 'pull_request' ]]; then
    
    # Extract Pull Request numer from the GITHUB_REF variable
    PR_NUMBER=$(echo $GITHUB_REF | awk 'BEGIN { FS = "/" } ; { print $3 }')

    # Add pull request specific parameters in sonar scanner
    sonar_begin_cmd="$sonar_begin_cmd /d:sonar.pullrequest.key=$PR_NUMBER /d:sonar.pullrequest.branch=$GITHUB_HEAD_REF /d:sonar.pullrequest.base=$GITHUB_BASE_REF /d:sonar.pullrequest.github.repository=$GITHUB_REPOSITORY /d:sonar.pullrequest.provider=github"

fi

#-----------------------------------
# Build Sonarscanner end command
#-----------------------------------
sonar_end_cmd="/dotnet-sonarscanner end /d:sonar.login=\"${SONAR_TOKEN}\""

#-----------------------------------
# Build dotnet build command
#-----------------------------------
dotnet_build_cmd="dotnet build"
if [ -n "$INPUT_DOTNETBUILDARGUMENTS" ]; then
    dotnet_build_cmd="$dotnet_build_cmd $INPUT_DOTNETBUILDARGUMENTS"
fi

#-----------------------------------
# Build dotnet test command
#-----------------------------------
dotnet_test_cmd="dotnet test"
if [ -n "$INPUT_DOTNETTESTARGUMENTS" ]; then
    dotnet_test_cmd="$dotnet_test_cmd $INPUT_DOTNETTESTARGUMENTS"
fi

#-----------------------------------
# Execute shell commands
#-----------------------------------
echo "Shell commands"

#Run Sonarscanner .NET Core "begin" command
echo "sonar_begin_cmd: $sonar_begin_cmd"
sh -c "$sonar_begin_cmd"

#Run dotnet build command
echo "dotnet_build_cmd: $dotnet_build_cmd"
sh -c "${dotnet_build_cmd}"

#Run dotnet test command (unless user choose not to)
if ! [[ "${INPUT_DOTNETDISABLETESTS,,}" == "true" || "${INPUT_DOTNETDISABLETESTS}" == "1" ]]; then
    echo "dotnet_test_cmd: $dotnet_test_cmd"
    sh -c "${dotnet_test_cmd}"
fi

#Run Sonarscanner .NET Core "end" command
echo "sonar_end_cmd: $sonar_end_cmd"
sh -c "$sonar_end_cmd"