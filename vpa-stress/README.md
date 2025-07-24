# Build stress-ng Container Image

```console
$ cd vpa-stress/stressng-image/
$ podman build -t stressng:latest .
$ podman tag localhost/stressng:latest quay.io/akrzos/stressng:latest
$ podman push quay.io/akrzos/stressng:latest
$ podman push quay.io/akrzos/stressng:latest
```
