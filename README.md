# dhso/kodexplorer
> kodcloud for docker.

## 运行 run
```bash
docker run -d \
--name kodcloud \
--restart=unless-stopped \
-p 10800:80 \
-v <kodcloud dir>:/var/www/html \
dhso/kodcloud:latest
```

## 编译
```bash
docker build --build-arg KODCOLUD_VERSION=[version] -t dhso/kodcloud:[version] .
```

docker run -d \
--name kod \
--restart=unless-stopped \
-p 8080:8080 \
dhso/kod:1.0