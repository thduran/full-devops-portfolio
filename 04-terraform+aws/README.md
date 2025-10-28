# Projeto de Portfólio DevOps: Pipeline Completo de IaC e CI/CD com EKS

Este projeto de portfólio demonstra um ciclo de vida DevOps de ponta a ponta. O objetivo é provisionar uma infraestrutura completa na AWS usando Terraform (IaC) e, em seguida, implantar automaticamente uma aplicação web em um pipeline de CI/CD usando GitHub Actions.

O foco não é apenas o resultado final, mas a jornada de construção e depuração.

## Índice

* [Visão Geral do Projeto](#visão-geral-do-projeto)
* [Arquitetura](#arquitetura)
* [Tecnologias Utilizadas](#tecnologias-utilizadas)
* [Decisões Chave de Arquitetura (Os "Porquês")](#decisões-chave-de-arquitetura-os-porquês)
* [Como Executar Este Projeto](#como-executar-este-projeto)
* [A Jornada: Relatório Completo de Aprendizado e Debug](#a-jornada-relatório-completo-de-aprendizado-e-debug)
* [Referência Rápida de Comandos](#referência-rápida-de-comandos)

---

1. Visão Geral do Projeto

O fluxo é dividido em duas fases principais:

Fase 1: Infraestrutura como Código (IaC)
* Um desenvolvedor executa `terraform apply` localmente.
* O Terraform provisiona uma rede (VPC), um cluster Kubernetes gerenciado (EKS), permissões (IAM) e os worker nodes (EC2) na AWS.

Fase 2: Pipeline de CI/CD
* Um `git push` para a branch main dispara um workflow do GitHub Actions.
* CI (Integração Contínua): O pipeline testa, compila, constrói uma imagem Docker e a envia para um registro.
* CD (Entrega Contínua): O pipeline se autentica no cluster EKS (criado pelo Terraform) e usa `kubectl apply` para implantar a nova versão da aplicação, que é exposta ao público por um Load Balancer.

2. Arquitetura

A arquitetura deste projeto é dividida em três fluxos principais: o Fluxo de Provisionamento de Infraestrutura (IaC), o Fluxo de Implantação de Aplicação (CI/CD) e o Fluxo de Tráfego do Usuário.

a. Fluxo de Provisionamento (IaC com Terraform)

Este fluxo é executado uma vez, manualmente, para construir o "terreno" onde a aplicação vai rodar.

* Tudo começa com o `terraform apply`.
* O Terraform lê os arquivos `.tf` e se comunica com a AWS.
* O `vpc.tf` cria a rede, usando o módulo `terraform-aws-modules/vpc/aws`. Crucialmente, ele é configurado para criar apenas sub-redes públicas (`private_subnets = []`) e desabilitar o NAT Gateway (`enable_nat_gateway = false`). Esta é uma decisão de arquitetura focada em custo zero para o projeto.
* O `iam.tf` cria duas "identidades" (Roles) essenciais: uma para o Control Plane do EKS (para que ele possa gerenciar redes) e outra para os Worker Nodes (para que eles possam se registrar no cluster e baixar imagens).
* O `eks.tf` cria o aws_eks_cluster (o "cérebro" gerenciado pela AWS) e o aws_eks_node_group (o "músculo", nossa instância t3.small).

b. Fluxo de Implantação (CI/CD com GitHub Actions)

Este fluxo é 100% automatizado e acontece a cada git push na branch main.

* O Job de CI é acionado. Ele baixa o código, executa testes, constrói a imagem Docker e a envia para o Docker Hub com uma nova tag.
* O Job de CD começa. Ele usa os secrets (AWS_ACCESS_KEY_ID) para se autenticar na AWS.
* Ele então executa o comando `aws eks update-kubeconfig` para se conectar ao cluster EKS que o Terraform criou.
* Finalmente, ele executa `kubectl apply` nos manifestos (ex: deployment.yaml, service.yaml) para implantar ou atualizar a aplicação no cluster.

c. Fluxo de Tráfego do Usuário (Kubernetes)

Este é o fluxo de como um usuário final acessa a aplicação.

* O `kubectl apply` criou um Service do tipo LoadBalancer.
* Como não instalamos um "AWS Load Balancer Controller" (o que seria uma arquitetura mais avançada), o EKS por padrão provisiona um Classic Load Balancer (ELBv1).
* O ELB é público (porta 80), mas ele não se conecta diretamente ao Pod.
* O ELB encaminha o tráfego para uma porta alta e aleatória no nó EC2. Essa porta é a NodePort (ex: 32522), que é definida pelo serviço do Kubernetes.
* Um processo chamado kube-proxy (que roda em todos os nós) intercepta o tráfego na porta (ex: 32522) e o roteia para o IP interno e porta do Pod (ex: 10.0.2.75:5000).
* (Esta arquitetura de NodePort foi a razão do nosso debug: ela exige a abertura manual dessa porta (ex. 32522) no Security Group (firewall) da instância EC2 para que o Load Balancer possa acessá-la.)

3. Tecnologias Utilizadas

* Nuvem: AWS (EKS, EC2, VPC, IAM, ELB)
* IaC: Terraform
* CI/CD: GitHub Actions
* Orquestração: Kubernetes
* Contêineres: Docker

4. Decisões Chave de Arquitetura (Os "Porquês")

Por que Terraform?
* Para garantir que a infraestrutura seja 100% reprodutível, versionável e fácil de destruir. Evita o "ClickOps" (criar manualmente no console), que é propenso a erros.

Por que essa arquitetura de VPC (Sem Sub-redes Privadas)?

* Custo e simplificação do projeto. A arquitetura de produção padrão usa private subnets para nós e um NAT Gateway para acesso à internet.
* Um NAT Gateway custa aproximadamente $0.045/h (aproximadamente $33/mês), ligado ou não.
* Ação: Usamos `private_subnets = []` e `enable_nat_gateway = false`. Colocamos nossos nós em public_subnets com `map_public_ip_on_launch = true`.
* Trade-off: Sacrificamos a segurança de produção (nós não estão isolados) em troca de custo zero de rede e simplificação.

Por que o iam.tf é necessário?
* O EKS é um "serviço de serviços". O Control Plane precisa de uma role (IAM) para gerenciar redes (VPC), e os Nós (EC2) precisam de outra role para se registrar no cluster e baixar imagens (ECR). O iam.tf define essas identidades e permissões obrigatórias.

Por que o pipeline de CD usa as credenciais do admin do Terraform?
* O EKS tem dois sistemas de permissão: IAM (AWS) e RBAC (Kubernetes).
* Por padrão, apenas o usuário IAM que criou o cluster é adicionado ao RBAC do Kubernetes como system:masters (admin).
* Ação: Usamos as credenciais do mesmo usuário IAM do Terraform nos secrets do GitHub (AWS_ACCESS_KEY_ID).
* Trade-off: É a forma mais simples de garantir que o pipeline tenha permissão de deploy sem precisar configurar manualmente o ConfigMap aws-auth.

5. Como Executar Este Projeto

Pré-requisitos

1. Uma conta AWS com credenciais (Access Key ID e Secret Key) de um usuário com permissões de administrador.
2. Terraform CLI instalado.
3. AWS CLI instalado e configurado (aws configure).
4. kubectl instalado. 
5. Um fork deste repositório no seu GitHub. 
6. Uma conta no Docker Hub.

5.1 Provisionar a Infra (Terraform)

No diretório raiz do projeto:

```bash
# 1. (Opcional) Edite o terraform.tfvars com seus valores
# vim terraform.tfvars

# 2. Inicializa o Terraform e baixa os módulos
terraform init

# 3. (Opcional) Vê o que será criado
terraform plan

# 4. Aplica e cria os recursos na AWS. (Pode levar de 15-20 minutos)
terraform apply -auto-approve
```

5.2 Configurar os Secrets do GitHub

No seu repositório GitHub, vá em Settings > Secrets and variables > Actions e crie os seguintes secrets:

* AWS_ACCESS_KEY_ID: A Access Key da AWS (mesmo usuário do Terraform).
* AWS_SECRET_ACCESS_KEY: A Secret Key correspondente.
* DOCKERHUB_USERNAME: Seu nome de usuário do Docker Hub.
* DOCKERHUB_TOKEN: Um Access Token (não sua senha) gerado no Docker Hub.

Importante: Você também precisará alterar o pipeline (e/ou k8s/deployment.yaml) para apontar para o seu repositório do Docker Hub (ex: seunome/minha-app:latest).

5.3 Executar o Pipeline (CI/CD)

Faça qualquer alteração pequena no código (ex: adicionar um espaço no README.md) e envie para a branch main.

```bash
git commit -m "Trigger pipeline" --allow-empty
git push origin main 
```

Vá até a aba "Actions" do seu repositório no GitHub para assistir o pipeline rodar.

5.4 Testar e Verificar o Deploy

Após o pipeline de CD ser concluído:

5.4.1 Configure seu kubectl local (o comando de saída do Terraform):

```bash
# Use os valores do seu .tfvars
aws eks update-kubeconfig --name my-cluster --region us-east-1
```

5.4.2 Verifique se os Nós e Pods estão prontos:

```bash
kubectl get nodes
# DEVE MOSTRAR: STATUS Ready 
kubectl get pods
# DEVE MOSTRAR: STATUS Running (pode levar um minuto)
```

5.4.3 Encontre o IP do Load Balancer:

```bash
kubectl get service
# Procure pelo seu serviço (ex: "web")
# Copie o valor do campo "EXTERNAL-IP" (ex: a66d....elb.amazonaws.com)
```

5.4.4 Acesse o IP no navegador: Cole o endereço EXTERNAL-IP no seu navegador. A aplicação deve carregar.

Solução de Problemas (Se NÃO carregar)
* Sintoma: O Pod está Running, o EXTERNAL-IP existe, mas o site não carrega.
* Causa: Usamos um LoadBalancer padrão, que cria um Classic ELB (ELBv1). Este ELB envia tráfego para a NodePort do serviço, não para a porta do pod. O Security Group (firewall) do nó (EC2) está bloqueando esta porta.
* Solução: Descubra a NodePort: kubectl describe service web (Procure por NodePort: ... 32522/TCP - o número será aleatório).
* Vá ao Console da AWS > EC2 > Security Groups.
* Encontre o Security Group do seu nó (ex: my-cluster-workers-sg). Clique em "Editar regras de entrada" (Edit inbound rules). Adicione uma regra: Tipo TCP Personalizado, Porta 32522 (o número da sua NodePort), Origem 0.0.0.0/0.
* Salve e teste o IP no navegador novamente.

6. Limpeza (!)
AVISO: O EKS e o Load Balancer são cobrados por hora.

6.1 DESTRUA O LOAD BALANCER (Dependência)
* O Load Balancer foi criado pelo Kubernetes, não pelo Terraform. Se você tentar destruir agora, o Terraform falhará com um erro de DependencyViolation.
* Solução: Exclua o serviço no Kubernetes primeiro:

```bash
kubectl delete service web
# (Aguarde 1-2 minutos para a AWS excluir o ELB).
```

6.2 DESTRUA A INFRA (Terraform)

```bash
terraform destroy -auto-approve
```

---

A Jornada: Relatório Completo de Aprendizado e Debug

Esta seção é um log de tudo o que foi aprendido durante a construção deste projeto, focado nos erros e como eles foram resolvidos.

Parte 1: Estratégia de Custo e Provisionamento
* Objetivo: Criar um cluster EKS com custo mínimo.
* Decisão: Evitar o NAT Gateway. Isso nos forçou a usar public_subnets para os worker nodes.

Empecilho 1: Ec2SubnetInvalidConfiguration (Erro de Lógica)
* Erro: O terraform apply falhou na criação do aws_eks_node_group com o erro does not automatically assign public IP addresses.
* Causa: Colocamos o nó em uma sub-rede pública, mas esquecemos de dizer à sub-rede para dar um IP público ao nó. Sem isso, o nó não podia se comunicar com o control plane do EKS.
* Solução: Adicionar `map_public_ip_on_launch = true` ao módulo vpc no arquivo vpc.tf.

Parte 2: O Desafio da Modularização vs. Projeto Plano

Empecilho 2: Reference to undeclared resource (Erro de Referência)
* Erro: A managed resource "vpc" "public_subnets" has not been declared...
* Causa: Dentro do nosso código, estávamos referenciando vpc.public_subnets (como se fosse um projeto plano), mas o recurso VPC estava dentro de um módulo.
* Solução: Corrigir todas as referências para o formato de módulo: vpc.public_subnets -> module.vpc.public_subnets aws_eks_cluster.cluster_name (no outputs.tf da raiz) -> module.my-eks.cluster_name
* (Nota: Mais tarde, simplificamos de volta para um projeto plano/híbrido, e as referências tiveram que ser ajustadas novamente para module.vpc.public_subnets e aws_eks_cluster.eks_cluster.name, mostrando o entendimento de como referenciar recursos em diferentes escopos.)

Empecilho 4: EntityAlreadyExists (Erro de Timing da AWS)
* Erro: Ao rodar terraform apply após um destroy falho, a criação das IAM Roles falhou com StatusCode: 409, EntityAlreadyExists.
* Causa: A AWS IAM tem "consistência eventual". O destroy removeu a role, mas a AWS ainda não tinha processado a exclusão totalmente quando tentamos recriá-la com o mesmo nome.
* Solução (Simplista): Esperar 1-2 minutos e rodar apply de novo.
* Solução (Correta): Usar `name_prefix = "..."` em vez de `name = "..." no iam.tf`. Isso faz o Terraform gerar um nome único com um sufixo aleatório, evitando a colisão.

Parte 3: O "Debug Final" do Load Balancer
* Sintoma: O pipeline rodou. `kubectl get pods` mostrava Running 1/1. `kubectl get service` mostrava um EXTERNAL-IP (Load Balancer). Mas o site não carregava no navegador (timeout).

Pista 1: port-forward funcionou!
* `kubectl port-forward pod/web-1234 8080:5000` (porta do app era 5000).
* Acessar http://localhost:8080 funcionou.
* Diagnóstico: Isso provou que o Pod e a aplicação estavam 100% saudáveis. O problema estava na rede (entre o Load Balancer e o Pod).

Pista 2: Não existe "Target Group".
* No Console da AWS, fomos ao EC2 > Target Groups, mas estava vazio.
* Diagnóstico: Um Service tipo LoadBalancer padrão no EKS (sem o "AWS Load Balancer Controller" instalado) não cria um Application Load Balancer (ALB). Ele cria um Classic Load Balancer (ELBv1).

A Revelação (O Fluxo Real do ELBv1):

1. O tráfego da Internet chega ao ELB pela porta 80.
2. O ELB não envia para o Pod. Ele envia para a NodePort no nó EC2.
3. Usamos `kubectl describe service web` para encontrar a NodePort (ex: 32522).
4. O kube-proxy (no nó) roteia o tráfego da porta 32522 para a porta 5000 do Pod.
O Problema Real: O Security Group (firewall) do nosso nó EC2 (t3.small) estava bloqueando a porta 32522!

A Solução Final:
1. No Console da AWS > EC2 > Security Groups, encontrar o SG do worker node.
2. Editar as Inbound Rules.
3. Adicionar uma nova regra: Tipo: TCP Personalizado, Porta: 32522 (ou qualquer que seja sua NodePort), Origem: 0.0.0.0/0 (Qualquer lugar).
4. Assim que salvamos, o status do nó no ELB (aba "Instances") mudou para InService e o site carregou.

Parte 4: A Falha ao Destruir (DependencyViolation)
* Erro: terraform destroy falhou com Error: deleting EC2 Subnet ... DependencyViolation.
* Causa: O Load Balancer (ELBv1) ainda estava usando as sub-redes. O Terraform não podia excluir algo com uma dependência ativa.
* Aprendizado: O Terraform não gerencia recursos criados pelo Kubernetes.
* Solução (Obrigatória): Sempre excluir os Service do tipo LoadBalancer do Kubernetes ANTES de destruir a infra do Terraform.
1. `kubectl delete service web`
2. Aguardar 2 minutos.
3. `terraform destroy -auto-approve`

---

Referência Rápida de Comandos

AWS CLI

Configura o kubectl

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

Kubectl (Debug)

```bash
# Verifica o status dos nós
kubectl get nodes
# Verifica o status dos pods
kubectl get pods
# Verifica o status dos serviços e encontra o IP 
kubectl get service
# (O "Debug Mestre") Testa o pod diretamente
kubectl port-forward pod/<nome-do-pod> [porta-local]:[porta-container]
# Vê os logs da aplicação se ela estiver quebrando
kubectl logs <nome-do-pod>
# O comando que revela a NodePort e os Selectors
kubectl describe service <nome-do-servico>
# O comando para "destravar" o terraform destroy 
kubectl delete service <nome-do-servico>
```