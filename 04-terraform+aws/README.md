# Projeto de Portfólio DevOps: Pipeline Completo na EKS

![Pipeline de CI/CD](https://github.com/thduran/full-devops-portfolio/actions/workflows/simple-workflow.yaml/badge.svg)

Este projeto demonstra um ciclo de vida DevOps completo, desde o provisionamento da infraestrutura com Terraform até um pipeline de CI/CD automatizado no GitHub Actions para implantar uma aplicação Go em um cluster Kubernetes (EKS) na AWS.

O foco principal é a automação (IaC, CI/CD) e a otimização de custos na nuvem.

## Índice

* [Visão Geral do Projeto](#visão-geral-do-projeto)
* [Arquitetura](#arquitetura)
* [Tecnologias Utilizadas](#tecnologias-utilizadas)
* [Decisões Chave & Justificativas](#decisões-chave--justificativas)
* [Como Executar este Projeto](#como-executar-este-projeto)
    * [Pré-requisitos](#pré-requisitos)
    * [1. Provisionar a Infra (Terraform)](#1-provisionar-a-infra-terraform)
    * [2. Configurar os Secrets do GitHub](#2-configurar-os-secrets-do-github)
    * [3. Executar o Pipeline (CI/CD)](#3-executar-o-pipeline-cicd)
    * [4. Acessar a Aplicação](#4-acessar-a-aplicação)
    * [5. Limpeza (Obrigatório)](#5-limpeza-obrigatório)
* [Jornada Detalhada do Projeto & Log de Debug](#jornada-detalhada-do-projeto--log-de-debug)
    * [Parte 1: Provisionamento com Terraform (Estratégia e Erros)](#parte-1-provisionamento-com-terraform-estratégia-e-erros)
    * [Parte 2: Modularização do Terraform (Refatoração)](#parte-2-modularização-do-terraform-refatoração)
    * [Parte 3: Pipeline de CI/CD (GitHub Actions)](#parte-3-pipeline-de-cicd-github-actions)
    * [Parte 4: Debug de Deploy (O Pesadelo do Load Balancer)](#parte-4-debug-de-deploy-o-pesadelo-do-load-balancer)
    * [Resumo de Comandos Essenciais](#resumo-de-comandos-essenciais)

---

## Visão Geral do Projeto

Este projeto automatiza o deploy de uma simples aplicação web em Go. O fluxo é o seguinte:

1.  **Infraestrutura como Código (IaC):** O Terraform é usado para provisionar um cluster Kubernetes gerenciado (EKS) na AWS, junto com toda a rede (VPC) e permissões (IAM) necessárias.
2.  **Integração Contínua (CI):** Quando um `push` é feito para a branch `main`, o GitHub Actions inicia:
    * Compila o código Go.
    * Executa testes.
    * Constrói uma imagem Docker.
    * Envia a imagem para o Docker Hub com uma tag de versão (`v${{ github.run_number }}`).
3.  **Entrega Contínua (CD):** Imediatamente após o CI, o job de CD:
    * Autentica-se no cluster EKS provisionado pelo Terraform.
    * Atualiza o manifesto do Kubernetes (`deployment.yaml`) para usar a nova tag da imagem.
    * Aplica o manifesto, disparando um *rollout* da nova versão.
4.  **Exposição:** Um Service do Kubernetes do tipo `LoadBalancer` expõe a aplicação para a internet.

## Arquitetura

O diagrama abaixo ilustra o fluxo de dados e as tecnologias envolvidas:

```mermaid
graph TD
    subgraph "Desenvolvedor"
        A[Git Push]
    end

    subgraph "GitHub Actions"
        A --> B(CI Job);
        B --> C{Testes Passaram?};
        C -- Sim --> D[Build & Push Imagem Docker];
        D --> E(Docker Hub);
        D --> F(CD Job);
        F --> G[Autenticação AWS];
        G --> H[kubectl apply];
    end

    subgraph "Usuário (Manual)"
        I[terraform apply] --> J(AWS);
    end

    subgraph "AWS"
        J -- provisiona --> K(VPC);
        J -- provisiona --> L(Cluster EKS);
        J -- provisiona --> M(Nó EC2 t3.small);

        H -- comanda --> L;
        L -- cria --> N(Pod: App Go);
        L -- cria --> O(Service: LoadBalancer);
        O -- provisiona --> P(Classic Load Balancer);
    end
    
    subgraph "Usuário Final"
       U(Internet) --> P;
    end

    P -- porta 80 --> M;
    M -- NodePort 32522 --> N(Porta 5000);