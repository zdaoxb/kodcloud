# dhso/kodexplorer
> kodcloud for docker.

## 运行 run
```bash
docker run -d \
--name kodcloud \
--restart=unless-stopped \
-p 10800:80 \
-v <kodcloud dir>:/var/www \
dhso/kodcloud:latest
```

## 编译
```bash
docker build --build-arg KODCOLUD_VERSION=[version] -t dhso/kodcloud:[version] .
```