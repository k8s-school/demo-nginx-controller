# Simple demo for nginx-controller ingress

## Pre-requisites

- An up and running Kubernetes cluster
- OpenSSL for certificate generation

## Launch the demo

```bash
git clone https://github.com/k8s-school/demo-nginx-controller
cd demo-nginx-controller
./setup.sh
```

## HTTPS Support

This demo includes automatic generation of self-signed certificates for HTTPS ingress. The setup script:

1. Generates self-signed certificates using `generate-certs.sh`
2. Creates a Kubernetes TLS secret with the certificates
3. Configures the ingress to use TLS

### Manual certificate generation

You can also generate certificates manually:

```bash
./generate-certs.sh [domain-name]
```

Default domain is `hello-world.info`. Certificates are stored in `./certs/` directory.

### Accessing the application

After running `./setup.sh -s`, you can access the application via:

- **HTTP**: `curl hello-world.info:<node-port>`
- **HTTPS**: `curl -k https://hello-world.info:<https-node-port>`

The `-k` flag ignores the self-signed certificate warnings.
