FROM ghcr.io/mhsanaei/3x-ui:v2.9.4
RUN apk add --no-cache nginx openssl ca-certificates tzdata curl jq
COPY bootstrap.sh /jinx/bootstrap.sh
RUN chmod +x /jinx/bootstrap.sh && sh -n /jinx/bootstrap.sh
ENV JINX_UUID=df70a084-8d46-50bd-dec8-3a0f41903f3a \
    PANEL_USERNAME=admin \
    PANEL_PASSWORD=admin \
    PORT=8080 \
    TZ=Asia/Tehran
EXPOSE 8080
WORKDIR /app
ENTRYPOINT ["/jinx/bootstrap.sh"]
