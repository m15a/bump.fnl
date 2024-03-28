FROM alpine:edge
RUN apk add --no-cache luajit
RUN ln -s /usr/bin/luajit /usr/local/bin/lua
COPY bump /usr/local/bin/
RUN mkdir /work
WORKDIR /work
ENTRYPOINT ["bump"]
CMD ["--help"]
