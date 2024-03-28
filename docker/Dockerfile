FROM alpine:edge

# TODO: luajit does not work; not sure why.
RUN apk add --no-cache lua5.4 fennel5.4 make

RUN mkdir -p /build/t
COPY Makefile /build/
COPY bump.fnl /build/
COPY bump/ /build/bump/
WORKDIR /build
RUN make install LUA=lua5.4 FENNEL=fennel5.4

WORKDIR /
RUN rm -rf /build
RUN apk del fennel5.4 make

RUN mkdir /work
WORKDIR /work
ENTRYPOINT ["bump"]
CMD ["--help"]
