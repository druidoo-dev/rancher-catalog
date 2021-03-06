version: '2'
services:
    traefik:
        tty: true
        stdin_open: true
        ports:
            - ${admin_port}:8080/tcp
            - ${http_port}:80/tcp
            - ${https_port}:443/tcp
            # log_driver: ''
        command:
            - --api.dashboard
            - --checknewversion=false
            - --rancher
            - --rancher.domain=${domain}
            - --rancher.metadata
            - --rancher.enableservicehealthfilter=${EnableServiceHealthFilter}
            # parameter para loglevel? (INFO, DEBUG, ERROR otra opcion)
            - --logLevel=INFO
            # para investigar...
            # - --docker.constraints="tag==web"
            # config entrypoints
            - --defaultentrypoints=http,https
            - --insecureskipverify=true
            - --entryPoints=Name:http Address::80 Redirect.EntryPoint:https
            - --entryPoints=Name:https Address::443 TLS Compress:on
            # - --entryPoints=Name:https Address::443 TLS:/secrets/domain.crt,/secrets/domain.key Compress:on
            # acme config
        {{- if eq .Values.acme_enable "true"}}
            - --acme
            - --acme.acmelogging
            - --acme.entrypoint=https
            - --acme.email=${acme_email}
            - --acme.onhostrule=${acme_onhostrule}
            - --acme.storage=/secrets/acme.json
        {{- end}}
        # por ahora traefik no soporta los dos challenge a la vez pero puede ser que mas adelante si, ver acá https://github.com/containous/traefik/issues/3378
        {{- if eq .Values.acme_http_challenge "true"}}
            - --acme.httpChallenge.entryPoint=http
        {{- end}}
        {{- if eq .Values.acme_dns_challenge "true"}}
            - --acme.dnschallenge
            - --acme.domains=*.${domain}
            # dio algunos errores y tampoco lo necesitamos
            # - --acme.domains=${domain}
            - --acme.dnschallenge.provider=route53
        {{- end}}
        labels:
            # por ahora no lo hacemos global y lo manejamos con scale y host distinto
            io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.scheduler.global: 'false'
            io.rancher.scheduler.affinity:host_label: ${host_label}
            # publish traefik admin
            traefik.enable: 'true'
            traefik.port: 8080
            traefik.frontend.auth.basic: "${auth_users}"
            traefik.frontend.rule: "Host:tr.${domain}"
        image: traefik:1.6.2-alpine
        volumes:
            - traefik-secrets:/secrets
volumes:
    traefik-secrets:
        driver: rancher-nfs
        external: true
