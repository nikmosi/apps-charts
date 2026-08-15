# Xray Helm Chart

Helm chart for [teddysun/xray](https://hub.docker.com/r/teddysun/xray) - Xray-core proxy server for Kubernetes with automated geoip/geosite assets downloading.

## Features

- **Inbound Protocol:** `mixed` (HTTP + SOCKS5) on port `8080` by default.
- **Outbound Protocol:** `vless` out-of-the-box configuration template.
- **Geo Assets InitContainer:** Automatically downloads `geoip.dat` and `geosite.dat` files into an `emptyDir` volume upon pod startup.
- **Asset Location:** Configurable path (default: `/usr/local/share/xray`) automatically exported via `XRAY_LOCATION_ASSET`.

## Prerequisites

- Kubernetes 1.19+
- Helm v3.0+

## Installing the Chart

To install the chart with the release name `my-xray`:

```bash
helm install my-xray ./xray
```

## Uninstalling the Chart

To uninstall/delete the `my-xray` deployment:

```bash
helm delete my-xray
```

## Configuration

| Parameter | Description | Default |
| --- | --- | --- |
| `replicaCount` | Number of pod replicas | `1` |
| `image.repository` | Container image repository | `teddysun/xray` |
| `image.tag` | Container image tag | `26.7.11` |
| `geoAssets.enabled` | Enable initContainer to download `geoip.dat` and `geosite.dat` | `true` |
| `geoAssets.mountPath` | Path to store geo database assets (`XRAY_LOCATION_ASSET`) | `/usr/local/share/xray` |
| `geoAssets.urls.geoip` | Download URL for `geoip.dat` | `https://github.com/v2fly/geoip/releases/latest/download/geoip.dat` |
| `geoAssets.urls.geosite` | Download URL for `geosite.dat` | `https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat` |
| `xray.configPath` | Path to mount `config.json` inside container | `/etc/xray/config.json` |
| `xray.config` | Inline JSON configuration for Xray | `mixed` inbound on `8080` + `vless` outbound |
| `service.type` | Kubernetes Service type | `ClusterIP` |
| `service.ports` | List of service ports | `[name: mixed, port: 8080, targetPort: 8080]` |

## Asset Path for Configuration

The asset path mounted by the `initContainer` is:
```
/usr/local/share/xray
```
The chart automatically passes `XRAY_LOCATION_ASSET=/usr/local/share/xray` to the container environment, so Xray automatically resolves `geoip:...` and `geosite:...` rules.
