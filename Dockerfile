FROM 294847794149.dkr.ecr.us-east-2.amazonaws.com/fluentd-windows

LABEL maintainer="Ryan King"
WORKDIR C:\\fluentd

RUN setx PATH "%PATH%;C:\\fluentd\\vendor\\bundle\\ruby\\2.6.0\\bin;C:\\ruby26\\bin"

# skip runtime bundler installation
ENV FLUENTD_DISABLE_BUNDLER_INJECTION 1

COPY Gemfile* C:\\fluentd
RUN powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
RUN choco install -y ruby --version 2.6.5.1 --params "'/InstallDir:C:\\ruby26'" \
  && choco install -y msys2 --params "'/NoPath /NoUpdate /InstallDir:C:\\ruby26\\msys64'"

RUN refreshenv \
  && ridk install 2 3 \
  && echo gem: --no-document >> C:\\ProgramData\\gemrc \
  && gem install bundler --version 1.16.2 \
  && bundle config silence_root_warning true \
  && bundle install --gemfile=C:\\fluentd\\Gemfile --path=C:\\fluentd\\vendor\\bundle \
  && gem sources --clear-all

RUN setx GEM_PATH "C:\\fluentd\\vendor\\bundle\\ruby\\2.6.0"
RUN setx GEM_HOME "C:\\fluentd\\vendor\\bundle\\ruby\\2.6.0"

# Remove gem cache and chocolatey
RUN powershell -Command "Remove-Item -Force C:\\ruby26\\lib\\ruby\\gems\\2.6.0\\cache\\*.gem; Remove-Item -Recurse -Force 'C:\\ProgramData\\chocolatey'"

COPY .\\conf\\fluent.conf C:\\fluentd\\etc
COPY .\\conf\\kubernetes.conf C:\\fluentd\\etc
COPY .\\plugins C:\\fluentd\\plugins
# RUN echo '' > C:\\fluentd\\etc\\disable.conf

ENV FLUENTD_CONF="fluent.conf"

ENTRYPOINT ["cmd", "/k", "fluentd", "-c", "C:\\fluent\\conf\\fluent.conf"]