Pipeline de CD

obs. os mesmos arquivos do diretorio day-02 foram copiados para day-03 para dar certo
a diferenca é que o diretorio k8s foi adicionado para que o CD de certo

cd se refere a linha 84 a 105
needs: [CI] para executar apos CI

precisa do kubectl apply e para isso antes precisa da configuração do kubeconfig pra saber qual cluster K8S queremos
tem uma action pra definir isso > azure/k8s-set-context@v4. Usaremos secret pra cadastrar o kubeconfig, que pegamos assim: code ~/.kube/config

Após definição do kubeconfig, como dito, precisamos deployar. E tem uma action pra isso: Azure/k8s-deploy@v5

no caso da digital ocean basta seguir as instruções iniciais (apenas dois comandos) para setar localmente o kubeconfig e para mostrar o kubeconfig a fim de colar como secret no github

com a pipe cd dando certo, basta dar um kubectl get svc pra pegar o external ip do service e testar
---

tb foi criado um workflow de teste pra 