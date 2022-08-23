FROM golang:1.19 as build

WORKDIR /code
COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /vtex-mirror


FROM scratch as final
LABEL author "@ia-Simon [GitHub]"

COPY --from=build /vtex-mirror /

ENTRYPOINT [ "/vtex-mirror" ]