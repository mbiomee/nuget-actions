FROM mcr.microsoft.com/dotnet/core/sdk:3.1.301

LABEL "com.github.actions.name"="Nuget-Action"
LABEL "com.github.actions.description"="Nuget Package build with test and static code analysis"
LABEL "com.github.actions.color"="green"

LABEL "repository"="https://github.com/mbiomee/nuget-actions"
LABEL "homepage"="https://mbiomee.online"
LABEL "maintainer"="Mostafa Biomee"

# Version numbers of used software
ENV SONAR_SCANNER_DOTNET_TOOL_VERSION=4.10.0 \
    DOTNETCORE_RUNTIME_VERSION=3.1 \
    JRE_VERSION=11

# Add Microsoft Debian apt-get feed 
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb

# Install the .NET Core Runtime for SonarScanner.
# The warning message "delaying package configuration, since apt-utils is not installed" is probably not an actual error, just a warning.
# We don't need apt-utils, we won't install it. The image seems to work even with the warning.
RUN apt-get update -y \
    && apt-get install --no-install-recommends -y apt-transport-https \
    && apt-get update -y \
    && apt-get install --no-install-recommends -y aspnetcore-runtime-$DOTNETCORE_RUNTIME_VERSION

# Install Java Runtime for SonarScanner
RUN apt-get install --no-install-recommends -y openjdk-$JRE_VERSION-jre

# Install SonarScanner .NET Core global tool
RUN dotnet tool install dotnet-sonarscanner --tool-path . --version $SONAR_SCANNER_DOTNET_TOOL_VERSION

# Cleanup
RUN apt-get -q -y autoremove \
    && apt-get -q clean -y \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]