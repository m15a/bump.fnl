FROM alpine:edge
# TODO: luajit does not work; not sure why.
RUN apk add --no-cache lua5.4 fennel5.4 make
RUN mkdir -p /build/t
COPY bump.fnl /build/
COPY bump/ /build/bump/
COPY Makefile /build/
WORKDIR /build
RUN make build LUA=lua5.4 FENNEL=fennel5.4
RUN cp bin/bump /usr/local/bin/
RUN mkdir /work
WORKDIR /work
RUN rm -rf /build
RUN apk del fennel5.4 make
ENTRYPOINT ["bump"]
CMD ["--help"]
